/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Cocoa/Cocoa.h>

//Notifications
#define AIActiveStateChangedNotification	@"AIActiveStateChangedNotification"
#define AIStateArrayChangedNotification		@"AIStateArrayChangedNotification"
#define AIMachineIsIdleNotification			@"AIMachineIsIdleNotification"
#define AIMachineIsActiveNotification		@"AIMachineIsActiveNotification"
#define AIMachineIdleUpdateNotification		@"AIMachineIdleUpdateNotification"

//Preferences
#define PREF_GROUP_SAVED_STATUS		@"Saved Status"
#define KEY_SAVED_STATUS			@"Saved Status"

//State dictionary keys
#define STATE_TYPE					@"Type"
#define STATE_TITLE					@"Title"
#define STATE_AWAY					@"Away"
#define STATE_AUTO_REPLY			@"AutoReply"
#define STATE_AUTO_REPLY_IS_AWAY	@"AutoReplyIsAway"
#define STATE_AVAILABLE				@"Available"
#define STATE_INVISIBLE				@"Invisible"
#define STATE_IDLE					@"Idle"
#define STATE_IDLE_START			@"IdleStart"
#define STATE_AWAY_MESSAGE			@"AwayMessage"
#define STATE_AVAILABLE_MESSAGE		@"AvailableMessage"
#define STATE_AUTO_REPLY_MESSAGE	@"AutoReplyMessage"

//Current version state ID string
#define STATE_SAVED_STATE			@"State"

//Status keys
#define STATUS_AVAILABLE_MESSAGE 	@"AvailableMessage"
#define STATUS_AWAY_MESSAGE 		@"AwayMessage"
#define STATUS_AUTO_REPLY 			@"AutoReply"
#define STATUS_IDLE_SINCE 			@"IdleSince"
#define STATUS_INVISIBLE 			@"Invisible"


@interface AIStatusController : NSObject {
    IBOutlet	AIAdium		*adium;

	//Status states
	NSMutableArray		*stateArray;
	NSDictionary		*activeState;
	
	//Machine idle tracking
	BOOL				machineIsIdle;
	double				lastSeenIdle;
	NSTimer				*idleTimer;
}

- (void)initController;
- (void)closeController;
- (NSArray *)stateArray;

- (void)setActiveState:(NSDictionary *)state;
- (NSDictionary *)activeState;

- (NSString *)titleForState:(NSDictionary *)state;
- (NSImage *)iconForState:(NSDictionary *)state;

//State Editing
- (void)addState:(NSDictionary *)state;
- (void)removeState:(NSDictionary *)state;
- (void)replaceExistingState:(NSDictionary *)oldState withState:(NSDictionary *)newState;
- (int)moveState:(NSDictionary *)state toIndex:(int)destIndex;

//Machine Idle
- (double)currentMachineIdle;

@end
