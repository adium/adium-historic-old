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

//Status State Notifications
#define AIActiveStatusStateChangedNotification	@"AIActiveStatusStateChangedNotification"
#define AIStatusStateArrayChangedNotification	@"AIStatusStateArrayChangedNotification"

//Idle Notifications
#define AIMachineIsIdleNotification				@"AIMachineIsIdleNotification"
#define AIMachineIsActiveNotification			@"AIMachineIsActiveNotification"
#define AIMachineIdleUpdateNotification			@"AIMachineIdleUpdateNotification"

//Preferences
#define PREF_GROUP_SAVED_STATUS		@"Saved Status"
#define KEY_SAVED_STATUS			@"Saved Status Array"

#define KEY_STATUS_NAME				@"Status Name"
#define KEY_STATUS_DESCRIPTION		@"Status Description"
#define	KEY_STATUS_TYPE				@"Status Type"

//Built-in names and descriptions, which services should use when they support identical or approximately identical states
#define	STATUS_NAME_AVAILABLE				@"Adium: Generic Available"
#define	STATUS_DESCRIPTION_AVAILABLE		AILocalizedString(@"Available", nil)
#define STATUS_NAME_FREE_FOR_CHAT			@"Adium: Free for Chat"
#define STATUS_DESCRIPTION_FREE_FOR_CHAT	AILocalizedString(@"Free for chat", nil)
#define STATUS_NAME_AVAILABLE_FRIENDS_ONLY	@"Adium: Available for Friends Only"
#define STATUS_DESCRIPTION_AVAILABLE_FRIENDS_ONLY AILocalizedString(@"Available for friends only",nil)

#define	STATUS_NAME_AWAY					@"Adium: Generic Away"
#define STATUS_DESCRIPTION_AWAY				AILocalizedString(@"Away", nil)
#define STATUS_NAME_EXTENDED_AWAY			@"Adium: Extended Away"
#define STATUS_DESCRIPTION_EXTENDED_AWAY	AILocalizedString(@"Extended away",nil)
#define STATUS_NAME_AWAY_FRIENDS_ONLY		@"Adium: Away for Friends Only"
#define STATUS_DESCRIPTION_AWAY_FRIENDS_ONLY AILocalizedString(@"Away for friends only",nil)
#define STATUS_NAME_DND						@"Adium: DND"
#define STATUS_DESCRIPTION_DND				AILocalizedString(@"Do not disturb", nil)
#define STATUS_NAME_NOT_AVAILABLE			@"Adium: Not Available"
#define STATUS_DESCRIPTION_NOT_AVAILABLE	AILocalizedString(@"Not available", nil)
#define STATUS_NAME_OCCUPIED				@"Adium: Occupied"
#define STATUS_DESCRIPTION_OCCUPIED			AILocalizedString(@"Occupied", nil)
#define STATUS_NAME_BRB						@"Adium: BRB"
#define STATUS_DESCRIPTION_BRB				AILocalizedString(@"Be right back",nil)
#define STATUS_NAME_BUSY					@"Adium: Busy"
#define	STATUS_DESCRIPTION_BUSY				AILocalizedString(@"Busy",nil)
#define STATUS_NAME_PHONE					@"Adium: Phone"
#define STATUS_DESCRIPTION_PHONE			AILocalizedString(@"On the phone",nil)
#define STATUS_NAME_LUNCH					@"Adium: Lunch"
#define STATUS_DESCRIPTION_LUNCH			AILocalizedString(@"Out to lunch",nil)
#define STATUS_NAME_NOT_AT_HOME				@"Adium: Not At Home"
#define STATUS_DESCRIPTION_NOT_AT_HOME		AILocalizedString(@"Not at home",nil)
#define STATUS_NAME_NOT_AT_DESK				@"Adium: Not At Desk"
#define STATUS_DESCRIPTION_NOT_AT_DESK		AILocalizedString(@"Not at desk",nil)
#define STATUS_NAME_NOT_IN_OFFICE			@"Adium: Not In Office"
#define STATUS_DESCRIPTION_NOT_IN_OFFICE	AILocalizedString(@"Not in office",nil)
#define STATUS_NAME_VACATION				@"Adium: Vacation"
#define STATUS_DESCRIPTION_VACATION			AILocalizedString(@"On vacation",nil)
#define STATUS_NAME_STEPPED_OUT				@"Adium: Stepped Out"
#define STATUS_DESCRIPTION_STEPPED_OUT		AILocalizedString(@"Stepped out",nil)

//Current version state ID string
#define STATE_SAVED_STATE			@"State"

@interface AIStatusController : NSObject {
    IBOutlet	AIAdium		*adium;

	//Status states
	NSMutableArray		*stateArray;
	AIStatus			*activeStatusState;
	
	//Machine idle tracking
	BOOL				machineIsIdle;
	double				lastSeenIdle;
	NSTimer				*idleTimer;
	
	NSMutableDictionary	*statusDictsByServiceCodeUniqueID[STATUS_TYPES_COUNT];
}

- (void)initController;
- (void)closeController;
- (NSArray *)stateArray;

- (void)registerStatus:(NSString *)statusName
	   withDescription:(NSString *)description
				ofType:(AIStatusType)type 
			forService:(AIService *)service;
- (NSMenu *)menuOfStatusesWithTarget:(id)target;

- (void)setActiveStatusState:(AIStatus *)state;
- (AIStatus *)activeStatusState;

- (NSString *)descriptionForStateOfStatus:(AIStatus *)statusState;

//State Editing
- (void)addStatusState:(AIStatus *)state;
- (void)removeStatusState:(AIStatus *)state;
- (void)replaceExistingStatusState:(AIStatus *)oldState withStatusState:(AIStatus *)newState;
- (int)moveStatusState:(AIStatus *)state toIndex:(int)destIndex;

//Machine Idle
- (double)currentMachineIdle;

@end
