/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AIContactListWindowController.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import "AIMessageTabViewItem.h"
#import "AINewMessagePrompt.h"
#import "AIDualWindowPreferences.h"

#define DUAL_SPELLING_DEFAULT_PREFS		@"DualSpellingDefaults"
#define DUAL_INTERFACE_DEFAULT_PREFS		@"DualWindowDefaults"

#define CONTACT_LIST_WINDOW_MENU_TITLE		@"Contact List"		//Title for the contact list menu item
#define MESSAGES_WINDOW_MENU_TITLE		@"Messages"		//Title for the messages window menu item
#define CLOSE_TAB_MENU_TITLE			@"Close Tab"		//Title for the close tab menu item
#define CLOSE_MENU_TITLE			@"Close"		//Title for the close menu item
#define PREVIOUS_MESSAGE_MENU_TITLE		@"Previous Message"
#define NEXT_MESSAGE_MENU_TITLE			@"Next Message"

@interface AIDualWindowInterfacePlugin (PRIVATE)
- (void)addMenuItems;
- (void)removeMenuItems;
- (void)buildWindowMenu;
- (void)updateActiveWindowMenuItem;
- (void)increaseUnviewedContentOfListObject:(AIListObject *)inObject;
- (void)clearUnviewedContentOfChat:(AIChat *)inChat;
- (AIMessageTabViewItem *)_createMessageTabForChat:(AIChat *)inChat;
- (AIMessageTabViewItem *)_messageTabForChat:(AIChat *)inChat;
- (AIMessageTabViewItem *)_messageTabForListObject:(AIListObject *)inListObject;
@end

@implementation AIDualWindowInterfacePlugin

//Plugin setup ------------------------------------------------------------------
- (void)installPlugin
{
    //Register our interface
    [[owner interfaceController] registerInterfaceController:self]; 
}

- (void)uninstallPlugin
{

}

//Open the interface
- (void)openInterface
{
    //init
    messageWindowController = nil;
    windowMenuArray = [[NSMutableArray alloc] init];

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_SPELLING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_SPELLING];
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    //Install Preference Views
    preferenceController = [[AIDualWindowPreferences dualWindowInterfacePreferencesWithOwner:owner] retain];
        
    //Open the contact list window
    [self showContactList:nil];

    //Register for the necessary notifications
    [[owner notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_DidReceiveContent object:nil];

    //Install our menu items
    [self addMenuItems];
    [self buildWindowMenu];
}

//Close the interface
- (void)closeInterface
{
    //Close and unload our windows
    if(messageWindowController){
        [messageWindowController closeWindow:nil];
        [messageWindowController release];
    }
    if(contactListWindowController){
        [contactListWindowController close:nil];
        [contactListWindowController release];
    }
    
    //Stop observing
    [[owner notificationCenter] removeObserver:self];

    //Remove our menu items
    [self removeMenuItems];
    
    //Cleanup
    [windowMenuArray release];
}

//Contact List ---------------------------------------------------------------------
//Show the contact list window
- (IBAction)showContactList:(id)sender
{
    if(!contactListWindowController){ //Load the window
        contactListWindowController = [[AIContactListWindowController contactListWindowControllerForInterface:self owner:owner] retain];
    }

    [contactListWindowController makeActive:nil];

    //Give Adium focus
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

}


//Messages -------------------------------------------------------------------------
//Close the active window
- (IBAction)close:(id)sender
{
    //Close the main window
    [[[NSApplication sharedApplication] keyWindow] performClose:nil];
}

//Close the active tab
- (IBAction)closeTab:(id)sender
{
    if(messageWindowController){
        AIMessageTabViewItem	*container = (AIMessageTabViewItem *)[messageWindowController selectedTabViewItemContainer];
        [[owner interfaceController] closeChat:[[container messageViewController] chat]];
    }
}

//Show the message window
- (IBAction)showMessageWindow:(id)sender
{
    if(messageWindowController){ //Show the message window only if it already exists (otherwise it would be empty)
        if([sender isKindOfClass:[NSMenuItem class]]){ //Select the tab if called in response to a menu selection
            id	container = [(NSMenuItem *)sender representedObject];

            [messageWindowController selectTabViewItemContainer:(AIMessageTabViewItem *)container];

        }else{ //Otherwise just bring the window forward
            [messageWindowController showWindow:nil];

        }
    }
}


//Cycling -------------------------------------------------------------------------
//Select the next message
- (IBAction)nextMessage:(id)sender
{
    NSArray	*containerArray = [messageWindowController messageContainerArray];
    int		newIndex;
    
    if(activeContainer != nil && activeContainer != contactListWindowController){
        newIndex = [containerArray indexOfObject:activeContainer] + 1;
    }else{
        newIndex = 0;
    }

    if(newIndex >= [containerArray count]){
        [contactListWindowController makeActive:nil];
    }else{
        [[containerArray objectAtIndex:newIndex] makeActive:nil];
    }
}

//Select the previous message
- (IBAction)previousMessage:(id)sender
{
    NSArray	*containerArray = [messageWindowController messageContainerArray];
    int		newIndex;

    if(activeContainer != nil && activeContainer != contactListWindowController){
        newIndex = [containerArray indexOfObject:activeContainer] - 1;
    }else{
        newIndex = [containerArray count] - 1;
    }
    
    if(newIndex < 0){
        [contactListWindowController makeActive:nil];
    }else{
        [[containerArray objectAtIndex:newIndex] makeActive:nil];
    }
}


//Container Interface --------------------------------------------------------------
//A container was closed
- (void)containerDidClose:(id <AIInterfaceContainer>)inContainer
{
    if(inContainer == contactListWindowController){
        [contactListWindowController release]; contactListWindowController = nil;
    }
    
    [self buildWindowMenu]; //Rebuild our window menu
}

//A container was made active
- (void)containerDidBecomeActive:(id <AIInterfaceContainer>)inContainer
{
    activeContainer = inContainer;

    //Set the container's handle's content as viewed
    if([inContainer isKindOfClass:[AIMessageTabViewItem class]]){
        [self clearUnviewedContentOfChat:[[(AIMessageTabViewItem *)inContainer messageViewController] chat]];
    }

    //Update the close window/close tab menu item keys
    if([inContainer isKindOfClass:[AIMessageTabViewItem class]]){
        [menuItem_close setKeyEquivalent:@"W"];
        [menuItem_closeTab setKeyEquivalent:@"w"];
    }else{
        [menuItem_close setKeyEquivalent:@"w"];

        //Removing the key equivalant from our "Close Tab" menu item
        //-----
        //Because of a bug with NSMenuItem (Yay), we can't just do this:
        // [menuItem_closeTab setKeyEquivalent:@""];
        //
        //Instead, we have to remove the menu item, remove its key
        //equivalant, and then re-add it to the menu
        [menuItem_closeTab retain];
        {
            NSMenu*	menu = [menuItem_closeTab menu];
            int		index = [menu indexOfItem:menuItem_closeTab];

            [menu removeItemAtIndex:index];
            [menuItem_closeTab setKeyEquivalent:@""];
            [menu insertItem:menuItem_closeTab atIndex:index];
        }
        [menuItem_closeTab release];

    }

    [self updateActiveWindowMenuItem];
}

//The containers were re-ordered
- (void)containerOrderDidChange
{
    [self buildWindowMenu]; //Rebuild our window menu
}


//Interface Notifications ------------------------------------------------------------------
//Called when a message object is added to a handle
- (void)didReceiveContent:(NSNotification *)notification
{
    NSDictionary		*userInfo = [notification userInfo];
    AIMessageTabViewItem	*messageTabContainer;
    AIContentObject		*object;

    //Get the content object
    object = [userInfo objectForKey:@"Object"];

    //Get the message tab for this chat
    messageTabContainer = [self _messageTabForChat:[object chat]];

    //force a message tab open in case of failure somewhere else
    if(!messageTabContainer){
        NSLog(@"Content received, but no chat open.  Forcing the chat open");
        [self openChat:[object chat]];
    }

    //Increase the handle's unviewed count (If it's not the active container)
    if(messageTabContainer && messageTabContainer != activeContainer){
        [self increaseUnviewedContentOfListObject:[object source]];
    }
}

//Called when the user requests to initiate a message
- (void)initiateNewMessage
{
    //Display our new message prompt
    [AINewMessagePrompt newMessagePromptWithOwner:owner];
}

//
- (void)openChat:(AIChat *)inChat
{
    AIMessageTabViewItem	*messageTabContainer = nil;
    AIListObject		*listObject;
    
    //Check for an existing message container with this list object
    if(listObject = [inChat listObject]){
        messageTabContainer = [self _messageTabForListObject:listObject];

        //If one already exists, we want to use it for this new chat
        if(messageTabContainer){
            [[messageTabContainer messageViewController] setChat:inChat];
        }
    }

    //Create a tab for this chat
    if(!messageTabContainer){
        messageTabContainer = [self _createMessageTabForChat:inChat];
    }

    //Display the account selector
    [[messageTabContainer messageViewController] setAccountSelectionMenuVisible:YES];
}

//
- (void)setActiveChat:(AIChat *)inChat
{
    //Select the tab
    [[self _messageTabForChat:inChat] makeActive:nil];
}

//
- (void)closeChat:(AIChat *)inChat
{
    AIMessageTabViewItem	*container;

    if(messageWindowController){
        //Remove unviewed content for this contact
        [self clearUnviewedContentOfChat:inChat];

        //Find the message controller for this chat, and close it
        container = [self _messageTabForChat:inChat];
        if(container) [messageWindowController removeTabViewItemContainer:container];
    }
}


//Menus ------------------------------------------------------------------------------
//Add our menu items
- (void)addMenuItems
{
    //Add the close menu item
    menuItem_close = [[NSMenuItem alloc] initWithTitle:CLOSE_MENU_TITLE target:self action:@selector(close:) keyEquivalent:@"w"];
    [[owner menuController] addMenuItem:menuItem_close toLocation:LOC_File_Close];

    //Add our close tab menu item
    menuItem_closeTab = [[NSMenuItem alloc] initWithTitle:CLOSE_TAB_MENU_TITLE target:self action:@selector(closeTab:) keyEquivalent:@""];
    [[owner menuController] addMenuItem:menuItem_closeTab toLocation:LOC_File_Close];

    //Add our other menu items
    {
        // Using the cursor keys
        unichar 	left = NSLeftArrowFunctionKey;
        NSString	*leftKey = [NSString stringWithCharacters:&left length:1];
        unichar 	right = NSRightArrowFunctionKey;
        NSString	*rightKey = [NSString stringWithCharacters:&right length:1];
        
        /* Using the [ ] keys */
/*        NSString	*leftKey = @"[";
        NSString	*rightKey = @"]";*/

        menuItem_previousMessage = [[NSMenuItem alloc] initWithTitle:PREVIOUS_MESSAGE_MENU_TITLE target:self action:@selector(previousMessage:) keyEquivalent:leftKey];
        [[owner menuController] addMenuItem:menuItem_previousMessage toLocation:LOC_Window_Commands];

        menuItem_nextMessage = [[NSMenuItem alloc] initWithTitle:NEXT_MESSAGE_MENU_TITLE target:self action:@selector(nextMessage:) keyEquivalent:rightKey];
        [[owner menuController] addMenuItem:menuItem_nextMessage toLocation:LOC_Window_Commands];
    }
}

//Build the contents of the 'window' menu
- (void)buildWindowMenu
{
    NSMenuItem			*item;
    AIMessageTabViewItem	*tabViewItem;
    NSEnumerator		*enumerator;
    int 			windowKey = 2;

    //Remove any existing menus
    enumerator = [windowMenuArray objectEnumerator];
    while((item = [enumerator nextObject])){
        [[owner menuController] removeMenuItem:item];
    }
    [windowMenuArray release]; windowMenuArray = [[NSMutableArray alloc] init];

    //Contact list window
    //Add toolbar Menu
    item = [[NSMenuItem alloc] initWithTitle:CONTACT_LIST_WINDOW_MENU_TITLE target:self action:@selector(showContactList:) keyEquivalent:@"1"];
    [item setRepresentedObject:contactListWindowController];
    [[owner menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
    [windowMenuArray addObject:[item autorelease]];
    //Add dock Menu
    item = [[NSMenuItem alloc] initWithTitle:CONTACT_LIST_WINDOW_MENU_TITLE target:self action:@selector(showContactList:) keyEquivalent:@""];
    [item setRepresentedObject:contactListWindowController];
    [[owner menuController] addMenuItem:item toLocation:LOC_Dock_Status];
    [windowMenuArray addObject:[item autorelease]];
    
    //Messages window and any open messasge
    if(messageWindowController != nil && [[messageWindowController messageContainerArray] count] != 0){
        //Add a 'Messages' menu item
        item = [[NSMenuItem alloc] initWithTitle:MESSAGES_WINDOW_MENU_TITLE target:self action:@selector(showMessageWindow:) keyEquivalent:@""];
        [[owner menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
        [windowMenuArray addObject:[item autorelease]];

        //Add a menu item for each open message controller
        enumerator = [[messageWindowController messageContainerArray] objectEnumerator];
        while((tabViewItem = [enumerator nextObject])){
            NSString		*windowKeyString;
            
            //Prepare a key equivalent for the controller
            if(windowKey < 10){
                windowKeyString = [NSString stringWithFormat:@"%i",windowKey];
            }else{
                windowKeyString = [NSString stringWithString:@""];
            }

            //Create the menu item
            item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"   %@",[tabViewItem labelString]] target:self action:@selector(showMessageWindow:) keyEquivalent:windowKeyString];
            [item setRepresentedObject:tabViewItem]; //associate this item with a tab

            //Add it to the menu and array
            [[owner menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
            [windowMenuArray addObject:[item autorelease]];

            windowKey++;
        }
    }

    [self updateActiveWindowMenuItem];
}

//remove our menu items
- (void)removeMenuItems
{
    [[owner menuController] removeMenuItem:menuItem_closeTab];
    [[owner menuController] removeMenuItem:menuItem_nextMessage];
    [[owner menuController] removeMenuItem:menuItem_previousMessage];
}

//Updates the 'check' icon so it's next to the active window
- (void)updateActiveWindowMenuItem
{
    NSMenuItem		*item;
    NSEnumerator	*enumerator;

    //'Check' the active window's menu item
    enumerator = [windowMenuArray objectEnumerator];
    while((item = [enumerator nextObject])){
        id representedObject = [item representedObject];

        if(representedObject != nil){
            if(representedObject == (id)activeContainer){
                [item setState:NSOnState];
            }else{
                [item setState:NSOffState];
            }
        }
    }
}

//Validate a menu item
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL enabled = YES;

    if(menuItem == menuItem_closeTab){
        if(![[messageWindowController window] isKeyWindow]) enabled = NO;
    }else if(menuItem == menuItem_nextMessage){
        if(!messageWindowController) enabled = NO;
    }else if(menuItem == menuItem_previousMessage){
        if(!messageWindowController) enabled = NO;
    }

    return(enabled);
}


//Messages ---------------------------------------------------------------------------
//Returns the existing messsage tab for the specified chat
- (AIMessageTabViewItem *)_messageTabForChat:(AIChat *)inChat
{
    NSEnumerator		*enumerator;
    AIMessageTabViewItem	*tabViewItem;

    //Check each message tab for a matching chat
    enumerator = [[messageWindowController messageContainerArray] objectEnumerator];
    while((tabViewItem = [enumerator nextObject])){
        if([[tabViewItem messageViewController] chat] == inChat){
            return(tabViewItem); //We've found a match
        }
    }

    return(nil);
}

//Returns the existing messsage tab for the specified list object
- (AIMessageTabViewItem *)_messageTabForListObject:(AIListObject *)inListObject
{
    NSEnumerator		*enumerator;
    AIMessageTabViewItem	*tabViewItem;

    //Check each message tab for a matching chat
    enumerator = [[messageWindowController messageContainerArray] objectEnumerator];
    while((tabViewItem = [enumerator nextObject])){
        if([[[tabViewItem messageViewController] chat] listObject] == inListObject){
            return(tabViewItem); //We've found a match
        }
    }

    return(nil);
}

//
- (AIMessageTabViewItem *)_createMessageTabForChat:(AIChat *)inChat
{
    AIMessageTabViewItem	*messageTabContainer;
    AIMessageViewController	*messageViewController;

    //Make sure our message window is loaded
    if(!messageWindowController){
        messageWindowController = [[AIMessageWindowController messageWindowControllerWithOwner:owner interface:self] retain];

        //Register to be notified when the message window closes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageWindowWillClose:) name:NSWindowWillCloseNotification object:[messageWindowController window]];
    }

    //Create the message view & tab
    messageViewController = [AIMessageViewController messageViewControllerForChat:inChat owner:owner];
    messageTabContainer = [AIMessageTabViewItem messageTabWithView:messageViewController owner:owner];

    //Add it to the message window & Rebuild the window menu
    [messageWindowController addTabViewItemContainer:messageTabContainer];
    [self buildWindowMenu];

    return(messageTabContainer);
}

//Called as the message window closes
- (void)messageWindowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[messageWindowController window]];
    
    //Release the window and void our reference to it
    [messageWindowController release]; messageWindowController = nil; 
}

//
- (void)increaseUnviewedContentOfListObject:(AIListObject *)inObject
{
    AIMutableOwnerArray	*ownerArray = [inObject statusArrayForKey:@"UnviewedContent"];
    int			currentUnviewed;

    //'UnviewedContent'++
    currentUnviewed = [[ownerArray objectWithOwner:inObject] intValue];
    [ownerArray setObject:[NSNumber numberWithInt:(currentUnviewed+1)] withOwner:inObject];

    //
    [[owner contactController] listObjectStatusChanged:inObject modifiedStatusKeys:[NSArray arrayWithObject:@"UnviewedContent"] delayed:NO silent:NO];
}

//
- (void)clearUnviewedContentOfChat:(AIChat *)inChat
{
    NSEnumerator	*enumerator;
    AIListObject	*listObject;

    //Clear the unviewed content of each list object participating in this chat
    enumerator = [[inChat participatingListObjects] objectEnumerator];
    while(listObject = [enumerator nextObject]){
        AIMutableOwnerArray	*ownerArray = [listObject statusArrayForKey:@"UnviewedContent"];

        if([[ownerArray objectWithOwner:listObject] intValue]){
            //Set 'UnviewedContent' to 0
            [ownerArray setObject:[NSNumber numberWithInt:0] withOwner:listObject];

            //
            [[owner contactController] listObjectStatusChanged:listObject modifiedStatusKeys:[NSArray arrayWithObject:@"UnviewedContent"] delayed:NO silent:NO];
        }

    }
}

@end



