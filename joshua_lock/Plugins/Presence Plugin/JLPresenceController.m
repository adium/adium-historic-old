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
#import "JLPresenceRemote.h"
#import "AIAccountController.h"
#import "AIChatController.h"
#import "AIInterfaceController.h"
#import "AIStatusController.h"
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/AIStatusMenu.h>
#import <Adium/AIAccountMenu.h>

#define STATUS_ITEM_MARGIN 8

@interface JLPresenceController (PRIVATE)
@end

@implementation JLPresenceController

//Returns the shared instance, possibly initializing and creating a new one.
+ (JLPresenceController *)presenceController
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
	if ((self = [super init])) {
		openChatsArray = [[NSMutableArray alloc] init];
		unviewedObjectsArray = [[NSMutableArray alloc] init];
		
		presenceRemote = [JLPresenceRemote presenceRemote];
		vendor = [NSConnection defaultConnection];
		// FIXME: we don't really want to be broadcasting self
		[vendor setRootObject: presenceRemote];
		
		if(![vendor registerName:ADIUM_PRESENCE_BROADCAST]) {
			// TODO: implement some *decent* error handling here
			AILog(@"JLD: We are not vending :(");
		} else {
			AILog(@"JLD: We *are* vending! :)");
		}
		
		notificationCenter = [NSDistributedNotificationCenter defaultCenter];
		[notificationCenter postNotificationName:@"JL_AdiumRunning" object:nil];
		// We need to broadcast accounts being online etc...
		[notificationCenter addObserver:self
							   selector:@selector(smdRunning:)
								   name:@"JL_SMDRunning"
								 object:nil];
		[notificationCenter addObserver:self
							   selector:@selector(killAdium:)
								   name:@"JL_QuitAdium"
								 object:nil];
		[notificationCenter addObserver:self
							   selector:@selector(bringFront:)
								   name:@"JL_BringAdiumFront"
								 object:nil];
		[notificationCenter addObserver:self
							   selector:@selector(activateStatus:)
								   name:@"JL_AdiumActivateStatus"
								 object:nil];
		
		NSNotificationCenter *localNotes = [adium notificationCenter];
		[localNotes addObserver:self
					   selector:@selector(chatOpened:)
						   name:Chat_DidOpen
						 object:nil];
		[localNotes addObserver:self
					   selector:@selector(chatClosed:)
						   name:Chat_WillClose
						 object:nil];
		[localNotes addObserver:self
					   selector:@selector(accountStateChanged:)
						   name:AIStatusActiveStateChangedNotification
						 object:nil];
		[[adium chatController] registerChatObserver:self];
	}
	
	return self;
}

- (void)dealloc
{
	[notificationCenter postNotificationName:@"JL_AdiumClosing" object: nil];
	//Unregister ourself
	[[adium chatController] unregisterChatObserver:self];
	[notificationCenter removeObserver:self];
	
	//Release our objects
	[vendor release];
		
	//To the superclass, Robin!
	[super dealloc];
}

#pragma mark Notification Handlers

- (void)smdRunning:(NSNotification *)note
{
	/* We receive this notification *if* SMD is started after Adium, we need to let 
	SMD know that Adium is already running. */
	if ([[adium accountController] oneOrMoreConnectedAccounts]) {
		[notificationCenter postNotificationName:@"JL_AdiumOnline" object:nil];
	} else {
		[notificationCenter postNotificationName:@"JL_AdiumRunning" object:nil];
	}
}

- (void)killAdium:(NSNotification *)note
{
	[notificationCenter postNotificationName:@"JL_AdiumClosing" object: nil];
	[adium confirmQuit:self];
	
}

- (void)bringFront:(NSNotification *)note
{
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp arrangeInFront:nil];
}

- (void)accountStateChanged:(NSNotification *)note
{
	[presenceRemote populateStatusObjects];
	// FIXME: this possibly needs to be a little more refined?
	if ([[adium accountController] oneOrMoreConnectedAccounts]) {
		[notificationCenter postNotificationName:@"JL_AdiumOnline" object:nil];
	}
}

- (void)activateStatus:(NSNotification *)note
{
	// Deciper the dict & convert to an AIStatus
	NSString	*title = [[note userInfo] objectForKey:@"statusTitle"];
	NSNumber	*type = [[note userInfo] objectForKey:@"statusType"];
	// Activate the AIStatus
	AIStatus *statusState = [AIStatus statusOfType:(AIStatusType)[type intValue]];
	[statusState setStatusName:title];
	// FIXME: we would like an account sent with the note
	//[account setStatusState:statusState];
}

#pragma mark Chat Observer

- (void)chatOpened:(NSNotification *)notification
{
	// FIXME: trigger some UI
	[openChatsArray addObject:[notification object]];
}

- (void)chatClosed:(NSNotification *)notification
{
	// FIXME: trigger some UI
	AIChat *chat = [notification object];
	[openChatsArray removeObjectIdenticalTo:chat];
	
	[unviewedObjectsArray removeObjectIdenticalTo:chat];
}

- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent		
{
	// If the contacts unviewed content state has changed
	if (inModifiedKeys == nil || [inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]) {
		// If there is new unviewed content
		if ([inChat unviewedContentCount]) {
			// If we're not already watching it
			if (![unviewedObjectsArray containsObjectIdenticalTo:inChat]) {
				// Add it, we're rocking now ;)
				[unviewedObjectsArray addObject:inChat];
				[notificationCenter postNotificationName:@"JL_UnviewedOn" object:nil];
			}
		// If they've viewed the content
		} else {
			// If we're tracking this object
			if ([unviewedObjectsArray containsObjectIdenticalTo:inChat]) {
				// Remove it, it's not unviewed anymore
				[unviewedObjectsArray removeObjectIdenticalTo:inChat];
				// If there are no more unviewed objects trigger UI
				if ([unviewedObjectsArray count] == 0) {
					[notificationCenter postNotificationName:@"JL_UnviewedOff" object:nil];
				}
			}
		}
	}
	return nil;
}

@end
