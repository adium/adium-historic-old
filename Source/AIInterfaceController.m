/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

// $Id$

#import "AIContactController.h"
#import "AIChatController.h"
#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "AIMenuController.h"
#import "AIPreferenceController.h"
#import "AIStandardListWindowController.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIFontAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITooltipUtilities.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AISortController.h>
#import <Adium/KFTypeSelectTableView.h>


#define CLOSE_CHAT_MENU_TITLE			AILocalizedString(@"Close Chat","Title for the close chat menu item")
#define CLOSE_MENU_TITLE				AILocalizedString(@"Close","Title for the close menu item")
#define CLOSE_ALL_TABS_MENU_TITLE		AILocalizedString(@"Close All Chats","Title for the close all chats menu item")

#define ERROR_MESSAGE_WINDOW_TITLE		AILocalizedString(@"Adium : Error","Error message window title")
#define LABEL_ENTRY_SPACING				4.0
#define DISPLAY_IMAGE_ON_RIGHT			NO

#define PREF_GROUP_FORMATTING			@"Formatting"
#define KEY_FORMATTING_FONT				@"Default Font"

#define MESSAGES_WINDOW_MENU_TITLE		AILocalizedString(@"Messages","Title for the messages window menu item")

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/Plugins/"	//Path to the internal plugins
#define DIRECTORY_EXTERNAL_PLUGINS		@"/Plugins"				//Path to the external plugins
#define EXTENSION_ADIUM_PLUGIN			@"AdiumPlugin"			//File extension of a plugin

#define WEBKIT_PLUGIN					@"Webkit Message View.AdiumPlugin"
#define SMV_PLUGIN						@"Standard Message View.AdiumPlugin"

@interface AIInterfaceController (PRIVATE)
- (void)_resetOpenChatsCache;
- (void)_addItemToMainMenuAndDock:(NSMenuItem *)item;
- (NSAttributedString *)_tooltipTitleForObject:(AIListObject *)object;
- (NSAttributedString *)_tooltipBodyForObject:(AIListObject *)object;
- (void)_pasteWithPreferredSelector:(SEL)preferredSelector sender:(id)sender;

- (AIChat *)mostRecentActiveChat;
@end

/*!
 * @class AIInterfaceController
 * @brief Interface controller
 *
 * Chat window related requests, such as opening and closing chats, are routed through the interface controller
 * to the appropriate component. The interface controller keeps track of the most recently active chat, handles chat
 * cycling (switching between chats), chat sorting, and so on.  The interface controller also handles switching to
 * an appropriate window or chat when the dock icon is clicked for a 'reopen' event.
 *
 * Contact list window requests, such as toggling window visibilty are routed to the contact list controller component.
 *
 * Error messages are routed through the interface controller.
 *
 * Tooltips, such as seen on hover in the contact list are generated and displayed here.  Tooltip display components and
 * plugins register with the interface controller to be queried for contact information when a tooltip is displayed.
 *
 * When displays in Adium flash, such as in the dock or the contact list for unviewed content, the interface controller
 * manages keeping the flashing synchronized.
 *
 * Finally, the interface controller manages many menu items, providing better menu item validation and target routing
 * than the responder chain alone would do.
 */
@implementation AIInterfaceController

- (id)init
{
	if ((self = [super init])) {
		/* Use KFTypeSelectTableView as our NSTableView base class to allow type-select searching of all
		* table and outline views throughout Adium.
		*/
		[[KFTypeSelectTableView class] poseAsClass:[NSTableView class]];
		
		contactListViewArray = [[NSMutableArray alloc] init];
		messageViewArray = [[NSMutableArray alloc] init];
		contactListTooltipEntryArray = [[NSMutableArray alloc] init];
		contactListTooltipSecondaryEntryArray = [[NSMutableArray alloc] init];
		closeMenuConfiguredForChat = NO;
		_cachedOpenChats = nil;
		mostRecentActiveChat = nil;
		activeChat = nil;
		
		tooltipListObject = nil;
		tooltipTitle = nil;
		tooltipBody = nil;
		tooltipImage = nil;
		flashObserverArray = nil;
		flashTimer = nil;
		flashState = 0;
		
		windowMenuArray = nil;
	}
	
	return self;
}

#if 0
//Can be called by a timer to periodically log the responder chain
//[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(reportResponderChain:) userInfo:nil repeats:YES];
- (void)reportResponderChain:(NSTimer *)inTimer
{
	NSMutableString	*responderChain = [NSMutableString string];
	
	NSWindow	*keyWindow = [[NSApplication sharedApplication] keyWindow];
	[responderChain appendFormat:@"%@ (%i): ",keyWindow,[keyWindow respondsToSelector:@selector(print:)]];
	
	NSResponder	*responder = [keyWindow firstResponder];
	
	//First, walk down the responder chain looking for a responder which can handle the preferred selector
	while (responder) {
		[responderChain appendFormat:@"%@ (%i)",responder,[responder respondsToSelector:@selector(print:)]];
		responder = [responder nextResponder];
		if (responder) [responderChain appendString:@" -> "];
	}

	NSLog(responderChain);
}
#endif

- (void)controllerDidLoad
{
    //Load the interface
    [interfacePlugin openInterface];

    //Configure our dynamic paste menu item
    [menuItem_paste setDynamic:YES];
    [menuItem_pasteFormatted setDynamic:YES];

	//Open the contact list window
    [self showContactList:nil];

	//Contact list menu tem
    NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:CONTACT_LIST_TITLE
																				target:self
																				action:@selector(toggleContactList:)
																		 keyEquivalent:@"/"];
	[menuController addMenuItem:menuItem toLocation:LOC_Window_Fixed];
	[menuController addMenuItem:[[menuItem copy] autorelease] toLocation:LOC_Dock_Status];
	[menuItem release];

	//Observe preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_INTERFACE];

    //Observe content so we can open chats as necessary
    [[adium notificationCenter] addObserver:self selector:@selector(didReceiveContent:) 
									   name:CONTENT_MESSAGE_RECEIVED object:nil];
}

- (void)controllerWillClose
{
    [contactListPlugin closeContactList];
    [interfacePlugin closeInterface];
}

// Dealloc
- (void)dealloc
{
    [contactListViewArray release]; contactListViewArray = nil;
    [messageViewArray release]; messageViewArray = nil;
    [interfaceArray release]; interfaceArray = nil;
	
    [tooltipListObject release]; tooltipListObject = nil;
	[tooltipTitle release]; tooltipTitle = nil;
	[tooltipBody release]; tooltipBody = nil;
	[tooltipImage release]; tooltipImage = nil;
	
	[[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
    [super dealloc];
}

//Registers code to handle the interface
- (void)registerInterfaceController:(id <AIInterfaceController>)inController
{
	if (!interfacePlugin) interfacePlugin = [inController retain];
}

//Register code to handle the contact list
- (void)registerContactListController:(id <AIContactListController>)inController
{
	if (!contactListPlugin) contactListPlugin = [inController retain];
}

//Preferences changed
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//
	[[adium notificationCenter] removeObserver:self name:Contact_OrderChanged object:nil];
	
	//Update prefs
	tabbedChatting = [[prefDict objectForKey:KEY_TABBED_CHATTING] boolValue];
	groupChatsByContactGroup = [[prefDict objectForKey:KEY_GROUP_CHATS_BY_GROUP] boolValue];
}

//Handle a reopen/dock icon click
- (BOOL)handleReopenWithVisibleWindows:(BOOL)visibleWindows
{
    //The 'visibleWindows' variable passed by the system is unreliable, since the presence
    //of the Adium system menu will cause it to always be YES.  We won't use it below.

	//If no windows are visible, show the contact list
	if (![contactListPlugin contactListIsVisibleAndMain] && [[interfacePlugin openContainers] count] == 0) {
		[self showContactList:nil];
	} else {
		AIChat	*mostRecentUnviewedChat;

		//If windows are open, try switching to a chat with unviewed content
		if ((mostRecentUnviewedChat = [[adium chatController] mostRecentUnviewedChat])) {
			//If the most recently active chat has unviewed content, don't switch away from it
			if (![[self mostRecentActiveChat] unviewedContentCount]) {
				[self setActiveChat:mostRecentUnviewedChat];
			}

		} else {
			NSEnumerator    *enumerator;
			NSWindow	    *window, *targetWindow = nil;
			BOOL	    	unMinimizedWindows = 0;
			
			//If there was no unviewed content, ensure that atleast one of Adium's windows is unminimized
			enumerator = [[NSApp windows] objectEnumerator];
			while ((window = [enumerator nextObject])) {
				//Check stylemask to rule out the system menu's window (Which reports itself as visible like a real window)
				if (([window styleMask] & (NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask))) {
					if (!targetWindow) targetWindow = window;
					if (![window isMiniaturized]) unMinimizedWindows++;
				}
			}
			
			//If there are no unminimized windows, unminimize the last one
			if (unMinimizedWindows == 0 && targetWindow) {
				[targetWindow deminiaturize:nil];
			}
		}
	}
	
	//We handled the reopen; return NO so NSApp does nothing.
    return NO; 
}

//Contact List ---------------------------------------------------------------------------------------------------------
#pragma mark Contact list
//Toggle the contact list
- (IBAction)toggleContactList:(id)sender
{
    if ([contactListPlugin contactListIsVisibleAndMain]) {
		[self closeContactList:nil];
    } else {
		[self showContactList:nil];
    } 
}

//Show the contact list window
- (IBAction)showContactList:(id)sender
{
	[contactListPlugin showContactListAndBringToFront:YES];
}

//Show the contact list window and bring Adium to the front
- (IBAction)showContactListAndBringToFront:(id)sender
{
	[contactListPlugin showContactListAndBringToFront:YES];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

//Close the contact list window
- (IBAction)closeContactList:(id)sender
{
	[contactListPlugin closeContactList];
}


//Messaging ------------------------------------------------------------------------------------------------------------
//Methods for instructing the interface to provide a representation of chats, and to determine which chat has user focus
#pragma mark Messaging
//Open a window for the chat
- (void)openChat:(AIChat *)inChat
{
	NSArray		*containers = [interfacePlugin openContainersAndChats];
	NSString	*containerID = nil;
	
	//Determine the correct container for this chat
	if (groupChatsByContactGroup) {
		AIListObject	*group = [[[inChat listObject] parentContact] containingObject];

		//If the contact is in the contact list root, we don't have a group
		if (group && (group != [[adium contactController] contactList])) {
			containerID = [group displayName];
		}
	} 
	
	//XXX - Temporary setup for multiple windows
	if (!tabbedChatting) {
		if ([inChat listObject]) {
			containerID = [[inChat listObject] internalObjectID];
		} else {
			containerID = [inChat name];
		}
	}
	
	if (!containerID) {
		//Open new chats into the first container (if not available, create a new one)
		if ([containers count] > 0) {
			containerID = [[containers objectAtIndex:0] objectForKey:@"ID"];
		} else {
			containerID = AILocalizedString(@"Messages",nil);
		}
	}

	//Determine the correct placement for this chat within the container
	[interfacePlugin openChat:inChat inContainerWithID:containerID atIndex:-1];
	if (![inChat isOpen]) {
		[inChat setIsOpen:YES];
		
		//Post the notification last, so observers receive a chat whose isOpen flag is yes.
		[[adium notificationCenter] postNotificationName:Chat_DidOpen object:inChat userInfo:nil];
	}
}

/*
 * @brief Close the interface for a chat
 *
 * Tell the interface plugin to close the chat.
 */
- (void)closeChat:(AIChat *)inChat
{
    [interfacePlugin closeChat:inChat];
}

//Consolidate chats into a single container
- (void)consolidateChats
{
	//We work with copies of these arrays, since moving chats may change their contents
	NSArray			*openContainers = [[interfacePlugin openContainers] copy];
	NSEnumerator	*containerEnumerator = [openContainers objectEnumerator];
	NSString		*firstContainerID = [containerEnumerator nextObject];
	NSString		*containerID;
	
	//For all containers but the first, move the chats they contain to the first container
	while ((containerID = [containerEnumerator nextObject])) {
		NSArray			*openChats = [[interfacePlugin openChatsInContainerWithID:containerID] copy];
		NSEnumerator	*chatEnumerator = [openChats objectEnumerator];
		AIChat			*chat;

		//Move all the chats, providing a target index if chat sorting is enabled
		while ((chat = [chatEnumerator nextObject])) {
			[interfacePlugin moveChat:chat
					toContainerWithID:firstContainerID
								index:-1];
		}
		
		[openChats release];
	}
	
	[self chatOrderDidChange];
	
	[openContainers release];
}

//Active chat
- (AIChat *)activeChat
{
	return activeChat;
}
//Set the active chat window
- (void)setActiveChat:(AIChat *)inChat
{
	[interfacePlugin setActiveChat:inChat];
}
//Last chat to be active (should only be nil if no chats are open)
- (AIChat *)mostRecentActiveChat
{
	return mostRecentActiveChat;
}
//Solely for key-value pairing purposes
- (void)setMostRecentActiveChat:(AIChat *)inChat
{
	[self setActiveChat:inChat];
}

//Returns an array of open chats (cached, so call as frequently as desired)
- (NSArray *)openChats
{
	if (!_cachedOpenChats) {
		_cachedOpenChats = [[interfacePlugin openChats] retain];
	}
	
	return _cachedOpenChats;
}

//
- (NSArray *)openChatsInContainerWithID:(NSString *)containerID
{
	return [interfacePlugin openChatsInContainerWithID:containerID];
}

//Resets the cache of open chats
- (void)_resetOpenChatsCache
{
	[_cachedOpenChats release]; _cachedOpenChats = nil;
}



//Interface plugin callbacks -------------------------------------------------------------------------------------------
//These methods are called by the interface to let us know what's going on.  We're informed of chats opening, closing,
//changing order, etc.
#pragma mark Interface plugin callbacks
//A chat window did open: rebuild our window menu to show the new chat
- (void)chatDidOpen:(AIChat *)inChat
{
	[self _resetOpenChatsCache];
	[self buildWindowMenu];
}

//A chat has become active: update our chat closing keys and flag this chat as selected in the window menu
- (void)chatDidBecomeActive:(AIChat *)inChat
{
	[activeChat release]; activeChat = [inChat retain];
	[self updateCloseMenuKeys];
	[self updateActiveWindowMenuItem];
	
	[mostRecentActiveChat release]; mostRecentActiveChat = nil;
	if (inChat) {
		mostRecentActiveChat = [inChat retain];

		/* Clear the unviewed content on the next event loop so other methods have a chance to react to the chat becoming
		* active. Specifically, this lets the handleReopenWithVisibleWindows: method have a chance to know that this chat
		* had unviewed content.
		*/
		[inChat performSelector:@selector(clearUnviewedContentCount)
					 withObject:nil
				   afterDelay:0];
	}		
}

//A chat has become visible: send out a notification for components and plugins to take action
- (void)chatDidBecomeVisible:(AIChat *)inChat inWindow:(NSWindow *)inWindow
{
	[[adium notificationCenter] postNotificationName:@"AIChatDidBecomeVisible"
											  object:inChat
											userInfo:[NSDictionary dictionaryWithObject:inWindow
																				 forKey:@"NSWindow"]];
}

/*
 * @brief Find the window currently displaying a chat
 *
 * If the chat is not in any window, or is not visible in any window, returns nil
 */
- (NSWindow *)windowForChat:(AIChat *)inChat
{
	return [interfacePlugin windowForChat:inChat];
}

//A chat window did close: rebuild our window menu to remove the chat
- (void)chatDidClose:(AIChat *)inChat
{
	[self _resetOpenChatsCache];
	[inChat clearUnviewedContentCount];
	[self buildWindowMenu];
	
	if (inChat == activeChat) {
		[activeChat release]; activeChat = nil;
	}
	
	if (inChat == mostRecentActiveChat) {
		[mostRecentActiveChat release]; mostRecentActiveChat = nil;
	}
}

//The order of chats has changed: rebuild our window menu to reflect the new order
- (void)chatOrderDidChange
{
	[self _resetOpenChatsCache];
	[self buildWindowMenu];
}

#pragma mark Unviewed content

//Content was received, increase the unviewed content count of the chat (if it's not currently active)
- (void)didReceiveContent:(NSNotification *)notification
{
	AIChat		*chat = [[notification userInfo] objectForKey:@"AIChat"];
	
	if (chat != activeChat) {
		[chat incrementUnviewedContentCount];
	}
}


//Chat close menus -----------------------------------------------------------------------------------------------------
#pragma mark Chat close menus
//Close the active window
- (IBAction)closeMenu:(id)sender
{
    [[[NSApplication sharedApplication] keyWindow] performClose:nil];
}

//Close the active chat
- (IBAction)closeChatMenu:(id)sender
{
	if (activeChat) [self closeChat:activeChat];
}

//Loop through open chats and close them
- (IBAction)closeAllChats:(id)sender
{
	NSEnumerator	*containerEnumerator = [[[[interfacePlugin openChats] copy] autorelease] objectEnumerator];
	AIChat			*chatToClose;

	while ((chatToClose = [containerEnumerator nextObject])) {
		[self closeChat:chatToClose];
	}
}

//Updates the key equivalents on 'close' and 'close chat' (dynamically changed to make cmd-w less destructive)
- (void)updateCloseMenuKeys
{
	if (activeChat && !closeMenuConfiguredForChat) {
        [menuItem_close setKeyEquivalent:@"W"];
        [menuItem_closeChat setKeyEquivalent:@"w"];
		closeMenuConfiguredForChat = YES;
	} else if (!activeChat && closeMenuConfiguredForChat) {
        [menuItem_close setKeyEquivalent:@"w"];
		[menuItem_closeChat removeKeyEquivalent];		
		closeMenuConfiguredForChat = NO;
	}
}


//Window Menu ----------------------------------------------------------------------------------------------------------
#pragma mark Window Menu
//Make a chat window active (Invoked by a selection in the window menu)
- (IBAction)showChatWindow:(id)sender
{
	[self setActiveChat:[sender representedObject]];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

//Updates the 'check' icon so it's next to the active window
- (void)updateActiveWindowMenuItem
{
    NSEnumerator	*enumerator = [windowMenuArray objectEnumerator];
    NSMenuItem		*item;

    while ((item = [enumerator nextObject])) {
		if ([item representedObject]) [item setState:([item representedObject] == activeChat ? NSOnState : NSOffState)];
    }
}

//Builds the window menu
//This function gets called whenever chats are opened, closed, or re-ordered - so improvements and optimizations here
//would probably be helpful
- (void)buildWindowMenu
{	
    NSMenuItem				*item;
    NSEnumerator			*enumerator;
    int						windowKey = 1;
	BOOL					respondsToSetIndentationLevel = [menuItem_paste respondsToSelector:@selector(setIndentationLevel:)];
	
    //Remove any existing menus
    enumerator = [windowMenuArray objectEnumerator];
    while ((item = [enumerator nextObject])) {
        [menuController removeMenuItem:item];
    }
    [windowMenuArray release]; windowMenuArray = [[NSMutableArray alloc] init];
	
    //Messages window and any open messasges
	NSEnumerator	*containerEnumerator = [[interfacePlugin openContainersAndChats] objectEnumerator];
	NSDictionary	*containerDict;
	
	while ((containerDict = [containerEnumerator nextObject])) {
		NSString		*containerName = [containerDict objectForKey:@"Name"];
		NSArray			*contentArray = [containerDict objectForKey:@"Content"];
		NSEnumerator	*contentEnumerator = [contentArray objectEnumerator];
		AIChat			*chat;
		
		//Add a menu item for the container
		if ([contentArray count] > 1) {
			item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:containerName
																		target:nil
																		action:nil
																 keyEquivalent:@""];
			[self _addItemToMainMenuAndDock:item];
			[item release];
		}
		
		//Add items for the chats it contains
		while ((chat = [contentEnumerator nextObject])) {
			NSString		*windowKeyString;
			
			//Prepare a key equivalent for the controller
			if (windowKey < 10) {
				windowKeyString = [NSString stringWithFormat:@"%i",(windowKey)];
			} else if (windowKey == 10) {
				windowKeyString = [NSString stringWithString:@"0"];
			} else {
				windowKeyString = [NSString stringWithString:@""];
			}
			
			item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[chat displayName]
																		target:self
																		action:@selector(showChatWindow:)
																 keyEquivalent:windowKeyString];
			if ([contentArray count] > 1 && respondsToSetIndentationLevel) [item setIndentationLevel:1];
			[item setRepresentedObject:chat];
			[item setImage:[chat chatMenuImage]];
			[self _addItemToMainMenuAndDock:item];
			[item release];

			windowKey++;
		}
	}

	[self updateActiveWindowMenuItem];
}

//Adds a menu item to the internal array, dock menu, and main menu
- (void)_addItemToMainMenuAndDock:(NSMenuItem *)item
{
	//Add to main menu first
	[menuController addMenuItem:item toLocation:LOC_Window_Fixed];
	[windowMenuArray addObject:item];
	
	//Make a copy, and add to the dock
	item = [item copy];
	[item setKeyEquivalent:@""];
	[menuController addMenuItem:item toLocation:LOC_Dock_Status];
	[windowMenuArray addObject:item];
	[item release];
}


//Chat Cycling ---------------------------------------------------------------------------------------------------------
#pragma mark Chat Cycling
//Select the next message
- (IBAction)nextMessage:(id)sender
{
	NSArray	*openChats = [self openChats];

	if ([openChats count]) {
		if (activeChat) {
			int chatIndex = [openChats indexOfObject:activeChat]+1;
			[self setActiveChat:[openChats objectAtIndex:(chatIndex < [openChats count] ? chatIndex : 0)]];
		} else {
			[self setActiveChat:[openChats objectAtIndex:0]];
		}
	}
}

//Select the previous message
- (IBAction)previousMessage:(id)sender
{
	NSArray	*openChats = [self openChats];
	
	if ([openChats count]) {
		if (activeChat) {
			int chatIndex = [openChats indexOfObject:activeChat]-1;
			[self setActiveChat:[openChats objectAtIndex:(chatIndex >= 0 ? chatIndex : [openChats count]-1)]];
		} else {
			[self setActiveChat:[openChats lastObject]];
		}
	}
}


//Message View ---------------------------------------------------------------------------------------------------------
//Message view is abstracted from the containing interface, since they're not directly related to eachother
#pragma mark Message View
//Registers a view to handle the contact list
- (void)registerMessageViewPlugin:(id <AIMessageViewPlugin>)inPlugin
{
    [messageViewArray addObject:inPlugin];
}
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
	//Sometimes our users find it amusing to disable plugins that are located within the Adium bundle.  This error
	//trap prevents us from crashing if they happen to disable all the available message view plugins.
	//PUT THAT PLUGIN BACK IT WAS IMPORTANT!
	if ([messageViewArray count] == 0) {
		NSRunCriticalAlertPanel(@"No Message View Plugin Installed",
								@"Adium cannot find its message view plugin, please re-install.  If you've manually disabled Adium's message view plugin, please re-enable it.",
								@"Quit",
								nil,
								nil);
		[NSApp terminate:nil];
	}
	
	return [[messageViewArray objectAtIndex:0] messageViewControllerForChat:inChat];
}


//Error Display --------------------------------------------------------------------------------------------------------
#pragma mark Error Display
- (void)handleErrorMessage:(NSString *)inTitle withDescription:(NSString *)inDesc
{
    [self handleMessage:inTitle withDescription:inDesc withWindowTitle:ERROR_MESSAGE_WINDOW_TITLE];
}

- (void)handleMessage:(NSString *)inTitle withDescription:(NSString *)inDesc withWindowTitle:(NSString *)inWindowTitle;
{
    NSDictionary	*errorDict;
    
    //Post a notification that an error was recieved
    errorDict = [NSDictionary dictionaryWithObjectsAndKeys:inTitle,@"Title",inDesc,@"Description",inWindowTitle,@"Window Title",nil];
    [[adium notificationCenter] postNotificationName:Interface_ShouldDisplayErrorMessage object:nil userInfo:errorDict];
}


//Synchronized Flashing ------------------------------------------------------------------------------------------------
#pragma mark Synchronized Flashing
//Register to observe the synchronized flashing
- (void)registerFlashObserver:(id <AIFlashObserver>)inObserver
{
    //Setup the timer if we don't have one yet
    if (!flashObserverArray) {
        flashObserverArray = [[NSMutableArray alloc] init];
        flashTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/2.0) 
                                                       target:self 
                                                     selector:@selector(flashTimer:) 
                                                     userInfo:nil
                                                      repeats:YES] retain];
    }
    
    //Add the new observer to the array
    [flashObserverArray addObject:inObserver];
}

//Unregister from observing flashing
- (void)unregisterFlashObserver:(id <AIFlashObserver>)inObserver
{
    //Remove the observer from our array
    [flashObserverArray removeObject:inObserver];
    
    //Release the observer array and uninstall the timer
    if ([flashObserverArray count] == 0) {
        [flashObserverArray release]; flashObserverArray = nil;
        [flashTimer invalidate];
        [flashTimer release]; flashTimer = nil;
    }
}

//Timer, invoke a flash
- (void)flashTimer:(NSTimer *)inTimer
{
    NSEnumerator	*enumerator;
    id<AIFlashObserver>	observer;
    
    flashState++;
    
    enumerator = [flashObserverArray objectEnumerator];
    while ((observer = [enumerator nextObject])) {
        [observer flash:flashState];
    }
}

//Current state of flashing.  This is an integer the increases by 1 with every flash.  Mod to whatever range is desired
- (int)flashState
{
    return flashState;
}


//Tooltips -------------------------------------------------------------------------------------------------------------
#pragma mark Tooltips
//Registers code to display tooltip info about a contact
- (void)registerContactListTooltipEntry:(id <AIContactListTooltipEntry>)inEntry secondaryEntry:(BOOL)isSecondary
{
    if (isSecondary)
        [contactListTooltipSecondaryEntryArray addObject:inEntry];
    else
        [contactListTooltipEntryArray addObject:inEntry];
}

//list object tooltips
- (void)showTooltipForListObject:(AIListObject *)object atScreenPoint:(NSPoint)point onWindow:(NSWindow *)inWindow 
{
    if (object) {
        if (object == tooltipListObject) { //If we already have this tooltip open
                                         //Move the existing tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle
												body:tooltipBody
											   image:tooltipImage 
										imageOnRight:DISPLAY_IMAGE_ON_RIGHT 
											onWindow:inWindow
											 atPoint:point 
										 orientation:TooltipBelow];
            
        } else { //This is a new tooltip
            NSArray                     *tabArray;
            NSMutableParagraphStyle     *paragraphStyleTitle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            NSMutableParagraphStyle     *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
            
            //Hold onto the new object
            [tooltipListObject release]; tooltipListObject = [object retain];
            
            //Buddy Icon
            [tooltipImage release];
			tooltipImage = [[tooltipListObject userIcon] retain];
			if (!tooltipImage) tooltipImage = [[AIServiceIcons serviceIconForObject:tooltipListObject
																			 type:AIServiceIconLarge
																		direction:AIIconNormal] retain];
            
            //Reset the maxLabelWidth for the tooltip generation
            maxLabelWidth = 0;
            
            //Build a tooltip string for the primary information
            [tooltipTitle release]; tooltipTitle = [[self _tooltipTitleForObject:object] retain];
            
            //If there is an image, set the title tab and indentation settings independently
            if (tooltipImage) {
                //Set a right-align tab at the maximum label width and a left-align just past it
                tabArray = [[NSArray alloc] initWithObjects:[[[NSTextTab alloc] initWithType:NSRightTabStopType 
																					location:maxLabelWidth] autorelease]
                                                            ,[[[NSTextTab alloc] initWithType:NSLeftTabStopType 
                                                                                   location:maxLabelWidth + LABEL_ENTRY_SPACING] autorelease]
                                                            ,nil];
                
                [paragraphStyleTitle setTabStops:tabArray];
                [tabArray release];
                tabArray = nil;
                [paragraphStyleTitle setHeadIndent:(maxLabelWidth + LABEL_ENTRY_SPACING)];
                
                [tooltipTitle addAttribute:NSParagraphStyleAttributeName 
                                     value:paragraphStyleTitle
                                     range:NSMakeRange(0,[tooltipTitle length])];
                
                //Reset the max label width since the body will be independent
                maxLabelWidth = 0;
            }
            
            //Build a tooltip string for the secondary information
            [tooltipBody release]; tooltipBody = nil;
            tooltipBody = [[self _tooltipBodyForObject:object] retain];
            
            //Set a right-align tab at the maximum label width for the body and a left-align just past it
            tabArray = [[NSArray alloc] initWithObjects:[[[NSTextTab alloc] initWithType:NSRightTabStopType 
                                                                                 location:maxLabelWidth] autorelease]
                                                        ,[[[NSTextTab alloc] initWithType:NSLeftTabStopType 
                                                                                location:maxLabelWidth + LABEL_ENTRY_SPACING] autorelease]
                                                        ,nil];
            [paragraphStyle setTabStops:tabArray];
            [tabArray release];
            [paragraphStyle setHeadIndent:(maxLabelWidth + LABEL_ENTRY_SPACING)];
            
            [tooltipBody addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,[tooltipBody length])];
            //If there is no image, also use these settings for the top part
            if (!tooltipImage) {
                [tooltipTitle addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0,[tooltipTitle length])];
            }
            
            //Display the new tooltip
            [AITooltipUtilities showTooltipWithTitle:tooltipTitle
                                                body:tooltipBody 
                                               image:tooltipImage
                                        imageOnRight:DISPLAY_IMAGE_ON_RIGHT
                                            onWindow:inWindow
                                             atPoint:point 
                                         orientation:TooltipBelow];
			
			[paragraphStyleTitle release];
			[paragraphStyle release];
        }
        
    } else {
        //Hide the existing tooltip
        if (tooltipListObject) {
            [AITooltipUtilities showTooltipWithTitle:nil 
                                                body:nil
                                               image:nil 
                                            onWindow:nil
                                             atPoint:point
                                         orientation:TooltipBelow];
            [tooltipListObject release]; tooltipListObject = nil;
			
			[tooltipTitle release]; tooltipTitle = nil;
			[tooltipBody release]; tooltipBody = nil;
			[tooltipImage release]; tooltipImage = nil;
        }
    }
}

- (NSAttributedString *)_tooltipTitleForObject:(AIListObject *)object
{
    NSMutableAttributedString           *titleString = [[NSMutableAttributedString alloc] init];
    
    id <AIContactListTooltipEntry>		tooltipEntry;
    NSEnumerator						*enumerator;
    NSEnumerator                        *labelEnumerator;
    NSMutableArray                      *labelArray = [NSMutableArray array];
    NSMutableArray                      *entryArray = [NSMutableArray array];
    NSMutableAttributedString           *entryString;
    float                               labelWidth;
    BOOL                                isFirst = YES;
    
    NSString                            *formattedUID = [object formattedUID];
    
    //Configure fonts and attributes
    NSFontManager                       *fontManager = [NSFontManager sharedFontManager];
    NSFont                              *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    NSMutableDictionary                 *titleDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:12] toHaveTrait:NSBoldFontMask],NSFontAttributeName, nil];
    NSMutableDictionary                 *labelDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:9] toHaveTrait:NSBoldFontMask], NSFontAttributeName, nil];
    NSMutableDictionary                 *labelEndLineDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:2] , NSFontAttributeName, nil];
    NSMutableDictionary                 *entryDict =[NSMutableDictionary dictionaryWithObjectsAndKeys:
        toolTipsFont, NSFontAttributeName, nil];
	
	//Get the user's display name as an attributed string
    NSAttributedString                  *displayName = [[NSAttributedString alloc] initWithString:[object displayName]
																					   attributes:titleDict];
	NSAttributedString					*filtedDisplayName = [[adium contentController] filterAttributedString:displayName
																							   usingFilterType:AIFilterDisplay
																									 direction:AIFilterIncoming
																									   context:nil];
	
	//Append the user's display name
	[titleString appendAttributedString:filtedDisplayName];
	
	//Append the user's formatted UID if there is one that's different to the display name
	if (formattedUID && (!([[[displayName string] compactedString] isEqualToString:[formattedUID compactedString]]))) {
		[titleString appendString:[NSString stringWithFormat:@" (%@)", formattedUID] withAttributes:titleDict];
	}
	[displayName release];
    
    if ([object isKindOfClass:[AIListContact class]]) {
		
		//Add the serviceID, three spaces away
		NSString	*displayServiceID;
		if ([object isKindOfClass:[AIMetaContact class]]) {
			if ([(AIMetaContact *)object containsOnlyOneUniqueContact]) {
				displayServiceID = [[[(AIMetaContact *)object preferredContact] service] shortDescription];
			} else {
				displayServiceID = META_SERVICE_STRING;
			}
		} else {
			displayServiceID = [[object service] shortDescription];
		}
		
        [titleString appendString:[NSString stringWithFormat:@"   %@",displayServiceID]
                   withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
		[fontManager convertFont:[NSFont toolTipsFontOfSize:9] 
					 toHaveTrait:NSBoldFontMask],NSFontAttributeName, nil]];
    }
    
    if ([object isKindOfClass:[AIListGroup class]]) {
        [titleString appendString:[NSString stringWithFormat:@" (%i/%i)",[(AIListGroup *)object visibleCount],[(AIListGroup *)object containedObjectsCount]] 
                   withAttributes:titleDict];
    }
    
    //Entries from plugins
    
    //Calculate the widest label while loading the arrays
    enumerator = [contactListTooltipEntryArray objectEnumerator];
    
    while ((tooltipEntry = [enumerator nextObject])) {
        
        entryString = [[tooltipEntry entryForObject:object] mutableCopy];
        if (entryString && [entryString length]) {
            
            NSString        *labelString = [tooltipEntry labelForObject:object];
            if (labelString && [labelString length]) {
                
                [entryArray addObject:entryString];
                [labelArray addObject:labelString];
                
                NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",labelString] 
																						 attributes:labelDict];
                
                //The largest size should be the label's size plus the distance to the next tab at least a space past its end
                labelWidth = [labelAttribString size].width;
                [labelAttribString release];
                
                if (labelWidth > maxLabelWidth)
                    maxLabelWidth = labelWidth;
            }
        }
        [entryString release];
    }
    
    //Add labels plus entires to the toolTip
    enumerator = [entryArray objectEnumerator];
    labelEnumerator = [labelArray objectEnumerator];
    
    while ((entryString = [enumerator nextObject])) {        
        NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:\t",[labelEnumerator nextObject]]
																				 attributes:labelDict];
        
        //Add a carriage return
        [titleString appendString:@"\r" withAttributes:labelEndLineDict];
        
        if (isFirst) {
            //skip a line
            [titleString appendString:@"\r" withAttributes:labelEndLineDict];
            isFirst = NO;
        }
        
        //Add the label (with its spacing)
        [titleString appendAttributedString:labelAttribString];
		[labelAttribString release];

		[entryString addAttributes:entryDict range:NSMakeRange(0,[entryString length])];
        [titleString appendAttributedString:entryString];
    }

    return [titleString autorelease];
}

- (NSAttributedString *)_tooltipBodyForObject:(AIListObject *)object
{
    NSMutableAttributedString       *tipString = [[NSMutableAttributedString alloc] init];
    
    //Configure fonts and attributes
    NSFontManager                   *fontManager = [NSFontManager sharedFontManager];
    NSFont                          *toolTipsFont = [NSFont toolTipsFontOfSize:10];
    NSMutableDictionary             *labelDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        [fontManager convertFont:[NSFont toolTipsFontOfSize:9] toHaveTrait:NSBoldFontMask], NSFontAttributeName, nil];
    NSMutableDictionary             *labelEndLineDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont toolTipsFontOfSize:1], NSFontAttributeName, nil];
    NSMutableDictionary             *entryDict =[NSMutableDictionary dictionaryWithObjectsAndKeys:
        toolTipsFont, NSFontAttributeName, nil];
    
    //Entries from plugins
    id <AIContactListTooltipEntry>  tooltipEntry;
    NSEnumerator                    *enumerator;
    NSEnumerator                    *labelEnumerator; 
    NSMutableArray                  *labelArray = [NSMutableArray array];
    NSMutableArray                  *entryArray = [NSMutableArray array];    
    NSMutableAttributedString       *entryString;
    float                           labelWidth;
    BOOL                            firstEntry = YES;
    
    //Calculate the widest label while loading the arrays
	enumerator = [contactListTooltipSecondaryEntryArray objectEnumerator];
	
	while ((tooltipEntry = [enumerator nextObject])) {
		
		entryString = [[tooltipEntry entryForObject:object] mutableCopy];
		if (entryString && [entryString length]) {
			
			NSString        *labelString = [tooltipEntry labelForObject:object];
			if (labelString && [labelString length]) {
				
				[entryArray addObject:entryString];
				[labelArray addObject:labelString];
				
				NSAttributedString * labelAttribString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:",labelString] 
																						 attributes:labelDict];
				
				//The largest size should be the label's size plus the distance to the next tab at least a space past its end
				labelWidth = [labelAttribString size].width;
				[labelAttribString release];
				
				if (labelWidth > maxLabelWidth)
					maxLabelWidth = labelWidth;
			}
		}
		[entryString release];
	}
		
    //Add labels plus entires to the toolTip
    enumerator = [entryArray objectEnumerator];
    labelEnumerator = [labelArray objectEnumerator];
    while ((entryString = [enumerator nextObject])) {
        NSMutableAttributedString *labelString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@:\t",[labelEnumerator nextObject]]
																						attributes:labelDict];
        
        if (firstEntry) {
            firstEntry = NO;
        } else {
            //Add a carriage return and skip a line
            [tipString appendString:@"\r\r" withAttributes:labelEndLineDict];
        }
        
        //Add the label (with its spacing)
        [tipString appendAttributedString:labelString];
        [labelString release];

        NSRange fullLength = NSMakeRange(0, [entryString length]);
        
        //remove any background coloration
        [entryString removeAttribute:NSBackgroundColorAttributeName range:fullLength];
        
        //adjust foreground colors for the tooltip background
        [entryString adjustColorsToShowOnBackground:[NSColor colorWithCalibratedRed:1.000 green:1.000 blue:0.800 alpha:1.0]];

        //headIndent doesn't apply to the first line of a paragraph... so when new lines are in the entry, we need to tab over to the proper location
        if ([entryString replaceOccurrencesOfString:@"\r" withString:@"\r\t\t" options:NSLiteralSearch range:fullLength])
            fullLength = NSMakeRange(0, [entryString length]);
        if ([entryString replaceOccurrencesOfString:@"\n" withString:@"\n\t\t" options:NSLiteralSearch range:fullLength])
            fullLength = NSMakeRange(0, [entryString length]);
		
        //Run the entry through the filters and add it to tipString
		entryString = [[[adium contentController] filterAttributedString:entryString
														 usingFilterType:AIFilterDisplay
															   direction:AIFilterIncoming
																 context:object] mutableCopy];
		
		[entryString addAttributes:entryDict range:NSMakeRange(0,[entryString length])];
        [tipString appendAttributedString:entryString];
		[entryString release];
    }

    return [tipString autorelease];
}

//Custom pasting ----------------------------------------------------------------------------------------------------
#pragma mark Custom Pasting
//Paste, stripping formatting
- (IBAction)paste:(id)sender
{
	[self _pasteWithPreferredSelector:@selector(pasteAsPlainText:) sender:sender];
}

//Paste with formatting
- (IBAction)pasteFormatted:(id)sender
{
	[self _pasteWithPreferredSelector:@selector(pasteAsRichText:) sender:sender];
}

/*
 * @brief Send a paste message, using preferredSelector if possible and paste: if not
 *
 * Walks the responder chain looking for a responder which can handle preferredSelector, skipping instances of
 * WebHTMLView.  These are skipped because we can control what paste does to WebView (by using a custom subclass) but
 * have no control over what the WebHTMLView would do.
 *
 * If no responder is found, repeats the process looking for the simpler paste: selector.
 */
- (void)_pasteWithPreferredSelector:(SEL)selector sender:(id)sender
{
	NSWindow	*keyWindow = [[NSApplication sharedApplication] keyWindow];
	NSResponder	*responder = [keyWindow firstResponder];
	
	//First, look for a responder which can handle the preferred selector
	if (!(responder = [keyWindow earliestResponderWhichRespondsToSelector:selector
														  andIsNotOfClass:NSClassFromString(@"WebHTMLView")])) {		
		//No responder found.  Try again, looking for one which will respond to paste:
		selector = @selector(paste:);
		
		responder = [keyWindow earliestResponderWhichRespondsToSelector:selector
														andIsNotOfClass:NSClassFromString(@"WebHTMLView")];
	}

	if (selector) {
		[keyWindow makeFirstResponder:responder];
		[responder performSelector:selector
						withObject:sender];
	}
}

//Custom Printing ------------------------------------------------------------------------------------------------------
#pragma mark Custom Printing
- (IBAction)adiumPrint:(id)sender
{
	//Pass the print command to the window, which is responsible for routing it to the correct place or
	//creating a view and printing.  Adium will not print from a window that does not respond to adiumPrint:
	NSWindow	*keyWindowController = [[[NSApplication sharedApplication] keyWindow] windowController];
	if ([keyWindowController respondsToSelector:@selector(adiumPrint:)]) {
		[keyWindowController performSelector:@selector(adiumPrint:)
								  withObject:sender];
	}
}

#pragma mark Preferences Display
- (IBAction)showPreferenceWindow:(id)sender
{
	[[adium preferenceController] showPreferenceWindow:sender];
}

#pragma mark Font Panel
- (IBAction)showFontPanel:(id)sender
{
	NSFontPanel	*fontPanel = [NSFontPanel sharedFontPanel];
	
	if (!fontPanelAccessoryView) {
		[NSBundle loadNibNamed:@"FontPanelAccessoryView" owner:self];
		[fontPanel setAccessoryView:fontPanelAccessoryView];
	}

	[fontPanel orderFront:self]; 
}

- (IBAction)setFontPanelSettingsAsDefaultFont:(id)sender
{
	NSFont	*selectedFont = [[NSFontManager sharedFontManager] selectedFont];

	[[adium preferenceController] setPreference:[selectedFont stringRepresentation]
										 forKey:KEY_FORMATTING_FONT
										  group:PREF_GROUP_FORMATTING];
	
	//We can't get foreground/background color from the font panel so far as I can tell... so we do the best we can.
	NSWindow	*keyWindow = [[NSApplication sharedApplication] keyWindow];
	NSResponder *responder = [keyWindow firstResponder]; 
	if ([responder isKindOfClass:[NSTextView class]]) {
		NSDictionary	*typingAttributes = [(NSTextView *)responder typingAttributes];
		NSColor			*foregroundColor, *backgroundColor;
		NSLog(@"Typing attributes are %@",typingAttributes);
		if ((foregroundColor = [typingAttributes objectForKey:NSForegroundColorAttributeName])) {
			[[adium preferenceController] setPreference:[foregroundColor stringRepresentation]
												 forKey:KEY_FORMATTING_TEXT_COLOR
												  group:PREF_GROUP_FORMATTING];
		}

		if ((backgroundColor = [typingAttributes objectForKey:AIBodyColorAttributeName])) {
			[[adium preferenceController] setPreference:[backgroundColor stringRepresentation]
												 forKey:KEY_FORMATTING_BACKGROUND_COLOR
												  group:PREF_GROUP_FORMATTING];
		}
	}
}

//Custom Dimming menu items --------------------------------------------------------------------------------------------
#pragma mark Custom Dimming menu items
//The standard ones do not dim correctly when unavailable
- (IBAction)toggleFontTrait:(id)sender
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    
    if ([fontManager traitsOfFont:[fontManager selectedFont]] & [sender tag]) {
        [fontManager removeFontTrait:sender];
    } else {
        [fontManager addFontTrait:sender];
    }
}

- (void)toggleToolbarShown:(id)sender
{
	NSWindow	*window = [[NSApplication sharedApplication] keyWindow]; 	
	[window toggleToolbarShown:sender];
}

- (void)runToolbarCustomizationPalette:(id)sender
{
	NSWindow	*window = [[NSApplication sharedApplication] keyWindow]; 	
	[window runToolbarCustomizationPalette:sender];
}

//Menu item validation
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSWindow	*keyWindow = [[NSApplication sharedApplication] keyWindow];
	NSResponder *responder = [keyWindow firstResponder]; 

    if (menuItem == menuItem_bold || menuItem == menuItem_italic) {
		NSFont			*selectedFont = [[NSFontManager sharedFontManager] selectedFont];
		
		//We must be in a text view, have text on the pasteboard, and have a font that supports bold or italic
		if ([responder isKindOfClass:[NSTextView class]]) {
			return (menuItem == menuItem_bold ? [selectedFont supportsBold] : [selectedFont supportsItalics]);
		}
		return NO;
		
	} else if (menuItem == menuItem_paste || menuItem == menuItem_pasteFormatted) {
		return [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, NSTIFFPboardType, NSPICTPboardType, NSPDFPboardType, nil]] != nil;
	
	} else if (menuItem == menuItem_showToolbar) {
		[menuItem_showToolbar setTitle:([[keyWindow toolbar] isVisible] ? 
										AILocalizedString(@"Hide Toolbar",nil) : 
										AILocalizedString(@"Show Toolbar",nil))];
		return [keyWindow toolbar] != nil;
	
	} else if (menuItem == menuItem_customizeToolbar) {
		return [keyWindow toolbar] != nil && [[keyWindow toolbar] isVisible];

	} else if (menuItem == menuItem_closeChat) {
		return activeChat != nil;
		
	} else if( menuItem == menuItem_closeAllChats) {
		return [[self openChats] count] > 0;

	} else if (menuItem == menuItem_print) {
		return [[keyWindow windowController] respondsToSelector:@selector(adiumPrint:)];
		
	} else {
		return YES;
	}
}

#pragma mark Window levels
- (NSMenu *)menuForWindowLevelsNotifyingTarget:(id)target
{
	NSMenu		*windowPositionMenu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSMenuItem	*menuItem;
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Above other windows",nil)
																	target:target
																	action:@selector(selectedWindowLevel:)
															 keyEquivalent:@""];
	[menuItem setEnabled:YES];
	[menuItem setTag:AIFloatingWindowLevel];
	[windowPositionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Normally",nil)
																	target:target
																	action:@selector(selectedWindowLevel:)
															 keyEquivalent:@""];
	[menuItem setEnabled:YES];
	[menuItem setTag:AINormalWindowLevel];
	[windowPositionMenu addItem:menuItem];
	[menuItem release];
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Below other windows",nil)
																	target:target
																	action:@selector(selectedWindowLevel:)
															 keyEquivalent:@""];
	[menuItem setEnabled:YES];
	[menuItem setTag:AIDesktopWindowLevel];
	[windowPositionMenu addItem:menuItem];
	[menuItem release];
	
	[windowPositionMenu setAutoenablesItems:NO];

	return [windowPositionMenu autorelease];
}

@end
