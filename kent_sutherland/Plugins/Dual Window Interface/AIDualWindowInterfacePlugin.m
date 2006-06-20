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

#import "AIDualWindowInterfacePlugin.h"
#import "AIInterfaceController.h"
#import "AIMessageTabViewItem.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import "AIChatController.h"
#import "ESDualWindowMessageAdvancedPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIChat.h>

#define ADIUM_UNIQUE_CONTAINER			@"ADIUM_UNIQUE_CONTAINER"

@implementation AIDualWindowInterfacePlugin

//Install
- (void)installPlugin
{
    [[adium interfaceController] registerInterfaceController:self];
}

//Open the interface
- (void)openInterface
{
	containers = [[NSMutableDictionary alloc] init];
	delayedContainerShowArray = [[NSMutableArray alloc] init];
	uniqueContainerNumber = 0;
	applicationIsHidden = NO;

	//Preferences
	//XXX - move to separate plugin
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_DEFAULT_PREFS forClass:[self class]] 
										  forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

	preferenceMessageAdvController = [[ESDualWindowMessageAdvancedPreferences preferencePane] retain];

	
	//Watch Adium hide and unhide (Used for better window opening behavior)
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationDidHide:)
												 name:NSApplicationDidHideNotification
											   object:NSApp];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationDidUnhide:)
												 name:NSApplicationDidUnhideNotification
											   object:NSApp];
}

//Close the interface
- (void)closeInterface
{
	//Close and unload our windows
	[[containers allValues] makeObjectsPerformSelector:@selector(closeWindow:) withObject:nil];

    //Stop observing
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    //Cleanup
	[preferenceMessageAdvController release]; preferenceMessageAdvController = nil;
    [containers release]; containers = nil;
	[delayedContainerShowArray release]; delayedContainerShowArray = nil;
}	


//Interface: Chat Control ----------------------------------------------------------------------------------------------
#pragma mark Interface: Chat Control
//Open a new chat window
- (id)openChat:(AIChat *)chat inContainerWithID:(NSString *)containerID atIndex:(int)index
{
	AIMessageTabViewItem		*messageTab = [chat statusObjectForKey:@"MessageTabViewItem"];
	AIMessageWindowController	*container = nil;
	AIMessageViewController 	*messageView = nil;
	
	//Create the messasge tab (if necessary)
	if (!messageTab) {
		container = [self openContainerWithID:containerID name:containerID];
		messageView = [AIMessageViewController messageViewControllerForChat:chat];

		//Add chat to container
		messageTab = [AIMessageTabViewItem messageTabWithView:messageView];
		[chat setStatusObject:messageTab
					   forKey:@"MessageTabViewItem"
					   notify:NotifyNever];
		[container addTabViewItem:messageTab atIndex:index silent:NO];
	}

    //Display the account selector if necessary
	[[messageTab messageViewController] setAccountSelectionMenuVisibleIfNeeded:YES];
	
	//Open the container window.  We wait until after the chat has been added to the container
	//before making it visible so window opening looks cleaner.
	if (container && !applicationIsHidden && ![[container window] isVisible]) {
		[container showWindowInFront:!([[adium interfaceController] activeChat])];
	}
	
	return messageTab;
}

/*
 * @brief Close a chat
 *
 * First, tell the chatController to close the chat. If it returns YES, remove our interface to the chat.
 * Take no action if it returns NO; this indicates that the chat shouldn't close, probably because it's about
 * to receive another message.
 */
- (void)closeChat:(AIChat *)chat
{
	if ([[adium chatController] closeChat:chat]) {
		AIMessageTabViewItem		*messageTab = [chat statusObjectForKey:@"MessageTabViewItem"];
		AIMessageWindowController	*container = [messageTab container];
		
		//Close the chat
		[container removeTabViewItem:messageTab silent:NO];
		[chat setStatusObject:nil
					   forKey:@"MessageTabViewItem"
					   notify:NotifyNever];
	}
}

//Make a chat active
- (void)setActiveChat:(AIChat *)inChat
{
	AIMessageTabViewItem *messageTab = [inChat statusObjectForKey:@"MessageTabViewItem"];
	if (messageTab) [messageTab makeActive:nil];
}

//Move a chat
- (void)moveChat:(AIChat *)chat toContainerWithID:(NSString *)containerID index:(int)index
{
	AIMessageTabViewItem		*messageTab = [chat statusObjectForKey:@"MessageTabViewItem"];
	AIMessageWindowController	*container = [containers objectForKey:containerID];

	if ([messageTab container] == container) {
		[container moveTabViewItem:messageTab toIndex:index];
	} else {
		[messageTab retain];
		[[messageTab container] removeTabViewItem:messageTab silent:YES];

		//Create the container if necessary
		if (!container) {
			container = [self openContainerWithID:containerID name:containerID];
		}

		[container addTabViewItem:messageTab atIndex:index silent:YES];
		[chat setStatusObject:messageTab
					   forKey:@"MessageTabViewItem"
					   notify:NotifyNever];
		
		[messageTab release];
	}
}


//Interface: Chat Access -----------------------------------------------------------------------------------------------
#pragma mark Interface: Chat Access
//Returns an array of open containers and chats
- (NSArray *)openContainersAndChats
{
	NSMutableArray				*openContainersAndChats = [NSMutableArray array];
	NSEnumerator				*containerEnumerator = [containers objectEnumerator];
	AIMessageWindowController	*container;
	
	while ((container = [containerEnumerator nextObject])) {
		[openContainersAndChats addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[container containerID], @"ID",
			[container containedChats], @"Content",
			[container name], @"Name",
			nil]];
	}
	
	return openContainersAndChats;
}

//Returns an array of open container IDs
- (NSArray *)openContainers
{
	return [containers allKeys];
}

//Returns an array of open chats
- (NSArray *)openChats
{
	NSMutableArray				*openContainersAndChats = [NSMutableArray array];
	NSEnumerator				*containerEnumerator = [containers objectEnumerator];
	AIMessageWindowController	*container;
	
	while ((container = [containerEnumerator nextObject])) {
		[openContainersAndChats addObjectsFromArray:[container containedChats]];
	}
	
	return openContainersAndChats;
}

//Returns the ID of the container containing the chat
- (NSString *)containerIDForChat:(AIChat *)chat
{
	return [[[chat statusObjectForKey:@"MessageTabViewItem"] container] containerID];
}

//Returns an array of all the chats in a container
- (NSArray *)openChatsInContainerWithID:(NSString *)containerID
{
	return [[containers objectForKey:containerID] containedChats];
}

/*
 * @brief Find the window currently displaying a chat
 *
 * If the chat is not in any window, or is not visible in any window, returns nil
 */
- (NSWindow *)windowForChat:(AIChat *)chat
{
	AIMessageWindowController	*windowController = [[chat statusObjectForKey:@"MessageTabViewItem"] container];
	
	return (([windowController activeChat] == chat) ?
			[windowController window] :
			nil);
}

/*
 * @brief Find the chat active in a window
 *
 * If the window does not have an active chat, nil is returned
 */
- (AIChat *)activeChatInWindow:(NSWindow *)window
{
	AIChat				*chat = nil;
	NSWindowController	*windowController = [window windowController];

	if ([windowController isKindOfClass:[AIMessageWindowController class]]) {
		chat = [(AIMessageWindowController *)windowController activeChat];
	}
	
	return chat;
}

//Containers -----------------------------------------------------------------------------------------------------------
#pragma mark Containers
//Open a new container
- (id)openContainerWithID:(NSString *)containerID name:(NSString *)containerName
{
	AIMessageWindowController	*container = [containers objectForKey:containerID];
	if (!container) {
		container = [AIMessageWindowController messageWindowControllerForInterface:self withID:containerID name:containerName];
		[containers setObject:container forKey:containerID];
		
		//If Adium is hidden, remember to open this container later
		if (applicationIsHidden) [delayedContainerShowArray addObject:container];
	}
	
	return container;
}

//Close a continer
- (void)closeContainer:(AIMessageWindowController *)container
{
	[container closeWindow:nil];
}

//A container did close
- (void)containerDidClose:(AIMessageWindowController *)container
{
	NSString	*key = [[containers allKeysForObject:container] lastObject];
	if (key) [containers removeObjectForKey:key];
}

//Adium hid
- (void)applicationDidHide:(NSNotification *)notification
{
	applicationIsHidden = YES;
}

//Adium unhid
- (void)applicationDidUnhide:(NSNotification *)notification
{
	NSEnumerator				*enumerator;
	AIMessageWindowController	*container;

	//Open any containers that should have opened while we were hidden
	enumerator = [delayedContainerShowArray objectEnumerator];
	while ((container = [enumerator nextObject])) [container showWindowInFront:YES];

	[delayedContainerShowArray removeAllObjects];
	applicationIsHidden = NO;
}


//Custom Tab Management ------------------------------------------------------------------------------------------------
#pragma mark Custom Tab Management
//Transfer a tab from one window to another (or to its own window)
- (void)transferMessageTab:(AIMessageTabViewItem *)tabViewItem
			   toContainer:(id)newMessageWindow
				   atIndex:(int)index
		 withTabBarAtPoint:(NSPoint)screenPoint
{
	AIMessageWindowController 	*oldMessageWindow = [tabViewItem container];
	
	if (oldMessageWindow != newMessageWindow) {
		//Get the frame of the source window (We must do this before removing the tab, since removing a tab may
		//destroy the source window)
		NSRect  oldMessageWindowFrame = [[oldMessageWindow window] frame];
		
		//Remove the tab, which will close the containiner if it becomes empty
		[tabViewItem retain];
	
		[oldMessageWindow removeTabViewItem:tabViewItem silent:YES];
		
		//Spawn a new window (if necessary)
		if (!newMessageWindow) {
			NSRect          newFrame;
			
			//Default to the width of the source container, and the drop point
			newFrame.size.width = oldMessageWindowFrame.size.width;
			newFrame.size.height = oldMessageWindowFrame.size.height;
			
			newFrame.origin = screenPoint;
			
			//Create a new unique container, set the frame
			newMessageWindow = [self openContainerWithID:[NSString stringWithFormat:@"%@:%i", ADIUM_UNIQUE_CONTAINER, uniqueContainerNumber++]
													name:AILocalizedString(@"Chat",nil)];
			
			if (newFrame.origin.x == -1 && newFrame.origin.y == -1) {
				NSRect curFrame = [[newMessageWindow window] frame];
				newFrame.origin = curFrame.origin;				
			}
			
			[[newMessageWindow window] setFrame:newFrame display:NO];
			
		}
		
		[(AIMessageWindowController *)newMessageWindow addTabViewItem:tabViewItem atIndex:index silent:YES]; 
		[[adium interfaceController] chatOrderDidChange];
		[tabViewItem makeActive:nil];
		[tabViewItem release];
	}
	
}

- (id)openNewContainer
{
	AIMessageWindowController *controller = [self openContainerWithID:[NSString stringWithFormat:@"%@:%i", ADIUM_UNIQUE_CONTAINER, uniqueContainerNumber++]
													name:AILocalizedString(@"Chat",nil)];
	return controller;
}

@end

