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

#import <Adium/AIObject.h>

// Global for DO server name
#define ADIUM_PRESENCE_BROADCAST				@"AIPresenceBroadcast"

@class AIAccountMenu, AIStatusMenu;
@protocol AIChatObserver;

@interface JLPresenceController : AIObject <AIChatObserver>
{
	AIStatusMenu		*statusMenu;
	AIAccountMenu		*accountMenu;
	
	BOOL				unviewedContent;
	BOOL				isOnline;
	
	// Controller specific
	NSMutableArray		*accountMenuItemsArray;
	NSMutableArray		*stateMenuItemsArray;
	NSMutableArray		*unviewedObjectsArray;
	NSMutableArray		*openChatsArray;
	
	NSNotificationCenter *notificationCenter;
}

+ (JLPresenceController *)presenceController;

- (NSArray *)accountMenuItemsArray;
- (NSArray *)stateMenuItemsArray;
- (NSArray *)openChatsArray;

- (void) accountMenuRebuild: (NSArray *) menuItems;
- (void) statusMenuRebuild: (NSArray *) menuItemArray;


- (void) activateAdium: (id) sender;
- (void) switchToChat: (id) sender;
- (void) terminate;

@end
