/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIContactListWindowController.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import "AIMessageTabViewItem.h"
#import "AINewMessagePrompt.h"
#import "AIDualWindowPreferences.h"
#import "AIDualWindowAdvancedPrefs.h"
#import "ESDualWindowMessageWindowPreferences.h"
#import "ESDualWindowMessageAdvancedPreferences.h"

#define CONTACT_LIST_WINDOW_MENU_TITLE  AILocalizedString(@"Contact List","Title for the contact list menu item")
#define MESSAGES_WINDOW_MENU_TITLE		AILocalizedString(@"Messages","Title for the messages window menu item")
#define CLOSE_TAB_MENU_TITLE			AILocalizedString(@"Close Tab","Title for the close tab menu item")
#define CLOSE_MENU_TITLE				AILocalizedString(@"Close","Title for the close menu item")
#define PREVIOUS_MESSAGE_MENU_TITLE		AILocalizedString(@"Previous Chat",nil)
#define NEXT_MESSAGE_MENU_TITLE			AILocalizedString(@"Next Chat",nil)
#define ARRANGE_MENU_TITLE				AILocalizedString(@"Arrange Tabs","Title for the arrange tabs menu item")
#define ARRANGE_ALTERNATE_MENU_TITLE	AILocalizedString(@"Arrange All Tabs","Title for the arrange all tabs menu item")
#define CHAT_IN_NEW_WINDOW				AILocalizedString(@"Chat in New Window",nil)
#define CHAT_IN_PRIMARY_WINDOW			AILocalizedString(@"Chat in Primary Window",nil)
#define CONSOLIDATE_ALL_CHATS			AILocalizedString(@"Consolidate All Chats",nil)
#define SPLIT_ALL_CHATS					AILocalizedString(@"Split All Chats by Group",nil)
#define TOGGLE_TAB_BAR					AILocalizedString(@"Toggle Tab Bar",nil)

@interface AIDualWindowInterfacePlugin (PRIVATE)
- (void)addMenuItems;
- (void)removeMenuItems;
- (void)buildWindowMenu;
- (void)_updateActiveWindowMenuItem;
- (void)_updateCloseMenuKeys;
- (void)_increaseUnviewedContentOfListObject:(AIListObject *)inObject;
- (void)_clearUnviewedContentOfChat:(AIChat *)inChat;
- (AIMessageTabViewItem *)_createMessageTabForChat:(AIChat *)inChat;
- (AIMessageTabViewItem *)_messageTabForChat:(AIChat *)inChat;
- (AIMessageTabViewItem *)_messageTabForListObject:(AIListObject *)inListObject;
- (AIMessageWindowController *)_messageWindowForContainer:(AIMessageTabViewItem *)container;
- (AIMessageTabViewItem *)_createMessageTabForChat:(AIChat *)inChat inMessageWindowController:(AIMessageWindowController *)messageWindowController;
- (void)closeTabViewItem:(AIMessageTabViewItem *)inTab;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)contactOrderChanged:(NSNotification *)notification;
- (void)listObjectStatusChanged:(NSNotification *)notification;
- (void)_transferMessageTabContainer:(AIMessageTabViewItem *)tabViewItem toWindow:(AIMessageWindowController *)messageWindowController;
- (void)arrangeTabs:(id)sender;
- (void)arrangeTabsByGroup:(id)sender;
- (AIMessageWindowController *)_primaryMessageWindow;
- (AIMessageWindowController *)_createMessageWindow;
- (void)_destroyMessageWindow:(AIMessageWindowController *)inWindow;
@end

@implementation AIDualWindowInterfacePlugin

#define DUAL_WINDOW_THEMABLE_PREFS      @"Dual Window Themable Prefs"

//Plugin setup ------------------------------------------------------------------
- (void)installPlugin
{
    //Register our interface
    [[adium interfaceController] registerInterfaceController:self];
}

- (void)uninstallPlugin
{
	
}

//Open the interface
- (void)openInterface
{
    //init
	arrangeByGroupWindowList = [[NSMutableDictionary alloc] init];
    messageWindowControllerArray = [[NSMutableArray alloc] init];
    forceIntoNewWindow = NO;
    forceIntoTab = NO;
    lastUsedMessageWindow = nil;
	
    windowMenuArray = [[NSMutableArray alloc] init];
	
    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_WINDOW_DEFAULT_PREFS
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];    
    
    //Register themable preferences
    [[adium preferenceController] registerThemableKeys:[NSArray arrayNamed:DUAL_WINDOW_THEMABLE_PREFS 
																  forClass:[self class]]
											  forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    
    //Install Preference Views
    preferenceController = [[AIDualWindowPreferences preferencePane] retain];
    preferenceAdvController = [[AIDualWindowAdvancedPrefs preferencePane] retain];
    preferenceMessageController = [[ESDualWindowMessageWindowPreferences preferencePane] retain];
    preferenceMessageAdvController = [[ESDualWindowMessageAdvancedPreferences preferencePane] retain];
	
    //Open the contact list window
    [self showContactList:nil];
	
    //Register for the necessary notifications
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(didReceiveContent:) 
									   name:Content_DidReceiveContent
									 object:nil];
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(didReceiveContent:)
									   name:Content_FirstContentRecieved 
									 object:nil];
	
	[[adium notificationCenter] addObserver:self 
								   selector:@selector(contactOrderChanged:)
									   name:Contact_OrderChanged 
									 object:nil];
	[[adium notificationCenter] addObserver:self 
								   selector:@selector(listObjectStatusChanged:)
									   name:ListObject_StatusChanged
									 object:nil];
	
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:) 
									   name:Preference_GroupChanged 
									 object:nil];
    
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
    [[adium notificationCenter] removeObserver:self];
	
    //Remove our menu items
    [self removeMenuItems];
	
    //Cleanup
    [windowMenuArray release];
}

//Handle a reopen/dock icon click
- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows
{
    //The 'visibleWindows' variable passed by the system is unreliable, since the presence
    //of the Adium system menu will cause it to always be YES.  We won't use it below.
	
    //If no windows are visible, show the contact list
    if(contactListWindowController == nil && [messageWindowControllerArray count] == 0){
		[self showContactList:nil];
    }else{
		//If windows are open, try switching to a tab with unviewed content
		if(![[adium contentController] switchToMostRecentUnviewedContent]){
			NSEnumerator    *enumerator;
			NSWindow	    *window, *targetWindow = nil;
			BOOL	    unMinimizedWindows = 0;
			
			//If there was no unviewed content, ensure that atleast one of Adium's windows is unminimized
			enumerator = [[NSApp windows] objectEnumerator];
			while(window = [enumerator nextObject]){
				//Check stylemask to rule out the system menu's window (Which reports itself as visible like a real window)
				if(([window styleMask] & (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask))){
					if(!targetWindow) targetWindow = window;
					if(![window isMiniaturized]) unMinimizedWindows++;
				}
			}
			//If there are no unminimized windows, unminimize the last one
			if(unMinimizedWindows == 0 && targetWindow){
				[targetWindow deminiaturize:nil];
			}
		}
    }
	
    return(NO); //we handled the reopen, return NO so NSApp does nothing.
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if (notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DUAL_WINDOW_INTERFACE] == 0) {
		NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
		
        //Cache the window spawning preferences
		alwaysCreateNewWindows = [[preferenceDict objectForKey:KEY_ALWAYS_CREATE_NEW_WINDOWS] boolValue];
		useLastWindow = [[preferenceDict objectForKey:KEY_USE_LAST_WINDOW] boolValue];
		
		//Cache the tab sorting prefs
		BOOL newKeepTabsArranged = [[preferenceDict objectForKey:KEY_KEEP_TABS_ARRANGED] boolValue];
		BOOL newArrangeByGroup = [[preferenceDict objectForKey:KEY_ARRANGE_TABS_BY_GROUP] boolValue];

		//If group arranging changed, check if we should autoarrange by group
		if( newArrangeByGroup != arrangeByGroup ) {
			
			arrangeByGroup = newArrangeByGroup;
			
			AIMessageWindowController   *controller;
			NSEnumerator				*enumerator = [messageWindowControllerArray objectEnumerator];
			while( controller = [enumerator nextObject] ) {
				[[controller customTabsView] setAllowsTabDragging:(!arrangeByGroup)];
			}
			
			// Force arrange by group if we should
			if( arrangeByGroup )
				[self arrangeTabsByGroup:menuItem_splitByGroup];
		}
		
		//If forced sorting changed, check if we should autoarrange tabs
		if( newKeepTabsArranged != keepTabsArranged ) {
			
			keepTabsArranged = newKeepTabsArranged;
			
			AIMessageWindowController   *controller;
			NSEnumerator				*enumerator = [messageWindowControllerArray objectEnumerator];
			while( controller = [enumerator nextObject] ) {
				[[controller customTabsView] setAllowsTabRearranging:(!keepTabsArranged)];
			}
			
			//Force the arrangement if we should
			if( keepTabsArranged )
				[self arrangeTabs:menuItem_arrangeTabs_alternate];
		}
						
    } else if( contactListWindowController &&
			   ([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_LIST_DISPLAY] == 0) ){
		
		BOOL windowIsBorderless = [[contactListWindowController window] isBorderless];
		BOOL borderlessPref = [[[adium preferenceController] preferenceForKey:KEY_SCL_BORDERLESS 
																		group:PREF_GROUP_CONTACT_LIST_DISPLAY] boolValue];
		
		if (windowIsBorderless != borderlessPref) {
			[[contactListWindowController window] performClose:nil];
			[self showContactList:nil];
		}
    }
}

- (void)contactOrderChanged:(NSNotification *)notification
{
	if( keepTabsArranged ) {
		[self arrangeTabs:menuItem_arrangeTabs_alternate];
	}
	
}

- (void)listObjectStatusChanged:(NSNotification *)notification
{
	if( keepTabsArranged ) {
		[self arrangeTabs:menuItem_arrangeTabs_alternate];
	}
}


//A tab was moved from one window to another
- (void)transferMessageTabContainer:(id)tabViewItem toWindow:(id)newMessageWindow atIndex:(int)index withTabBarAtPoint:(NSPoint)screenPoint
{
    AIMessageWindowController 	*oldMessageWindow;
    
    //Transfer container from one one window to another
    oldMessageWindow = [self _messageWindowForContainer:(AIMessageTabViewItem *)tabViewItem];

    if(oldMessageWindow != newMessageWindow){
        //Get the frame of the source window (We must do this before removing the tab, since removing a tab may destroy the source window)
        NSRect  oldMessageWindowFrame = [[oldMessageWindow window] frame];

        //Remove the tab
        [tabViewItem retain];
        [oldMessageWindow removeTabViewItemContainer:(AIMessageTabViewItem *)tabViewItem];
        
        if(!newMessageWindow) {
			NSRect          newFrame;

            //Default to the width of the source message window, and the drop point
			newFrame.size.width = oldMessageWindowFrame.size.width;
			newFrame.size.height = oldMessageWindowFrame.size.height;
			
			newFrame.origin = screenPoint;
			
            //Create a new window, set the frame
            newMessageWindow = [self _createMessageWindow];
			
			if( newFrame.origin.x == -1 && newFrame.origin.y == -1) {
				NSRect curFrame = [[newMessageWindow window] frame];
				newFrame.origin = curFrame.origin;				
				//newFrame.origin.x = NSMinX(oldMessageWindowFrame);
				//newFrame.origin.y = NSMaxY(oldMessageWindowFrame);

				//[[newMessageWindow window] cascadeTopLeftFromPoint:(newFrame.origin)];
			}
			
			[[newMessageWindow window] setFrame:newFrame display:NO];

        }
        
        [(AIMessageWindowController *)newMessageWindow addTabViewItemContainer:(AIMessageTabViewItem *)tabViewItem 
																	   atIndex:index]; 
		[tabViewItem makeActive:nil];
        [tabViewItem release];
    }
	
}


//Contact List ---------------------------------------------------------------------
//Show the contact list window
- (IBAction)showContactList:(id)sender
{
    if(!contactListWindowController){ //Load the window
        contactListWindowController = [[AIContactListWindowController contactListWindowControllerForInterface:self] retain];
    }
    [contactListWindowController makeActive:nil];
}

//Show the contact list window and bring Adium to the front
- (IBAction)showContactListAndBringToFront:(id)sender
{
    [self showContactList:nil];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)toggleContactList:(id)sender
{
    if(contactListWindowController && [[contactListWindowController window] isMainWindow]){ //The window is loaded and main
        [[contactListWindowController window] performClose:nil];
    }else{
		[self showContactList:nil];
    } 
	
}

//Messages -------------------------------------------------------------------------
//Close the active window
- (IBAction)close:(id)sender
{
    [[[NSApplication sharedApplication] keyWindow] performClose:nil];
}

//Close the active tab
- (IBAction)closeTab:(id)sender
{
    if([activeContainer isKindOfClass:[AIMessageTabViewItem class]]){ //Just to make sure the active container is really a tab
        [[adium interfaceController] closeChat:[[(AIMessageTabViewItem *)activeContainer messageViewController] chat]];    
    }
}

//Open chat in new window (Must ONLY be called by a context menu)
- (IBAction)openChatInNewWindow:(id)sender
{
    AIListContact 	*listContact = [[adium menuController] contactualMenuContact];
    AIChat			*chat;
	
    if(listContact){
        forceIntoNewWindow = YES; //Temporarily override our preference
        chat = [[adium contentController] openChatWithContact:listContact];
        [[adium interfaceController] setActiveChat:chat];
    }
}

//Open chat as tab in primary window (Must ONLY be called by a context menu)
- (IBAction)openChatInPrimaryWindow:(id)sender
{
    AIListContact 	*listContact = [[adium menuController] contactualMenuContact];
    AIChat			*chat;
	
    if(listContact){
        forceIntoTab = YES; //Temporarily override our preference
        chat = [[adium contentController] openChatWithContact:listContact];
        [[adium interfaceController] setActiveChat:chat];
    }
}

//Consilidate all open chats into a single tabbed window
- (IBAction)consolidateAllChats:(id)sender
{
    AIMessageWindowController	*messageWindowController;
    NSEnumerator		*windowEnumerator;
    AIMessageWindowController 	*targetMessageWindow = [self _primaryMessageWindow];
	
    //Enumerate all windows
    windowEnumerator = [messageWindowControllerArray objectEnumerator];
    while(messageWindowController = [windowEnumerator nextObject]){
        NSEnumerator		*tabViewEnumerator;
        AIMessageTabViewItem	*tabViewItem;
		
        tabViewEnumerator = [[messageWindowController messageContainerArray] objectEnumerator];
        while((tabViewItem = [tabViewEnumerator nextObject])){
            [self _transferMessageTabContainer:tabViewItem toWindow:targetMessageWindow];
        }
    }
    
    [self buildWindowMenu]; //Rebuild our window menu
}

//Show the message window (Must ONLY be called by a window menu item)
- (IBAction)showMessageWindow:(id)sender
{
    AIMessageTabViewItem	*container;
	
    if([messageWindowControllerArray count] && [sender isKindOfClass:[NSMenuItem class]]){
        container = (AIMessageTabViewItem *)[(NSMenuItem *)sender representedObject];
        [container makeActive:nil];
    }
    
    //Give Adium focus
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

//Called as a message window closes, destroy the window
- (void)messageWindowWillClose:(NSNotification *)notification
{
    NSWindow			*theWindow = [notification object];
    NSEnumerator 		*windowEnumerator;
    AIMessageWindowController 	*messageWindowController;
	
    //Search for this window in the windowcontroller array
    windowEnumerator = [messageWindowControllerArray objectEnumerator];
    while(messageWindowController = [windowEnumerator nextObject]){
        if(theWindow == [messageWindowController window]){
            [self _destroyMessageWindow:messageWindowController];
        }
    }
}


//Cycling -------------------------------------------------------------------------
//Select the next message
- (IBAction)nextMessage:(id)sender
{
    AIMessageWindowController 	*messageWindow;
	
    //contact list is active or nothing is
    if ((!activeContainer) || (activeContainer == contactListWindowController)) {
		if([messageWindowControllerArray count]){
			[[messageWindowControllerArray objectAtIndex:0] selectFirstTabViewItemContainer];
		}
		
    }else if([activeContainer isKindOfClass:[AIMessageTabViewItem class]]){ //dealing w/ a tab
																			//Get the selected message window
        messageWindow = [self _messageWindowForContainer:(AIMessageTabViewItem *)activeContainer];
		
        //Select the next tab
        if(![messageWindow selectNextTabViewItemContainer]){
            //If there are no more tabs in this window, move to the next window
            int nextIndex = [messageWindowControllerArray indexOfObject:messageWindow] + 1;
			
            if(nextIndex < [messageWindowControllerArray count]){
                messageWindow = [messageWindowControllerArray objectAtIndex:nextIndex];
            }else{ //Wrap around, select first tab of first window
                messageWindow = [messageWindowControllerArray objectAtIndex:0];
            }
			
            [messageWindow selectFirstTabViewItemContainer];
        }
    }
}

//Select the previous message
- (IBAction)previousMessage:(id)sender
{
    AIMessageWindowController *messageWindow;
	
    //contact list is active or nothing is
    if ((!activeContainer) || (activeContainer == contactListWindowController)) {
		if([messageWindowControllerArray count]){
            [[messageWindowControllerArray lastObject] selectLastTabViewItemContainer];
		}
		
    }else if([activeContainer isKindOfClass:[AIMessageTabViewItem class]]){ //dealing w/ a tab
																			//Get the selected message window
        messageWindow = [self _messageWindowForContainer:(AIMessageTabViewItem *)activeContainer];
		
        //Select the next tab
        if(![messageWindow selectPreviousTabViewItemContainer]){
            //If there are no more tabs in this window, move to the next window
            int nextIndex = [messageWindowControllerArray indexOfObject:messageWindow] - 1;
			
            if(nextIndex >= 0){
                messageWindow = [messageWindowControllerArray objectAtIndex:nextIndex];
            }else{ //Wrap around, select first tab of first window
                messageWindow = [messageWindowControllerArray lastObject];
            }
			
            [messageWindow selectLastTabViewItemContainer];
        }
    }
	
}


//Container Interface --------------------------------------------------------------
//A container was opened
- (void)containerDidOpen:(id <AIInterfaceContainer>)inContainer
{
    [self buildWindowMenu]; //Rebuild our window menu
}

//A container was closed
- (void)containerDidClose:(id <AIInterfaceContainer>)inContainer
{
    if(inContainer == activeContainer){
		activeContainer = nil;
	}
	
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
        [self _clearUnviewedContentOfChat:[[(AIMessageTabViewItem *)inContainer messageViewController] chat]];
		
		//Remember that we were on this container last (used for tab spawning)
		lastUsedMessageWindow = [self _messageWindowForContainer:(AIMessageTabViewItem *)inContainer];
    }
    
    //Update the close window/close tab menu item keys
    [self _updateCloseMenuKeys];
    [self _updateActiveWindowMenuItem];
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
        [self openChat:[object chat]];
    }
	
    //Increase the contacts unviewed count (If it's not the active container and is the listObject of this cat)
    if(messageTabContainer && messageTabContainer != activeContainer && ([[object chat] listObject]==[object source])){
        [self _increaseUnviewedContentOfListObject:[object source]];
    }
}

//Called when the user requests to initiate a message
- (void)initiateNewMessage
{
    //Display our new message prompt
    [AINewMessagePrompt newMessagePrompt];
}

//Open a container for the chat
- (void)openChat:(AIChat *)inChat
{
    AIMessageTabViewItem	*messageTabContainer = nil;
//    AIListObject		*listObject;
	
    //Check for an existing message container with this list object
 //   if(listObject = [inChat listObject]){
 //       messageTabContainer = [self _messageTabForListObject:listObject];
      //If one already exists, we want to use it for this new chat
//        if(messageTabContainer){
			//            [[messageTabContainer messageViewController] setChat:inChat];
			//
			//            //Honor any temporary preference override for window spawning
			//            if(forceIntoNewWindow || forceIntoTab){
			//                [self _transferMessageTabContainer:messageTabContainer toWindow:(forceIntoNewWindow ? nil : [self _primaryMessageWindow])];
			//            }
			
			//            [messageTabContainer makeActive:nil];
//        }
  //  }
#warning Evan: Potential problem: We now use the chat instead of the listobject to check for a unique tab.  Any problems?
	//Use the current message tab for this chat if one exists
	messageTabContainer = [self _messageTabForChat:inChat];
	
    //Create a tab for this chat
    if(!messageTabContainer){
		if(arrangeByGroup) {
			NSString *group;
			if( [inChat listObject] ) {
				group = [[[inChat listObject] containingGroup] uniqueObjectID];
			} else {
				group = @"Group Chats";
			}
			
			AIMessageWindowController		*groupController = [arrangeByGroupWindowList objectForKey:group];
			if( groupController ) {
				messageTabContainer = [self _createMessageTabForChat:inChat
										   inMessageWindowController:groupController];
			} else {
				messageTabContainer = [self _createMessageTabForChat:inChat inMessageWindowController:nil];
				
				NSEnumerator				*enumerator = [messageWindowControllerArray objectEnumerator];
				AIMessageWindowController   *controller;
				NSArray						*tabViewItemArray;
				while( controller = [enumerator nextObject] ) {
					tabViewItemArray = [controller messageContainerArray];
					if( [tabViewItemArray indexOfObject:messageTabContainer] != NSNotFound ) {
						[arrangeByGroupWindowList setObject:controller forKey:group];
						break;
					}
				}
				//[arrangeByGroupWindowList setObject:[messageTabContainer messageViewController] forKey:group];
			}
		}else if(forceIntoNewWindow || forceIntoTab){
            messageTabContainer = [self _createMessageTabForChat:inChat
									   inMessageWindowController:(forceIntoNewWindow ? nil : [self _primaryMessageWindow])];
        }else{
            messageTabContainer = [self _createMessageTabForChat:inChat];
        }
    }
	
    //Display the account selector if multiple accounts are available for sending to the contact
	[[messageTabContainer messageViewController] setAccountSelectionMenuVisible:YES];
	
    //Clear any temporary preference overriding
    forceIntoNewWindow = NO;
    forceIntoTab = NO;
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
    AIMessageWindowController 	*messageWindowController = nil;
	AIMessageWindowController   *groupWindowController = nil;
	NSString					*group;
	
    container = [self _messageTabForChat:inChat];
    if (container)
		messageWindowController = [self _messageWindowForContainer:container];
	
    if(messageWindowController){
        //Remove unviewed content for this contact
        [self _clearUnviewedContentOfChat:inChat];
		
        //Close it
        [messageWindowController removeTabViewItemContainer:container];
		
		//Clear the group sorting cache, if necessary
		if( arrangeByGroup ) {
			if( [inChat listObject] )
				group = [[[inChat listObject] containingGroup] uniqueObjectID];
			else
				group = @"Group Chats";
			
			groupWindowController = [arrangeByGroupWindowList objectForKey:group];
			if( [[groupWindowController customTabsView] numberOfTabViewItems] == 0 ) {
				[arrangeByGroupWindowList removeObjectForKey:group];
			}
		}
    }
}


//Menus ------------------------------------------------------------------------------
//Add our menu items
- (void)addMenuItems
{
    //Add the close menu item
    menuItem_close = [[NSMenuItem alloc] initWithTitle:CLOSE_MENU_TITLE
												target:self 
												action:@selector(close:)
										 keyEquivalent:@"w"];
    [[adium menuController] addMenuItem:menuItem_close toLocation:LOC_File_Close];
	
    //Add our close tab menu item
    menuItem_closeTab = [[NSMenuItem alloc] initWithTitle:CLOSE_TAB_MENU_TITLE
												   target:self 
												   action:@selector(closeTab:) 
											keyEquivalent:@""];
    [[adium menuController] addMenuItem:menuItem_closeTab toLocation:LOC_File_Close];
	
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
		
        menuItem_previousMessage = [[NSMenuItem alloc] initWithTitle:PREVIOUS_MESSAGE_MENU_TITLE
															  target:self 
															  action:@selector(previousMessage:)
													   keyEquivalent:leftKey];
        [[adium menuController] addMenuItem:menuItem_previousMessage toLocation:LOC_Window_Commands];
		
        menuItem_nextMessage = [[NSMenuItem alloc] initWithTitle:NEXT_MESSAGE_MENU_TITLE 
														  target:self
														  action:@selector(nextMessage:)
												   keyEquivalent:rightKey];
        [[adium menuController] addMenuItem:menuItem_nextMessage toLocation:LOC_Window_Commands];
		
		menuItem_arrangeTabs = [[NSMenuItem alloc] initWithTitle:ARRANGE_MENU_TITLE
														  target:self
														 action:@selector(arrangeTabs:)
												   keyEquivalent:@""];
		[[adium menuController] addMenuItem:menuItem_arrangeTabs toLocation:LOC_Window_Commands];
		
		if([NSApp isOnPantherOrBetter]){
			menuItem_arrangeTabs_alternate = [[NSMenuItem alloc] initWithTitle:ARRANGE_ALTERNATE_MENU_TITLE
																 target:self
																 action:@selector(arrangeTabs:)
														  keyEquivalent:@""];
			[menuItem_arrangeTabs_alternate setAlternate:YES];
			[menuItem_arrangeTabs_alternate setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
			[[adium menuController] addMenuItem:menuItem_arrangeTabs_alternate toLocation:LOC_Window_Commands];
		}			
        
		menuItem_splitByGroup = [[NSMenuItem alloc] initWithTitle:SPLIT_ALL_CHATS
														   target:self
														   action:@selector(arrangeTabsByGroup:)
													keyEquivalent:@""];
		[[adium menuController] addMenuItem:menuItem_splitByGroup toLocation:LOC_Window_Commands];
		
	}
	
    //Add contextual menu items
    menuItem_openInNewWindow = [[NSMenuItem alloc] initWithTitle:CHAT_IN_NEW_WINDOW 
														  target:self
														  action:@selector(openChatInNewWindow:) 
												   keyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:menuItem_openInNewWindow toLocation:Context_Contact_Additions];
    
    menuItem_openInPrimaryWindow = [[NSMenuItem alloc] initWithTitle:CHAT_IN_PRIMARY_WINDOW 
															  target:self 
															  action:@selector(openChatInPrimaryWindow:)
													   keyEquivalent:@""];
    [[adium menuController] addContextualMenuItem:menuItem_openInPrimaryWindow toLocation:Context_Contact_Additions];
    
    menuItem_consolidate = [[NSMenuItem alloc] initWithTitle:CONSOLIDATE_ALL_CHATS
													  target:self 
													  action:@selector(consolidateAllChats:)
											   keyEquivalent:@"O"];
    [[adium menuController] addMenuItem:menuItem_consolidate toLocation:LOC_Window_Commands];
    		
    menuItem_toggleTabBar = [[NSMenuItem alloc] initWithTitle:TOGGLE_TAB_BAR
													   target:nil 
													   action:@selector(toggleForceTabBarVisible:)
												keyEquivalent:@"\\"];
    [[adium menuController] addMenuItem:menuItem_toggleTabBar toLocation:LOC_Window_Commands];
	
}

//Build the contents of the 'window' menu
- (void)buildWindowMenu
{
    NSMenuItem					*item;
    AIMessageTabViewItem		*tabViewItem;
    NSEnumerator				*enumerator;
    NSEnumerator				*tabViewEnumerator;
    NSEnumerator				*windowEnumerator;
    AIMessageWindowController 	*messageWindowController;
    int							windowKey = 1;

    //Remove any existing menus
    enumerator = [windowMenuArray objectEnumerator];
    while((item = [enumerator nextObject])){
        [[adium menuController] removeMenuItem:item];
    }
    [windowMenuArray release]; windowMenuArray = [[NSMutableArray alloc] init];
	
    //Contact list window
    //Add toolbar Menu
    item = [[NSMenuItem alloc] initWithTitle:CONTACT_LIST_WINDOW_MENU_TITLE
									  target:self
									  action:@selector(toggleContactList:)
							   keyEquivalent:@"/"];
    [item setRepresentedObject:contactListWindowController];
    [[adium menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
    [windowMenuArray addObject:[item autorelease]];
    
    //Add dock Menu
    item = [[NSMenuItem alloc] initWithTitle:CONTACT_LIST_WINDOW_MENU_TITLE 
									  target:self 
									  action:@selector(showContactListAndBringToFront:) 
							   keyEquivalent:@""];
    [item setRepresentedObject:contactListWindowController];
    [[adium menuController] addMenuItem:item toLocation:LOC_Dock_Status];    
    [windowMenuArray addObject:[item autorelease]];
	
    //Messages window and any open messasges
    if([messageWindowControllerArray count])
    {
		//Add a 'Messages' menu item
		item = [[NSMenuItem alloc] initWithTitle:MESSAGES_WINDOW_MENU_TITLE
										  target:self
										  action:@selector(showMessageWindow:)
								   keyEquivalent:@""];
        [[adium menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
        [windowMenuArray addObject:[item autorelease]];
		
        //Add a 'Messages' menu item to the dock
        item = [[NSMenuItem alloc] initWithTitle:MESSAGES_WINDOW_MENU_TITLE
										  target:self 
										  action:@selector(showMessageWindow:)
								   keyEquivalent:@""];
        [[adium menuController] addMenuItem:item toLocation:LOC_Dock_Status];
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
					NSString		*tabViewItemTitle = [NSString stringWithFormat:@"   %@",[tabViewItem labelString]];
					
					//Prepare a key equivalent for the controller
					if(windowKey < 10){
						windowKeyString = [NSString stringWithFormat:@"%i",(windowKey)];
					}else if (windowKey == 10){
						windowKeyString = [NSString stringWithString:@"0"];
					}else{
						windowKeyString = [NSString stringWithString:@""];
					}
					
					//Create the menu item
					item = [[NSMenuItem alloc] initWithTitle:tabViewItemTitle
													  target:self 
													  action:@selector(showMessageWindow:) 
											   keyEquivalent:windowKeyString];
					[item setRepresentedObject:tabViewItem]; //associate this item with a tab
					
					//Add it to the menu and array
					[[adium menuController] addMenuItem:item toLocation:LOC_Window_Fixed];
                    [windowMenuArray addObject:[item autorelease]];
					
					
                    //Create the same menu item for the dock menu
                    item = [[NSMenuItem alloc] initWithTitle:tabViewItemTitle
													  target:self
													  action:@selector(showMessageWindow:)
											   keyEquivalent:@""];
                    [item setRepresentedObject:tabViewItem]; //associate this item with a tab
                    
                    [[adium menuController] addMenuItem:item toLocation:LOC_Dock_Status];
                    [windowMenuArray addObject:[item autorelease]];
					
					windowKey++;
				}
			}
		}
    }
	
    [self _updateActiveWindowMenuItem];
    [self _updateCloseMenuKeys];
}

//remove our menu items
- (void)removeMenuItems
{
    [[adium menuController] removeMenuItem:menuItem_closeTab];
    [[adium menuController] removeMenuItem:menuItem_nextMessage];
    [[adium menuController] removeMenuItem:menuItem_previousMessage];
}

//Updates the 'check' icon so it's next to the active window
- (void)_updateActiveWindowMenuItem
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

//Update the close window/close tab menu item keys

//evands Notes: NSDictionary using the tabview as the key with the message window as the object? We're having to go through this
//every time a container changes.

- (void)_updateCloseMenuKeys
{
    if([activeContainer isKindOfClass:[AIMessageTabViewItem class]] && 
	   [[[self _messageWindowForContainer:(AIMessageTabViewItem *)activeContainer] messageContainerArray] count] > 1){
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
}

//Validate a menu item
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    BOOL enabled = YES;

    if(menuItem == menuItem_closeTab){
        AIMessageWindowController *messageWindow = [self _messageWindowForContainer:(AIMessageTabViewItem *)activeContainer];
		
        enabled = (messageWindow && [[messageWindow messageContainerArray] count] > 1);
		
    }else if((menuItem == menuItem_nextMessage) ||
			 (menuItem == menuItem_previousMessage)){
        if(![messageWindowControllerArray count]) enabled = NO;
		
    }else if (menuItem == menuItem_openInNewWindow || menuItem == menuItem_openInPrimaryWindow){
		AIListObject *contactualMenuContact = [[adium menuController] contactualMenuContact];
		
		enabled = (contactualMenuContact && [contactualMenuContact isKindOfClass:[AIListContact class]]);
		
    }else if (menuItem == menuItem_consolidate){
		if(([messageWindowControllerArray count] <= 1) || arrangeByGroup) enabled = NO; //only with more than one window open
		
	}else if (menuItem == menuItem_splitByGroup){
        if(![messageWindowControllerArray count] || arrangeByGroup) enabled = NO;
		
    }else if (menuItem == menuItem_arrangeTabs || menuItem == menuItem_arrangeTabs_alternate){
        if(![messageWindowControllerArray count] || keepTabsArranged) enabled = NO;
	}
	
    return(enabled);
}


//Private ---------------------------------------------------------------------------
//Increase unviewed content
- (void)_increaseUnviewedContentOfListObject:(AIListObject *)inObject
{
	int			currentUnviewed = [inObject integerStatusObjectForKey:@"UnviewedContent"];
	
	//'UnviewedContent'++
	[inObject setStatusObject:[NSNumber numberWithInt:(currentUnviewed+1)] forKey:@"UnviewedContent" notify:YES];
}

//Clear unviewed content
- (void)_clearUnviewedContentOfChat:(AIChat *)inChat
{
    NSEnumerator	*enumerator;
    AIListObject	*listObject;
	
    //Clear the unviewed content of each list object participating in this chat
    enumerator = [[inChat participatingListObjects] objectEnumerator];
    while(listObject = [enumerator nextObject]){
		if([listObject integerStatusObjectForKey:@"UnviewedContent"]){
			[listObject setStatusObject:[NSNumber numberWithInt:0] forKey:@"UnviewedContent" notify:YES];
		}
    }
}

//Returns the existing messsage tab for the specified chat
- (AIMessageTabViewItem *)_messageTabForChat:(AIChat *)inChat
{
    NSEnumerator		*windowEnumerator;
    AIMessageWindowController 	*messageWindow;
    AIMessageTabViewItem	*tabViewItem = nil;
	
    windowEnumerator = [messageWindowControllerArray objectEnumerator];
    while(messageWindow = [windowEnumerator nextObject]){
        if(tabViewItem = (AIMessageTabViewItem *)[messageWindow containerForChat:inChat]) break;
    }
	
    return(tabViewItem);
}

//Returns the existing messsage tab for the specified list object
- (AIMessageTabViewItem *)_messageTabForListObject:(AIListObject *)inListObject
{
    NSEnumerator		*windowEnumerator;
    AIMessageWindowController 	*messageWindow;
    AIMessageTabViewItem	*tabViewItem = nil;
	
    windowEnumerator = [messageWindowControllerArray objectEnumerator];
    while(messageWindow = [windowEnumerator nextObject]){
        if(tabViewItem = (AIMessageTabViewItem *)[messageWindow containerForListObject:inListObject]) break;
    }
    return(tabViewItem);
}

//Create a tab for the chat, adding it to the correct window according to our preferences
- (AIMessageTabViewItem *)_createMessageTabForChat:(AIChat *)inChat
{
    AIMessageWindowController	*messageWindowController;
	
    if(![messageWindowControllerArray count] || alwaysCreateNewWindows){
        messageWindowController = nil;
    }else if(useLastWindow && lastUsedMessageWindow){
        messageWindowController = lastUsedMessageWindow;
    }else{
        messageWindowController = [messageWindowControllerArray objectAtIndex:0];
    }
	
    return([self _createMessageTabForChat:inChat inMessageWindowController:messageWindowController]);
}

//pass nil to create a new window for this tab; otherwise, put a tab containing inChat into the window controller by messageWindowController
- (AIMessageTabViewItem *)_createMessageTabForChat:(AIChat *)inChat inMessageWindowController:(AIMessageWindowController *)messageWindowController
{
    AIMessageTabViewItem	*messageTabContainer = nil;
    AIMessageViewController	*messageViewController;
	
    //Create the message window, view, and tab
    if(!messageWindowController){
        messageWindowController = [self _createMessageWindow];
    }
    
    messageViewController = [AIMessageViewController messageViewControllerForChat:inChat];
    messageTabContainer = [AIMessageTabViewItem messageTabWithView:messageViewController];
    
    //Add it to the message window & rebuild the window menu
    [messageWindowController addTabViewItemContainer:messageTabContainer];
	
    return(messageTabContainer);
}

//Transfers an existing chat to the specified message window
- (void)_transferMessageTabContainer:(AIMessageTabViewItem *)tabViewItem toWindow:(AIMessageWindowController *)newMessageWindow
{
    [self transferMessageTabContainer:tabViewItem toWindow:newMessageWindow atIndex:-1 withTabBarAtPoint:NSMakePoint(-1,-1)];
}


// #### MAKE SORTING HAPPEN ON STATUS CHANGES TOO!!! ####
// Use: ListObject_StatusChanged, Contact_OrderChanged
//Arrange tabs in some or all windows with the current sort options
- (IBAction)arrangeTabs:(id)sender
{
	if( sender == menuItem_arrangeTabs ) {
		
		if( lastUsedMessageWindow ){
			[lastUsedMessageWindow arrangeTabs];
		}		
		
	} else if( sender == menuItem_arrangeTabs_alternate ) {
		
		AIMessageWindowController   *controller;
		NSEnumerator				*enumerator = [messageWindowControllerArray objectEnumerator];

		while( controller = [enumerator nextObject] ) {
			[controller arrangeTabs];
		}
		
	}
}

- (IBAction)arrangeTabsByGroup:(id)sender
{
	
	NSMutableDictionary			*arrangeByGroupCache = [NSMutableDictionary dictionary];
	AIMessageWindowController   *controller;
	AIListObject				*listObject;
	NSEnumerator				*controllerEnumerator = [messageWindowControllerArray objectEnumerator];
	NSEnumerator				*tabCellEnumerator;
	NSEnumerator				*dictionaryEnumerator;
	NSEnumerator				*arrayEnumerator;
	AICustomTabCell				*tabCell;
	AIMessageTabViewItem		*tabViewItem;
	NSString					*listGroupID;
	NSMutableArray				*splitArray;
	BOOL						shouldSplit = NO;
	
	// First build our cache of (group, {AIMessageTabViewItem, AIMessageWindowController}) data
	// Run through all message windows
	
	while( controller = [controllerEnumerator nextObject] ) {
		
		// Run through each tab cell and get its tabViewItem and group
		tabCellEnumerator = [[[controller customTabsView] tabCells] objectEnumerator];
		while( tabCell = [tabCellEnumerator nextObject] ) {
			tabViewItem = (AIMessageTabViewItem *)[tabCell tabViewItem];
			listObject = [[[tabViewItem messageViewController] chat] listObject];
			
			// Group chats don't have list objects
			if( listObject ) {
				listGroupID = [[listObject containingGroup] uniqueObjectID];
			} else {
				listGroupID = @"Group Chats";
			}
			// Is there an array for this group yet?
			if( splitArray = [arrangeByGroupCache objectForKey:listGroupID]) {
				
				// Add this (tabViewItem, controller) pair to the existing group array
				[splitArray addObject:[NSArray arrayWithObjects:tabViewItem, controller, nil]];
				
				// If the previous controller is different from this controller, we MUST split the tabs into separate windows				
				if( [[splitArray objectAtIndex:([splitArray count]-2)] objectAtIndex:1] != controller ) {
					shouldSplit = YES;
				}
			} else {
				// Create a mutable array for this group
				[arrangeByGroupCache setObject:[NSMutableArray arrayWithObject:[NSArray arrayWithObjects:tabViewItem, controller, nil]] forKey:listGroupID];
			}
			
		}
		
	}
		
	arrangeByGroupWindowList = [[NSMutableDictionary alloc] init];
	NSArray *tempArray;
	dictionaryEnumerator = [arrangeByGroupCache objectEnumerator];
	
	// Pre-process the controller list to use as many existing windows as possible
	// This should be made smarter in the future
	while( splitArray = [dictionaryEnumerator nextObject] ) {
		tempArray = [splitArray objectAtIndex:0];
		if( [[arrangeByGroupWindowList allValues] indexOfObject:[tempArray objectAtIndex:1]] == NSNotFound )
			[arrangeByGroupWindowList
				setObject:[tempArray objectAtIndex:1]
				   forKey:[[[[[[tempArray objectAtIndex:0] messageViewController] chat] listObject] containingGroup] uniqueObjectID]];
		
	}
	
	dictionaryEnumerator = [arrangeByGroupCache objectEnumerator];
	
	// If we split into more than one group or groups are spread among multiple windows, create the windows with the appropriate tabs
	if( shouldSplit || ([arrangeByGroupCache count] > [messageWindowControllerArray count]) ) {
				
		while( splitArray = [dictionaryEnumerator nextObject] ) {
			
			arrayEnumerator = [splitArray objectEnumerator];
			tabViewItem = [[arrayEnumerator nextObject] objectAtIndex:0];
			listGroupID = [[[[[tabViewItem messageViewController] chat] listObject] containingGroup] uniqueObjectID];

			// This MAY return nil, but that's ok: it means we need to open in a new window anyhow
			controller = [arrangeByGroupWindowList objectForKey:listGroupID];
			[self _transferMessageTabContainer:tabViewItem toWindow:controller];

			if( controller == nil ) {
				controller = [self _messageWindowForContainer:tabViewItem];
				[arrangeByGroupWindowList
				setObject:controller
				   forKey:[[[[[tabViewItem messageViewController] chat] listObject] containingGroup] uniqueObjectID]];				
			}
			
			while( tempArray = [arrayEnumerator nextObject] ) {
				tabViewItem = [tempArray objectAtIndex:0];
				[self _transferMessageTabContainer:tabViewItem toWindow:controller];
			}
		}
		
	// We still want the window list
	} else {
				
		while( splitArray = [dictionaryEnumerator nextObject] ) {
			
			tempArray = [splitArray objectAtIndex:0];
			
			[arrangeByGroupWindowList
				setObject:[tempArray objectAtIndex:1]
				   forKey:[[[[[[tempArray objectAtIndex:0] messageViewController] chat] listObject] containingGroup] uniqueObjectID]];
			}
		
	}

}

//Returns the message window containing only tabs from 'group', or a new one if there was none previously.
- (AIMessageWindowController *)_messageWindowForGroup:(AIListGroup *)group
{
	return nil;
}


//Returns the message window housing the specified container
- (AIMessageWindowController *)_messageWindowForContainer:(AIMessageTabViewItem *)container
{
    NSEnumerator				*windowEnumerator = [messageWindowControllerArray objectEnumerator];
    AIMessageWindowController 	*messageWindowController = nil;
	
    while(messageWindowController = [windowEnumerator nextObject]){
        if([messageWindowController containsMessageContainer:container]) break;
    }
	
    return(messageWindowController);
}

//Returns the 'primary' message window.  Returns nil if no message windows are present
- (AIMessageWindowController *)_primaryMessageWindow
{
    if([messageWindowControllerArray count] != 0){ //Use our first message window as the primary
        return([messageWindowControllerArray objectAtIndex:0]);
    }else{
        return(nil);
    }
}

//Create a new message window
- (AIMessageWindowController *)_createMessageWindow
{    
    AIMessageWindowController	*messageWindowController = [AIMessageWindowController messageWindowControllerForInterface:self];
    
    //Register to be notified when this message window closes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageWindowWillClose:) 
                                                 name:NSWindowWillCloseNotification 
                                               object:[messageWindowController window]];
    
    //Add the messageWindowController to our array
    [messageWindowControllerArray addObject:messageWindowController];
        
    return(messageWindowController);
}

//Destroy a message window
- (void)_destroyMessageWindow:(AIMessageWindowController *)inWindow
{
    //Cler the lastUsedMessageWindow tracking variable if necessary
    if (lastUsedMessageWindow==inWindow)
        lastUsedMessageWindow = nil;
    
    //Stop observing the message window
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:inWindow];
	
    //Remove window from our array
    [messageWindowControllerArray removeObject:inWindow];
}

@end



