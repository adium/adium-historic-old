/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#define DUAL_SPELLING_DEFAULT_PREFS		@"DualSpellingDefaults"

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
- (AIMessageTabViewItem *)messageTabWithContact:(AIListContact *)inContact account:(AIAccount *)inAccount content:(NSAttributedString *)inContent create:(BOOL)create;
- (void)updateActiveWindowMenuItem;
- (void)increaseUnviewedContentOfHandle:(AIHandle *)inHandle;
- (void)clearUnviewedContentOfHandle:(AIHandle *)inHandle;
- (void)clearUnviewedContentOfContact:(AIListContact *)inContact;
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

    //Open the contact list window
    [self showContactList:nil];

    //Register for the necessary notifications
    [[owner notificationCenter] addObserver:self selector:@selector(initiateMessage:) name:Interface_InitiateMessage object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_DidReceiveContent object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(closeMessage:) name:Interface_CloseMessage object:nil];

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
    [super dealloc];
}

//Contact List ---------------------------------------------------------------------
//Show the contact list window
- (IBAction)showContactList:(id)sender
{
    if(!contactListWindowController){ //Load the window
        contactListWindowController = [[AIContactListWindowController contactListWindowControllerForInterface:self owner:owner] retain];
    }

    [contactListWindowController makeActive:nil];
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

        [[owner notificationCenter] postNotificationName:Interface_CloseMessage
                                                  object:[[container messageViewController] contact]
                                                userInfo:nil];
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
        [self clearUnviewedContentOfContact:[[(AIMessageTabViewItem *)inContainer messageViewController] contact]];
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
//Called when the user requests to initiate a message
- (void)initiateMessage:(NSNotification *)notification
{
    NSDictionary		*userInfo = [notification userInfo];
    AIMessageTabViewItem	*container;

    //Get the information from the notification
    if([userInfo objectForKey:@"To"]){
        container = [self messageTabWithContact:[userInfo objectForKey:@"To"]
                                        account:[userInfo objectForKey:@"From"]
                                        content:[userInfo objectForKey:@"Content"]
                                         create:YES];
        [[container messageViewController] setAccountSelectionMenuVisible:YES]; //Show the message view's account selection menu
        [container makeActive:nil];			//Select the tab
        
    }else{
        //No destination was specified, invoke the standard new message prompt
        [AINewMessagePrompt newMessagePromptWithOwner:owner];
    }
    
}

//Called when a message object is added to a handle
- (void)didReceiveContent:(NSNotification *)notification
{
    NSDictionary		*userInfo = [notification userInfo];
    AIMessageTabViewItem	*container;
    id <AIContentObject>	object = [userInfo objectForKey:@"Object"];

    //Ensure a message window/view is open for this contact
    container = [self messageTabWithContact:[notification object]
                                    account:[object destination]
                                    content:nil
                                        create:YES];
    
    //Make sure the account that was messaged is the active account
    if([object destination] != [[container messageViewController] account]){
        //Select the correct account, and re-show the account menu
        [[container messageViewController] setAccount:[object destination]];
        [[container messageViewController] setAccountSelectionMenuVisible:YES];            
    }

    //Increase the handle's unviewed count (If it's not the active container)
    if(container != activeContainer){
        [self increaseUnviewedContentOfHandle:[object source]];        
    }
}

//Called when the user requests to close a message
- (void)closeMessage:(NSNotification *)notification
{
    AIMessageTabViewItem	*container;

    if(messageWindowController){
        //Remove unviewed content for this contact
        [self clearUnviewedContentOfContact:[notification object]];

        //Find the message controller for this handle, and close it
        container = [self messageTabWithContact:[notification object]
                                        account:nil
                                        content:nil
                                         create:NO];

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
    item = [[NSMenuItem alloc] initWithTitle:CONTACT_LIST_WINDOW_MENU_TITLE target:self action:@selector(showContactList:) keyEquivalent:@"1"];
    [item setRepresentedObject:contactListWindowController];
    [[owner menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
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
//Returns (creating if necessary & desired) a message view controller for the specified contact
- (AIMessageTabViewItem *)messageTabWithContact:(AIListContact *)inContact account:(AIAccount *)inAccount content:(NSAttributedString *)inContent create:(BOOL)create
{
    id <AIInterfaceContainer>	container = nil;

    if(!messageWindowController){ //If the message window isn't loaded, create it
        messageWindowController = [[AIMessageWindowController messageWindowControllerWithOwner:owner interface:self] retain];

        //Register to be notified when the message window closes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageWindowWillClose:) name:NSWindowWillCloseNotification object:[messageWindowController window]];

    }else{ //Otherwise, search it for and existing tab for this contact
        NSEnumerator		*enumerator;
        AIMessageTabViewItem	*tabViewItem;

        enumerator = [[messageWindowController messageContainerArray] objectEnumerator];
        while((tabViewItem = [enumerator nextObject])){
            if([tabViewItem identifier] == inContact){
                container = tabViewItem;
            }
        }
    }

    //If the view doesn't exist, create it
    if(!container && create){
        AIMessageViewController	*controller;

        //Create the message view & tab
        controller = [AIMessageViewController messageViewControllerForContact:inContact account:inAccount content:inContent owner:owner interface:self];
        container = [AIMessageTabViewItem messageTabViewItemWithIdentifier:inContact messageView:controller owner:owner];

        //Add it to the message window & Rebuild the window menu
        [messageWindowController addTabViewItemContainer:container];
        [self buildWindowMenu];
    }

    return(container);
}

//Called as the message window closes
- (void)messageWindowWillClose:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[messageWindowController window]];
    
    //Release the window and void our reference to it
    [messageWindowController release]; messageWindowController = nil; 
}


//
- (void)increaseUnviewedContentOfHandle:(AIHandle *)inHandle
{
    NSMutableDictionary	*statusDict = [inHandle statusDictionary];
    int			currentUnviewed;

    //'UnviewedContent'++
    currentUnviewed = [[statusDict objectForKey:@"UnviewedContent"] intValue];
    [statusDict setObject:[NSNumber numberWithInt:(currentUnviewed+1)] forKey:@"UnviewedContent"];

    //
    [[owner contactController] handleStatusChanged:inHandle modifiedStatusKeys:[NSArray arrayWithObject:@"UnviewedContent"]];
}

//
- (void)clearUnviewedContentOfHandle:(AIHandle *)inHandle
{
    if([[[inHandle statusDictionary] objectForKey:@"UnviewedContent"] intValue]){
        //Set 'UnviewedContent' to 0
        [[inHandle statusDictionary] setObject:[NSNumber numberWithInt:0] forKey:@"UnviewedContent"];

        //
        [[owner contactController] handleStatusChanged:inHandle modifiedStatusKeys:[NSArray arrayWithObject:@"UnviewedContent"]];
    }
}

//
- (void)clearUnviewedContentOfContact:(AIListContact *)inContact
{
    NSEnumerator	*enumerator = [inContact handleEnumerator];
    AIHandle		*handle;

    while((handle = [enumerator nextObject])){
        [self clearUnviewedContentOfHandle:handle];
    }
}

@end



