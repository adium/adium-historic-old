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

#import "AIStatus.h"

@class AIService;
@protocol AIListObjectObserver;

//Status State Notifications
#define AIStatusStateArrayChangedNotification	@"AIStatusStateArrayChangedNotification"

//Idle Notifications
#define AIMachineIsIdleNotification				@"AIMachineIsIdleNotification"
#define AIMachineIsActiveNotification			@"AIMachineIsActiveNotification"
#define AIMachineIdleUpdateNotification			@"AIMachineIdleUpdateNotification"

//Preferences
#define PREF_GROUP_SAVED_STATUS					@"Saved Status"
#define KEY_SAVED_STATUS						@"Saved Status Array"

#define KEY_STATUS_NAME							@"Status Name"
#define KEY_STATUS_DESCRIPTION					@"Status Description"
#define	KEY_STATUS_TYPE							@"Status Type"

#define PREF_GROUP_STATUS_PREFERENCES			@"Status Preferences"
#define KEY_STATUS_REPORT_IDLE					@"Report Idle"
#define KEY_STATUS_REPORT_IDLE_INTERVAL			@"Report Idle Interval"

//Built-in names and descriptions, which services should use when they support identical or approximately identical states
#define	STATUS_NAME_AVAILABLE				@"Generic Available"
#define	STATUS_DESCRIPTION_AVAILABLE		AILocalizedString(@"Available", nil)
#define STATUS_NAME_FREE_FOR_CHAT			@"Free for Chat"
#define STATUS_DESCRIPTION_FREE_FOR_CHAT	AILocalizedString(@"Free for chat", nil)
#define STATUS_NAME_AVAILABLE_FRIENDS_ONLY	@"Available for Friends Only"
#define STATUS_DESCRIPTION_AVAILABLE_FRIENDS_ONLY AILocalizedString(@"Available for friends only",nil)

#define	STATUS_NAME_AWAY					@"Generic Away"
#define STATUS_DESCRIPTION_AWAY				AILocalizedString(@"Away", nil)
#define STATUS_NAME_EXTENDED_AWAY			@"Extended Away"
#define STATUS_DESCRIPTION_EXTENDED_AWAY	AILocalizedString(@"Extended away",nil)
#define STATUS_NAME_AWAY_FRIENDS_ONLY		@"Away for Friends Only"
#define STATUS_DESCRIPTION_AWAY_FRIENDS_ONLY AILocalizedString(@"Away for friends only",nil)
#define STATUS_NAME_DND						@"DND"
#define STATUS_DESCRIPTION_DND				AILocalizedString(@"Do not disturb", nil)
#define STATUS_NAME_NOT_AVAILABLE			@"Not Available"
#define STATUS_DESCRIPTION_NOT_AVAILABLE	AILocalizedString(@"Not available", nil)
#define STATUS_NAME_OCCUPIED				@"Occupied"
#define STATUS_DESCRIPTION_OCCUPIED			AILocalizedString(@"Occupied", nil)
#define STATUS_NAME_BRB						@"BRB"
#define STATUS_DESCRIPTION_BRB				AILocalizedString(@"Be right back",nil)
#define STATUS_NAME_BUSY					@"Busy"
#define	STATUS_DESCRIPTION_BUSY				AILocalizedString(@"Busy",nil)
#define STATUS_NAME_PHONE					@"Phone"
#define STATUS_DESCRIPTION_PHONE			AILocalizedString(@"On the phone",nil)
#define STATUS_NAME_LUNCH					@"Lunch"
#define STATUS_DESCRIPTION_LUNCH			AILocalizedString(@"Out to lunch",nil)
#define STATUS_NAME_NOT_AT_HOME				@"Not At Home"
#define STATUS_DESCRIPTION_NOT_AT_HOME		AILocalizedString(@"Not at home",nil)
#define STATUS_NAME_NOT_AT_DESK				@"Not At Desk"
#define STATUS_DESCRIPTION_NOT_AT_DESK		AILocalizedString(@"Not at my desk",nil)
#define STATUS_NAME_NOT_IN_OFFICE			@"Not In Office"
#define STATUS_DESCRIPTION_NOT_IN_OFFICE	AILocalizedString(@"Not in the office",nil)
#define STATUS_NAME_VACATION				@"Vacation"
#define STATUS_DESCRIPTION_VACATION			AILocalizedString(@"On vacation",nil)
#define STATUS_NAME_STEPPED_OUT				@"Stepped Out"
#define STATUS_DESCRIPTION_STEPPED_OUT		AILocalizedString(@"Stepped out",nil)

#define STATUS_NAME_INVISIBLE				@"Invisible"
#define STATUS_DESCRIPTION_INVISIBLE		AILocalizedString(@"Invisible",nil)

#define STATUS_NAME_OFFLINE					@"Offline"

//Current version state ID string
#define STATE_SAVED_STATE					@"State"

//Protocol for state menu display
@protocol StateMenuPlugin <NSObject>
- (void)addStateMenuItems:(NSArray *)menuItemArray;
- (void)removeStateMenuItems:(NSArray *)menuItemArray;
@end

@interface AIStatusController : NSObject<AIListObjectObserver> {
    IBOutlet	AIAdium		*adium;

	//Status states
	NSMutableArray			*stateArray;
	NSMutableArray			*builtInStateArray;
	AIStatus				*_activeStatusState; //Cached active status state
	NSMutableSet			*_allActiveStatusStates; //Cached all active status states
	NSMutableDictionary		*statusDictsByServiceCodeUniqueID[STATUS_TYPES_COUNT];
	NSMutableSet			*builtInStatusTypes[STATUS_TYPES_COUNT];

	NSMutableSet			*accountsToConnect;
	BOOL					isProcessingSelectedGlobalOffline;

	//Machine idle tracking
	BOOL					machineIsIdle;
	double					lastSeenIdle;
	NSTimer					*idleTimer;

	//State menu support
	NSMutableArray			*stateMenuPluginsArray;
	NSMutableDictionary		*stateMenuItemArraysDict;
	int						stateMenuSelectionUpdateDelays;
	NSArray					*_stateArrayForMenuItems;
	
	NSMutableSet			*stateMenuItemsNeedingUpdating;
}

- (void)initController;
- (void)beginClosing;
- (void)closeController;
- (void)finishIniting;
- (NSArray *)stateArray;
- (NSArray *)stateArrayForMenuItems;

- (void)registerStatus:(NSString *)statusName
	   withDescription:(NSString *)description
				ofType:(AIStatusType)type 
			forService:(AIService *)service;
- (NSMenu *)menuOfStatusesForService:(AIService *)service withTarget:(id)target;

- (void)setActiveStatusState:(AIStatus *)state;
- (AIStatus *)activeStatusState;
- (NSSet *)allActiveStatusStates;
- (AIStatusType)activeStatusType;

- (NSString *)descriptionForStateOfStatus:(AIStatus *)statusState;
- (NSString *)defaultStatusNameForType:(AIStatusType)statusType;

//State Editing
- (void)addStatusState:(AIStatus *)state;
- (void)removeStatusState:(AIStatus *)state;
- (void)replaceExistingStatusState:(AIStatus *)oldState withStatusState:(AIStatus *)newState;
- (int)moveStatusState:(AIStatus *)state toIndex:(int)destIndex;

//Machine Idle
- (double)currentMachineIdle;

//State menu support
- (void)registerStateMenuPlugin:(id <StateMenuPlugin>)stateMenuPlugin;
- (void)unregisterStateMenuPlugin:(id <StateMenuPlugin>)stateMenuPlugin;
- (void)rebuildAllStateMenus;
- (void)rebuildAllStateMenusForPlugin:(id <StateMenuPlugin>)stateMenuPlugin;
- (void)updateAllStateMenuSelections;
- (void)updateStateMenuSelectionForPlugin:(id <StateMenuPlugin>)stateMenuPlugin;
- (void)plugin:(id <StateMenuPlugin>)stateMenuPlugin didAddMenuItems:(NSArray *)addedMenuItems;
- (void)removeAllMenuItemsForPlugin:(id <StateMenuPlugin>)stateMenuPlugin;
- (void)setDelayStateMenuSelectionUpdates:(BOOL)shouldDelay;

@end
