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

#import "AIDualWindowInterfacePlugin.h"
#import "AIMessageViewController.h"
#import "AIMessageWindowController.h"
#import "AIMessageTabViewItem.h"
#import "ESDualWindowMessageWindowPreferences.h"
#import "ESDualWindowMessageAdvancedPreferences.h"

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
#warning move to separate plugin
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_DEFAULT_PREFS forClass:[self class]] 
										  forGroup:PREF_GROUP_INTERFACE];
		
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_WINDOW_DEFAULT_PREFS forClass:[self class]] 
										  forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];    
	preferenceMessageController = [[ESDualWindowMessageWindowPreferences preferencePane] retain];
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
	
}	


//Interface: Chat Control ----------------------------------------------------------------------------------------------
#pragma mark Interface: Chat Control
//Open a new chat window
- (id)openChat:(AIChat *)chat inContainerWithID:(NSString *)containerID atIndex:(int)index
{
	AIMessageTabViewItem		*messageTab = [[chat statusDictionary] objectForKey:@"MessageTabViewItem"];
	AIMessageWindowController	*container = nil;
	AIMessageViewController 	*messageView = nil;
	
	//Create the messasge tab (if necessary)
	if(!messageTab){
		container = [self openContainerWithID:containerID name:containerID];
		messageView = [AIMessageViewController messageViewControllerForChat:chat];

		//Add chat to container
		messageTab = [AIMessageTabViewItem messageTabWithView:messageView];
		[[chat statusDictionary] setObject:messageTab forKey:@"MessageTabViewItem"];
		[container addTabViewItem:messageTab atIndex:index silent:NO];
	}

    //Display the account selector (if multiple accounts are available for sending to the contact)
	[[messageTab messageViewController] setAccountSelectionMenuVisible:YES];
	
	//Open the container window.  We wait until after the chat has been added to the container
	//before making it visible so window opening looks cleaner.
	if(container && !applicationIsHidden && ![[container window] isVisible]){
		[container showWindowInFront:!([[adium interfaceController] activeChat])];
	}
	
	return(messageTab);
}

//Close a chat window
- (void)closeChat:(AIChat *)chat
{
	AIMessageTabViewItem		*messageTab = [[chat statusDictionary] objectForKey:@"MessageTabViewItem"];
	AIMessageWindowController	*container = [messageTab container];
	
	//Close the chat
	[container removeTabViewItem:messageTab silent:NO];
	[[chat statusDictionary] removeObjectForKey:@"MessageTabViewItem"];
}

//Make a chat active
- (void)setActiveChat:(AIChat *)inChat
{
	AIMessageTabViewItem *messageTab = [[inChat statusDictionary] objectForKey:@"MessageTabViewItem"];
	if(messageTab) [messageTab makeActive:nil];
}

//Move a chat
- (void)moveChat:(AIChat *)chat toContainerWithID:(NSString *)containerID index:(int)index
{
	AIMessageTabViewItem		*messageTab = [[chat statusDictionary] objectForKey:@"MessageTabViewItem"];
	AIMessageWindowController	*container = [containers objectForKey:containerID];

	if([messageTab container] == container){
		[container moveTabViewItem:messageTab toIndex:index];
	}else{
		[messageTab retain];
		[[messageTab container] removeTabViewItem:messageTab silent:YES];
		[container addTabViewItem:messageTab atIndex:index silent:YES];
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
	
	while(container = [containerEnumerator nextObject]){
		[openContainersAndChats addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[container containerID], @"ID",
			[container containedChats], @"Content",
			[container name], @"Name",
			nil]];
	}
	
	return(openContainersAndChats);
}

//Returns an array of open container IDs
- (NSArray *)openContainers
{
	return([containers allKeys]);
}

//Returns an array of open chats
- (NSArray *)openChats
{
	NSMutableArray				*openContainersAndChats = [NSMutableArray array];
	NSEnumerator				*containerEnumerator = [containers objectEnumerator];
	AIMessageWindowController	*container;
	
	while(container = [containerEnumerator nextObject]){
		[openContainersAndChats addObjectsFromArray:[container containedChats]];
	}
	
	return(openContainersAndChats);
}

//Returns the ID of the container containing the chat
- (NSString *)containerIDForChat:(AIChat *)chat
{
	return([[[[chat statusDictionary] objectForKey:@"MessageTabViewItem"] container] containerID]);
}

//Returns an array of all the chats in a container
- (NSArray *)openChatsInContainerWithID:(NSString *)containerID
{
	return([[containers objectForKey:containerID] containedChats]);
}


//Containers -----------------------------------------------------------------------------------------------------------
#pragma mark Containers
//Open a new container
- (id)openContainerWithID:(NSString *)containerID name:(NSString *)containerName
{
	AIMessageWindowController	*container = [containers objectForKey:containerID];
	if(!container){
		container = [AIMessageWindowController messageWindowControllerForInterface:self withID:containerID name:containerName];
		[containers setObject:container forKey:containerID];
		
		//If Adium is hidden, remember to open this container later
		if(applicationIsHidden) [delayedContainerShowArray addObject:container];
	}
	
	return(container);
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
	if(key) [containers removeObjectForKey:key];
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
	while(container = [enumerator nextObject]) [container showWindowInFront:YES];

	[delayedContainerShowArray removeAllObjects];
	applicationIsHidden = NO;
}


//Custom Tab Management ------------------------------------------------------------------------------------------------
#pragma mark Custom Tab Management
//Transfer a tab from one window to another (or to it's own window)
- (void)transferMessageTab:(AIMessageTabViewItem *)tabViewItem
			   toContainer:(id)newMessageWindow
				   atIndex:(int)index
		 withTabBarAtPoint:(NSPoint)screenPoint
{
	AIMessageWindowController 	*oldMessageWindow = [tabViewItem container];
	
	if(oldMessageWindow != newMessageWindow){
		//Get the frame of the source window (We must do this before removing the tab, since removing a tab may
		//destroy the source window)
		NSRect  oldMessageWindowFrame = [[oldMessageWindow window] frame];
		
		//Remove the tab, which will close the containiner if it becomes empty
		[tabViewItem retain];
	
		[oldMessageWindow removeTabViewItem:tabViewItem silent:YES];
		
		//Spawn a new window (if necessary)
		if(!newMessageWindow){
			NSRect          newFrame;
			
			//Default to the width of the source container, and the drop point
			newFrame.size.width = oldMessageWindowFrame.size.width;
			newFrame.size.height = oldMessageWindowFrame.size.height;
			
			newFrame.origin = screenPoint;
			
			//Create a new unique container, set the frame
			newMessageWindow = [self openContainerWithID:[NSString stringWithFormat:@"%@:%i", ADIUM_UNIQUE_CONTAINER, uniqueContainerNumber++]
													name:@"Messages"];
			
			if(newFrame.origin.x == -1 && newFrame.origin.y == -1){
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

@end

