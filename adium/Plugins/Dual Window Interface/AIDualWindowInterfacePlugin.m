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
#import "AIDualWindowPreferences.h"
#import "AIDualWindowAdvancedPrefs.h"
#import "ESDualWindowMessageWindowPreferences.h"
#import "ESDualWindowMessageAdvancedPreferences.h"

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
#warning clean up used
//    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_DEFAULT_PREFS forClass:[self class]] 
//										  forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
//    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:DUAL_INTERFACE_WINDOW_DEFAULT_PREFS forClass:[self class]] 
//										  forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];    
//	preferenceMessageAdvController = [[ESDualWindowMessageAdvancedPreferences preferencePane] retain];

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
- (id)openChat:(AIChat *)chat inContainerNamed:(NSString *)containerName atIndex:(int)index
{
	AIMessageTabViewItem		*messageTab = [[chat statusDictionary] objectForKey:@"MessageTabViewItem"];
	AIMessageWindowController	*container = nil;
	AIMessageViewController 	*messageView = nil;
	
	//Create the messasge tab (if necessary)
	if(!messageTab){
		container = [self openContainerNamed:containerName];
		messageView = [AIMessageViewController messageViewControllerForChat:chat];

		//Add chat to container
		messageTab = [AIMessageTabViewItem messageTabWithView:messageView];
		[[chat statusDictionary] setObject:messageTab forKey:@"MessageTabViewItem"];
		[container addTabViewItem:messageTab atIndex:index];
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
	[container removeTabViewItem:messageTab];
	[[chat statusDictionary] removeObjectForKey:@"MessageTabViewItem"];

//	//Close the container
//	if([container containerIsEmpty]){
//		[self closeContainer:container];
//	}
}

//Make a chat active
- (void)setActiveChat:(AIChat *)inChat
{
	AIMessageTabViewItem *messageTab = [[inChat statusDictionary] objectForKey:@"MessageTabViewItem"];
	if(messageTab) [messageTab makeActive:nil];
}

//Move a chat
- (void)moveChat:(AIChat *)chat toContainerNamed:(NSString *)containerName index:(int)index
{
	AIMessageTabViewItem		*messageTab = [[chat statusDictionary] objectForKey:@"MessageTabViewItem"];
	AIMessageWindowController	*container = [containers objectForKey:containerName];

	if([messageTab container] == container){
		[container moveTabViewItem:messageTab toIndex:index];
	}else{
#warning ignoring cross-container moves for now
		NSLog(@"ignoring cross-container moves for now");		
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
			[container name], @"Title",
			[container containedChats], @"Content",
			nil]];
	}
	
	return(openContainersAndChats);
}

//Returns an array of open container names
- (NSArray *)openContainerNames
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

//Returns the name of the container containing the chat
- (NSString *)containerNameForChat:(AIChat *)chat
{
	return([[[[chat statusDictionary] objectForKey:@"MessageTabViewItem"] container] name]);
}

//Returns an array of all the chats in a container
- (NSArray *)openChatsInContainerNamed:(NSString *)containerName
{
	return([[containers objectForKey:containerName] containedChats]);
}


//Containers -----------------------------------------------------------------------------------------------------------
#pragma mark Containers
//Open a new container
- (id)openContainerNamed:(NSString *)containerName
{
	AIMessageWindowController	*container = [containers objectForKey:containerName];
	if(!container){
		container = [AIMessageWindowController messageWindowControllerForInterface:self withName:containerName];
		[containers setObject:container forKey:containerName];
		
		//If Adium is hidden, remember to open this container later
		if(applicationIsHidden) [delayedContainerShowArray addObject:container];
			
//		if(applicationIsHidden){
//			//If another chat is open, open behind it
////			[container showWindowInFront:!([[adium interfaceController] activeChat])];
//		}else{
//			[delayedContainerShowArray addObject:container];
//		}
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
	
		[oldMessageWindow removeTabViewItem:tabViewItem];
		
		//Spawn a new window (if necessary)
		if(!newMessageWindow){
			NSRect          newFrame;
			
			//Default to the width of the source container, and the drop point
			newFrame.size.width = oldMessageWindowFrame.size.width;
			newFrame.size.height = oldMessageWindowFrame.size.height;
			
			newFrame.origin = screenPoint;
			
			//Create a new unique container, set the frame
			newMessageWindow = [self openContainerNamed:[NSString stringWithFormat:@"ADIUM_UNIQUE_CONTAINER:%i", uniqueContainerNumber++]];
			
			if(newFrame.origin.x == -1 && newFrame.origin.y == -1){
				NSRect curFrame = [[newMessageWindow window] frame];
				newFrame.origin = curFrame.origin;				
			}
			
			[[newMessageWindow window] setFrame:newFrame display:NO];
			
		}
		
		[(AIMessageWindowController *)newMessageWindow addTabViewItem:tabViewItem atIndex:index]; 
		[tabViewItem makeActive:nil];
		[tabViewItem release];
	}
	
}

@end

