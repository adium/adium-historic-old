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
#import "ESDualWindowMessageWindowPreferences.h"

#define DUAL_INTERFACE_DEFAULT_PREFS		@"DualWindowDefaults"
#define DUAL_INTERFACE_WINDOW_DEFAULT_PREFS	@"DualWindowMessageDefaults"

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
- (AIMessageWindowController *) messageWindowControllerForContainer:(AIMessageTabViewItem *)container;
- (AIMessageTabViewItem *)_createMessageTabForChat:(AIChat *)inChat inMessageWindowController:(AIMessageWindowController *)messageWindowController;
- (void)closeTabViewItem:(AIMessageTabViewItem *)inTab;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)openChatWithObject:(AIListObject *)inObject inWindow:(AIMessageWindowController *)inWindow;
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
    messageWindowControllerArray = [[NSMutableArray alloc] init];
    activeWindowControllerIndex = -1;

    windowMenuArray = [[NSMutableArray alloc] init];

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
        [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_WINDOW_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    //Install Preference Views
    preferenceController = [[AIDualWindowPreferences dualWindowInterfacePreferencesWithOwner:owner] retain];
    preferenceMessageController = [[ESDualWindowMessageWindowPreferences dualWindowMessageWindowInterfacePreferencesWithOwner:owner] retain];
    
    //Open the contact list window
    [self showContactList:nil];

    //Register for the necessary notifications
    [[owner notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_DidReceiveContent object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    //Install our menu items
    [self addMenuItems];
    [self buildWindowMenu];
    [self preferencesChanged:nil];
}

//Close the interface
- (void)closeInterface
{
    //Close and unload our windows
    if([messageWindowControllerArray count]){
	[messageWindowControllerArray makeObjectsPerformSelector:@selector(closeWindow:) withObject:nil];
	[messageWindowControllerArray removeAllObjects];
    }
    if(contactListWindowController){
        [contactListWindowController close:nil];
    }

    //Stop observing
    [[owner notificationCenter] removeObserver:self];

    //Remove our menu items
    [self removeMenuItems];

    //Cleanup
    [windowMenuArray release];
}

- (void)preferencesChanged:(NSNotification *)notification
{
    if (notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DUAL_WINDOW_INTERFACE] == 0) {
	NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

	alwaysCreateNewWindows = [[preferenceDict objectForKey:KEY_ALWAYS_CREATE_NEW_WINDOWS] boolValue];
	useLastWindow = [[preferenceDict objectForKey:KEY_USE_LAST_WINDOW] boolValue];
    }
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

- (AIContactListWindowController *)contactListWindowController
{
    return contactListWindowController;
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
    AIMessageWindowController	*messageWindowController = [messageWindowControllerArray objectAtIndex:activeWindowControllerIndex];
    [self closeTabViewItem:(AIMessageTabViewItem *)[messageWindowController selectedTabViewItemContainer]];
}

- (void)closeTabViewItem:(AIMessageTabViewItem *)inTab
{
    [[owner interfaceController] closeChat:[[inTab messageViewController] chat]];
}

- (IBAction)openChatInNewWindow:(id)sender
{
    AIListObject * inObject = [[owner menuController] contactualMenuContact];
    if (inObject) [self openChatWithObject:inObject inWindow:nil];
}

- (IBAction)openChatInPrimaryWindow:(id)sender
{
    AIListObject * inObject = [[owner menuController] contactualMenuContact];
    if (inObject) [self openChatWithObject:inObject inWindow:[messageWindowControllerArray count] ? [messageWindowControllerArray objectAtIndex:0] : nil];
}

- (IBAction)consolidateAllChats:(id)sender
{
    AIMessageWindowController * messageWindowController;
    AIMessageTabViewItem * tabViewItem;
    NSEnumerator * windowEnumerator;
    NSEnumerator * tabViewEnumerator;

    AIMessageWindowController * firstMessageWindowController = [messageWindowControllerArray objectAtIndex:0];
    //enumerate all windows
    windowEnumerator = [messageWindowControllerArray objectEnumerator];
    while (messageWindowController = [windowEnumerator nextObject])
    {
	if ([[messageWindowController messageContainerArray] count] != 0){

	    //Add a menu item for each open message container in this window
	    tabViewEnumerator = [[messageWindowController messageContainerArray] objectEnumerator];
	    while((tabViewItem = [tabViewEnumerator nextObject])){
		[self openChatWithObject:[[tabViewItem messageViewController] listObject] inWindow:firstMessageWindowController];
	    }
	}
    }
}

- (void)openChatWithObject:(AIListObject *)inObject inWindow:(AIMessageWindowController *)messageWindowController
{
    AIChat * theChat;
    AIMessageWindowController * oldMesssageWindowController = nil;
    AIMessageViewController * messageViewController;
    
    AIMessageTabViewItem * tabViewItem = [self _messageTabForListObject:inObject];

    if (!tabViewItem){
	theChat = [[owner contentController] openChatOnAccount:nil withListObject:inObject];
	tabViewItem = [self _messageTabForListObject:inObject];
	oldMesssageWindowController = [self messageWindowControllerForContainer:tabViewItem];
	[oldMesssageWindowController removeTabViewItemContainer:tabViewItem removingChat:NO];
	[self _createMessageTabForChat:theChat inMessageWindowController:messageWindowController];
	[self openChat:theChat]; //switch to it and configure as necessary
	[self buildWindowMenu]; //Rebuild our window menu
	
    }else{
	oldMesssageWindowController = [self messageWindowControllerForContainer:tabViewItem];
	
	theChat = [[tabViewItem messageViewController] chat];

    if ((!messageWindowController) || ([[messageWindowController messageContainerArray] indexOfObjectIdenticalTo:tabViewItem] == NSNotFound)){ //tab view isn't in this window already (or we want a new window)

	//same as other routine - consolidate

	//Make sure our message window is loaded
	if(!messageWindowController || ![messageWindowControllerArray count]){
	    messageWindowController = [AIMessageWindowController messageWindowControllerWithOwner:owner interface:self];

	    //Register to be notified when the message window closes
	    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageWindowWillClose:) name:NSWindowWillCloseNotification object:[messageWindowController window]];

	    //Add the messageWindowController to our array
	    [messageWindowControllerArray addObject:messageWindowController];
	    activeWindowControllerIndex = [messageWindowControllerArray count] - 1;
	} else {
	    activeWindowControllerIndex = [messageWindowControllerArray indexOfObjectIdenticalTo:messageWindowController];
	}
	
	//Create the message view & tab
	messageViewController = [[tabViewItem messageViewController] retain];
	[oldMesssageWindowController removeTabViewItemContainer:tabViewItem removingChat:NO];

	tabViewItem = [AIMessageTabViewItem messageTabWithView:messageViewController owner:owner];
	[messageWindowController addTabViewItemContainer:tabViewItem];
	
    }
    [self buildWindowMenu]; //Rebuild our window menu   

    }
 
}
//Show the message window
- (IBAction)showMessageWindow:(id)sender
{
    if([messageWindowControllerArray count]){ //Show the message window only if it already exists (otherwise it would be empty)
        if([sender isKindOfClass:[NSMenuItem class]]){ //Select the tab if called in response to a menu selection
            id	container = [(NSMenuItem *)sender representedObject];
	    AIMessageWindowController * messageWindowController = [self messageWindowControllerForContainer:(AIMessageTabViewItem *)container];

            [messageWindowController selectTabViewItemContainer:(AIMessageTabViewItem *)container];

	    activeWindowControllerIndex = [messageWindowControllerArray indexOfObjectIdenticalTo:messageWindowController]; //update the index to the new window
        }else{ //Otherwise just bring the window forward

	    AIMessageWindowController * messageWindowController = [messageWindowControllerArray lastObject];
	    [messageWindowController showWindow:nil];

        }
    }
}

- (AIMessageWindowController *) messageWindowControllerForContainer:(AIMessageTabViewItem *)container
{
    NSEnumerator *windowEnumerator = [messageWindowControllerArray objectEnumerator];
    AIMessageWindowController *messageWindowController;
    while (messageWindowController = [windowEnumerator nextObject])
    {
	NSArray	*containerArray = [messageWindowController messageContainerArray];
	if ([containerArray indexOfObjectIdenticalTo:container] != NSNotFound)
	    return messageWindowController;
    }

    return nil;
}

//Cycling -------------------------------------------------------------------------
//Select the next message
- (IBAction)nextMessage:(id)sender
{
    AIMessageWindowController *messageWindowController;
    int loop, numWindows;
    int	newIndex;
    BOOL success = NO;

    if ((!activeContainer) || (activeContainer == contactListWindowController)) //contact list is active or nothing is
    {
	if ([messageWindowControllerArray count])
	{	//warning may need check here
	    messageWindowController = [messageWindowControllerArray objectAtIndex:0];
	    [[[messageWindowController messageContainerArray] objectAtIndex:0] makeActive:nil];
	    [messageWindowController showWindow:nil];
	}
    }
    else
    {
	loop = activeWindowControllerIndex;
	numWindows = [messageWindowControllerArray count];
	while (loop < numWindows && !success)
	{
	    messageWindowController = [messageWindowControllerArray objectAtIndex:loop];
	    NSArray	*containerArray = [messageWindowController messageContainerArray];

	    if (loop == activeWindowControllerIndex) //we're looking at the current window
		newIndex = [containerArray indexOfObject:activeContainer] + 1;
	    else
		newIndex = 0;
	    
	    if(newIndex < [containerArray count]){
		[[containerArray objectAtIndex:newIndex] makeActive:nil];
		activeWindowControllerIndex = loop;
		[messageWindowController showWindow:nil];
		success = YES;
	    }


	    loop++;
	}
	if (!success) { //the new index was greater than the last window's index
	    [contactListWindowController makeActive:nil];
	}
    }

}

//Select the previous message
- (IBAction)previousMessage:(id)sender
{
    AIMessageWindowController *messageWindowController;
    int loop;
    int	newIndex;
    BOOL success = NO;

    if ((!activeContainer) || (activeContainer == contactListWindowController) ) //nothing or contact list is active
    {
	if ([messageWindowControllerArray count])
	{	//warning may need check here
	    messageWindowController = [messageWindowControllerArray lastObject];
	    [[[messageWindowController messageContainerArray] lastObject] makeActive:nil];
	    [messageWindowController showWindow:nil];
	}
    }
    else
    {	loop = activeWindowControllerIndex;
	while (loop >= 0 && !success)
	{	    
	    messageWindowController = [messageWindowControllerArray objectAtIndex:loop];
	    NSArray	*containerArray = [messageWindowController messageContainerArray];

	    if (loop == activeWindowControllerIndex) //we're looking at the current window
		newIndex = [containerArray indexOfObject:activeContainer] - 1;
	    else
		newIndex = [containerArray count] - 1;
	    
	    if(newIndex >= 0){
		[[containerArray objectAtIndex:newIndex] makeActive:nil];
		activeWindowControllerIndex = loop;
		[messageWindowController showWindow:nil];
		success = YES;
	    }


	    loop--;
	}
	if (!success) { //the new index was greater than the last window's index
	    [contactListWindowController makeActive:nil];
	}
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

    //the incoming container is a tabViewItem
    if([inContainer isKindOfClass:[AIMessageTabViewItem class]]){
	//Set the container's handle's content as viewed
        [self clearUnviewedContentOfChat:[[(AIMessageTabViewItem *)inContainer messageViewController] chat]];

	//Make sure the container's window is in the front
	AIMessageWindowController * messageWindowController = [self messageWindowControllerForContainer:(AIMessageTabViewItem *)inContainer];
	activeWindowControllerIndex = [messageWindowControllerArray indexOfObjectIdenticalTo:messageWindowController];
	lastUsedMessageWindowControllerIndex = activeWindowControllerIndex;
    }
    else
	activeWindowControllerIndex = -1; //no active window controller -> contact list

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
	    [[self messageWindowControllerForContainer:messageTabContainer] showWindow:nil];
        }
    }

    //Create a tab for this chat
    if(!messageTabContainer){
        messageTabContainer = [self _createMessageTabForChat:inChat];
    }

    //Display the account selector
    if(![[[inChat statusDictionary] objectForKey:@"DisallowAccountSwitching"] boolValue]){
        [[messageTabContainer messageViewController] setAccountSelectionMenuVisible:YES];
    }
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
    AIMessageWindowController 	*messageWindowController;

    container = [self _messageTabForChat:inChat];
    if (container)
	messageWindowController = [self messageWindowControllerForContainer:container];

    if(messageWindowController){
        //Remove unviewed content for this contact
        [self clearUnviewedContentOfChat:inChat];

        //Close it
        [messageWindowController removeTabViewItemContainer:container];
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

    //Add contextual menu items
    menuItem_openInNewWindow = [[NSMenuItem alloc] initWithTitle:@"Chat in New Window" target:self action:@selector(openChatInNewWindow:) keyEquivalent:@""];
    [[owner menuController] addContextualMenuItem:menuItem_openInNewWindow toLocation:Context_Contact_Additions];
    
    menuItem_openInPrimaryWindow = [[NSMenuItem alloc] initWithTitle:@"Chat in Primary Window" target:self action:@selector(openChatInPrimaryWindow:) keyEquivalent:@""];
    [[owner menuController] addContextualMenuItem:menuItem_openInPrimaryWindow toLocation:Context_Contact_Additions];

    menuItem_consolidate = [[NSMenuItem alloc] initWithTitle:@"Consolidate All Chats" target:self action:@selector(consolidateAllChats:) keyEquivalent:@"O"];
    [[owner menuController] addMenuItem:menuItem_consolidate toLocation:LOC_Window_Commands];
}

//Build the contents of the 'window' menu
- (void)buildWindowMenu
{
    NSMenuItem			*item;
    AIMessageTabViewItem	*tabViewItem;
    NSEnumerator		*enumerator;
    NSEnumerator 		*tabViewEnumerator;
    NSEnumerator		*windowEnumerator;
    AIMessageWindowController 	*messageWindowController;
    int 			windowKey = 2;


    //Remove any existing menus
    enumerator = [windowMenuArray objectEnumerator];
    while((item = [enumerator nextObject])){
        [[owner menuController] removeMenuItem:item];
    }
    [windowMenuArray release]; windowMenuArray = [[NSMutableArray alloc] init];

    //Contact list window
    //Add toolbar Menu
    item = [[NSMenuItem alloc] initWithTitle:CONTACT_LIST_WINDOW_MENU_TITLE target:self action:@selector(showContactList:) keyEquivalent:@"/"];
    [item setRepresentedObject:contactListWindowController];
    [[owner menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
    [windowMenuArray addObject:[item autorelease]];
    //Add dock Menu
    item = [[NSMenuItem alloc] initWithTitle:CONTACT_LIST_WINDOW_MENU_TITLE target:self action:@selector(showContactList:) keyEquivalent:@""];
    [item setRepresentedObject:contactListWindowController];
    [[owner menuController] addMenuItem:item toLocation:LOC_Dock_Status];
    [windowMenuArray addObject:[item autorelease]];

    //Messages window and any open messasge
    if([messageWindowControllerArray count])
    {
	//Add a 'Messages' menu item
	item = [[NSMenuItem alloc] initWithTitle:MESSAGES_WINDOW_MENU_TITLE target:self action:@selector(showMessageWindow:) keyEquivalent:@""];
        [[owner menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
        [windowMenuArray addObject:[item autorelease]];

	//enumerate all windows
	windowEnumerator = [messageWindowControllerArray objectEnumerator];
	while (messageWindowController = [windowEnumerator nextObject])
	{
	    if ([[messageWindowController messageContainerArray] count] != 0){

		//Add a menu item for each open message container in this window
		tabViewEnumerator = [[messageWindowController messageContainerArray] objectEnumerator];
		while((tabViewItem = [tabViewEnumerator nextObject])){
		    NSString		*windowKeyString;

		    //Prepare a key equivalent for the controller
		    if(windowKey < 10){
			windowKeyString = [NSString stringWithFormat:@"%i",(windowKey-1)];
		    }else if (windowKey == 10){
			windowKeyString = [NSString stringWithString:@"0"];
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
        if((activeWindowControllerIndex==-1) || (![[[messageWindowControllerArray objectAtIndex:activeWindowControllerIndex] window] isKeyWindow]) ) enabled = NO;
    }else if(menuItem == menuItem_nextMessage){
        if(![messageWindowControllerArray count]) enabled = NO;
    }else if(menuItem == menuItem_previousMessage){
        if(![messageWindowControllerArray count]) enabled = NO;
    }else if (menuItem == menuItem_openInNewWindow || menuItem == menuItem_openInPrimaryWindow){
	enabled = ([[owner menuController] contactualMenuContact] != nil);
    }else if (menuItem == menuItem_consolidate)
    {
	if ([messageWindowControllerArray count] <= 1) enabled = NO; //only with more than one window open
    }

    return(enabled);
}


//Messages ---------------------------------------------------------------------------
//Returns the existing messsage tab for the specified chat
- (AIMessageTabViewItem *)_messageTabForChat:(AIChat *)inChat
{
    NSEnumerator		*windowEnumerator;
    NSEnumerator		*tabViewEnumerator;
    AIMessageTabViewItem	*tabViewItem;
    AIMessageWindowController 	*messageWindowController;

    windowEnumerator = [messageWindowControllerArray objectEnumerator];

    while (messageWindowController = [windowEnumerator nextObject])
    {
	//Check each message tab for a matching chat
	tabViewEnumerator = [[messageWindowController messageContainerArray] objectEnumerator];
	while((tabViewItem = [tabViewEnumerator nextObject])){
	    if([[tabViewItem messageViewController] chat] == inChat){
		return(tabViewItem); //We've found a match
	    }
	}
    }
    return(nil);
}

//Returns the existing messsage tab for the specified list object
- (AIMessageTabViewItem *)_messageTabForListObject:(AIListObject *)inListObject
{
    NSEnumerator		*windowEnumerator;
    NSEnumerator		*tabViewEnumerator;
    AIMessageTabViewItem	*tabViewItem;
    AIMessageWindowController 	*messageWindowController;

    windowEnumerator = [messageWindowControllerArray objectEnumerator];

    while (messageWindowController = [windowEnumerator nextObject])
    {
	//Check each message tab for a matching chat
	tabViewEnumerator = [[messageWindowController messageContainerArray] objectEnumerator];
	while((tabViewItem = [tabViewEnumerator nextObject])){
	    if([[[tabViewItem messageViewController] chat] listObject] == inListObject){
		return(tabViewItem); //We've found a match
	    }
	}
    }
    return(nil);
}

//create a tab for the chat.  add it to the first message window, creating one if necessary
- (AIMessageTabViewItem *)_createMessageTabForChat:(AIChat *)inChat
{
    AIMessageTabViewItem	*messageTabContainer;
    AIMessageWindowController	*messageWindowController;
    
    if (![messageWindowControllerArray count] || alwaysCreateNewWindows)
	messageWindowController = nil;
    else if (useLastWindow)
	messageWindowController = [messageWindowControllerArray objectAtIndex:lastUsedMessageWindowControllerIndex];
    else
	messageWindowController = [messageWindowControllerArray objectAtIndex:0];
    
    messageTabContainer = [self _createMessageTabForChat:inChat inMessageWindowController:messageWindowController];

    return messageTabContainer;
}

//pass nil to create a new window for this tab; otherwise, put a tab containing inChat into the window controller by messageWindowController
- (AIMessageTabViewItem *)_createMessageTabForChat:(AIChat *)inChat inMessageWindowController:(AIMessageWindowController *)messageWindowController
{
    AIMessageTabViewItem	*messageTabContainer;
    AIMessageViewController	*messageViewController;

    //Make sure our message window is loaded
    if(!messageWindowController || ![messageWindowControllerArray count]){
	messageWindowController = [AIMessageWindowController messageWindowControllerWithOwner:owner interface:self];

	//Register to be notified when the message window closes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageWindowWillClose:) name:NSWindowWillCloseNotification object:[messageWindowController window]];

	//Add the messageWindowController to our array
	[messageWindowControllerArray addObject:messageWindowController];
	activeWindowControllerIndex = [messageWindowControllerArray count] - 1;
    } else {
    activeWindowControllerIndex = [messageWindowControllerArray indexOfObjectIdenticalTo:messageWindowController];
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
    NSWindow * theWindow = [notification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[notification object]];

    //search for this window out the windowcontroller array
    NSEnumerator *windowEnumerator = [messageWindowControllerArray objectEnumerator];
    AIMessageWindowController *messageWindowController;
    while (messageWindowController = [windowEnumerator nextObject])
    {
	if (theWindow == [messageWindowController window]) {
	    //Remove the window from our array, releasing the window in the process
	    [messageWindowControllerArray removeObjectIdenticalTo:messageWindowController];
	}
    }
    activeWindowControllerIndex = -1; //nothing's active; if another window takes over in a brief moment this will change
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



