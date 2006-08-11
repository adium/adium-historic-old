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

#import "JLPresenceController.h"
#import "AIAccountController.h"
#import "AIChatController.h"
#import "AIInterfaceController.h"
#import "AIStatusController.h"
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/AIStatusMenu.h>
#import <Adium/AIAccountMenu.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>

#import <unistd.h>

@interface JLPresenceController (PRIVATE)
- (void)activateAdium: (id)sender;
@end

@implementation JLPresenceController

+ (JLPresenceController *)presenceController
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{	
	if ((self = [super init])) {
		
		// FIXME: add distributedNotificationCenter to AIAdium?!?
		notificationCenter = [NSDistributedNotificationCenter defaultCenter];
		//notificationCenter = [adium notificationCenter];
		
		if ([[adium accountController] oneOrMoreConnectedAccounts]) {
			[notificationCenter postNotificationName: @"AIPresenceOnline" object: nil];
		} else {
			[notificationCenter postNotificationName: @"AIPresenceOffline" object: nil];
		}		
		
		// Setup for open chats and unviewed content catching
		accountMenuItemsArray = [[NSMutableArray alloc] init];
		stateMenuItemsArray = [[NSMutableArray alloc] init];
		unviewedObjectsArray = [[NSMutableArray alloc] init];
		openChatsArray = [[NSMutableArray alloc] init];
		
		// Presence changed and app running notifications
		[notificationCenter postNotificationName: @"AIPresenceChanged" object: nil];
		[notificationCenter postNotificationName: @"AIAdiumRunning" object: nil];
		
		// Register to receive notification of chats opening and closing
		[notificationCenter addObserver: self
							   selector: @selector(chatOpened:)
								   name: Chat_DidOpen
								 object: nil];
		
		[notificationCenter addObserver: self
							   selector: @selector(chatClosed:)
								   name: Chat_WillClose
								 object: nil];
		
		[notificationCenter addObserver: self
							   selector: @selector(statusIconSetDidChange:)
								   name: AIStatusIconSetDidChangeNotification
								 object: nil];
		
		// Register as chat observer (for catching unviewed content)
		[[adium chatController] registerChatObserver: self];
		
		// Register to receive state change notifications
		[notificationCenter addObserver: self
							   selector: @selector(accountStateChanged:)
								   name: AIStatusActiveStateChangedNotification
								 object: nil];
			
		// Broadcast ourselves via DO
		NSConnection	*vendor = [NSConnection defaultConnection];
		[vendor setRootObject:self];
		
		if(![vendor registerName:ADIUM_PRESENCE_BROADCAST]) {
			// TODO: implement some *decent* error handling here
			AILog(@"JL_DEBUG: We are not vending :(");
		} else {
			AILog(@"JL_DEBUG: We *are* vending! :)");
		}
	}
	
	return self;
}

- (void) dealloc 
{
	// Warn that we're going down
	[notificationCenter postNotificationName: @"AIAdiumClosing" object: nil];
	// Unregister ourself
	[[adium chatController] unregisterChatObserver: self];
	[[adium notificationCenter] removeObserver: self];
	
	// Release our objects
	[unviewedObjectsArray release];
	[accountMenu release];
	[statusMenu release];
	
	[super dealloc];
}


#pragma mark Menu Rebuilding

- (void) accountMenuRebuild: (NSArray *) menuItems
{
	[accountMenuItemsArray release];
	accountMenuItemsArray = [menuItems retain];
}

- (void) statusMenuRebuild: (NSArray *) menuItemArray
{
	[stateMenuItemsArray removeAllObjects];
	[ stateMenuItemsArray addObjectsFromArray:menuItemArray];
}

#pragma mark Chat Observer
- (void) chatOpened:(NSNotification *)notification
{
	// Add it to the array
	[openChatsArray addObject: [notification object]];
	
	// We need to update the menu next time
	[notificationCenter postNotificationName: @"AIPresenceChanged" object: nil];
}

- (void) chatClosed: (NSNotification *)notification
{
	AIChat *chat = [notification object];
	// Remove it from the array
	[openChatsArray removeObjectIdenticalTo: chat];
	[unviewedObjectsArray removeObjectIdenticalTo: chat];
	[notificationCenter postNotificationName: @"AIChatClosed" object: chat];
}

- (NSSet *)updateChat: (AIChat *)inChat keys: (NSSet *)inModifiedKeys silent: (BOOL)isSilent
{
	// If the contact's unviewed content state has changed
	if (inModifiedKeys == nil || [inModifiedKeys containsObject: KEY_UNVIEWED_CONTENT]) {
		// If there is new unviewed content
		if ([inChat unviewedContentCount]) {
			// If we're not already watching it
			if (![unviewedObjectsArray containsObjectIdenticalTo: inChat]) {
				// Add it, we're watching it now
				[unviewedObjectsArray addObject: inChat];
				
				// We need to update our menu
				[notificationCenter postNotificationName: @"AIPresenceChanged" object: nil];
			}
		} else {
			// If we're tracking this object
			if ([unviewedObjectsArray containsObjectIdenticalTo: inChat]) {
				// Remove it, it's not unviewed anymore
				[unviewedObjectsArray removeObjectIdenticalTo: inChat];
				// We need to update our menu
				[notificationCenter postNotificationName: @"AIPresenceChanged" object: nil];
			}
		}
	}
	
	if ([unviewedObjectsArray count] == 0) {
		// If there are no more contacts with unviewed content, set our icon to normal
		if (unviewedContent) {
			if ([[adium accountController] oneOrMoreConnectedAccounts]) {
				[notificationCenter postNotificationName: @"AIPresenceOnline" object: nil];
			} else {
				[notificationCenter postNotificationName: @"AIPresenceOffline" object: nil];
			}
			unviewedContent = NO;
		}
	} else {
		// If this is the first contact with unviewed content, set our icon to unviewed content
		if (!unviewedContent) {
			unviewedContent = YES;  // FIXME: unviewedContent superfluous?
			// TODO: trigger unviewed content icon in UI
			[notificationCenter postNotificationName: @"AIPresenceChanged" object: nil];
		}
	}
	
	// If they're typing we also need to update because we show typing within the menu next to chats
	if ([inModifiedKeys containsObject: KEY_TYPING]) {
		[notificationCenter postNotificationName: @"AIPresenceChanged" object: nil];
	}
	
	// We didn't modify attributes so return nil
	return nil;
}

#pragma mark -
- (void)accountStateChanged: (NSNotification *)notification
{
	if (!unviewedContent) {
		if ([[adium accountController] oneOrMoreConnectedAccounts]) {
			[notificationCenter postNotificationName: @"AIPresenceOnline" object: nil];
		} else {
			[notificationCenter postNotificationName: @"AIPresenceOffline" object: nil];
		}
	}
}

- (void)statusIconSetDidChange: (NSNotification *)notification
{
	if (unviewedContent) {
		// TODO: set duck with badge
		[notificationCenter postNotificationName: @"AIPresenceChanged" object: nil];
	} else {
		if ([[adium accountController] oneOrMoreConnectedAccounts]) {
			[notificationCenter postNotificationName: @"AIPresenceOnline" object: nil];
		} else {
			[notificationCenter postNotificationName: @"AIPresenceOffline" object: nil];
		}
	}
}

- (NSArray *)accountMenuItemsArray
{
	return accountMenuItemsArray;
}

- (NSArray *)stateMenuItemsArray
{
	return stateMenuItemsArray;
}

- (NSArray *)openChatsArray
{
	return openChatsArray;
}

#pragma mark Distributed Menu Actions

- (void) activateAdium: (id) sender
{
	[NSApp activateIgnoringOtherApps: YES];
	[NSApp arrangeInFront: nil];
}

- (void) switchToChat: (id) sender
{
	// If Adium isn't the active app, activate it
	if (![NSApp isActive]) {
		[self activateAdium: nil];
	}
	
	[[adium interfaceController] setActiveChat: [sender representedObject]];
}

- (void) terminate
{
	// Kill Adium :(
	[NSApp terminate: self];
}

@end
