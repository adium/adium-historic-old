/*
 *  AIStatusControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Adium/AIControllerProtocol.h>
#import <Adium/AIStatus.h>

@class AIStatus;

//Status State Notifications
#define AIStatusStateArrayChangedNotification	@"AIStatusStateArrayChangedNotification"
#define AIStatusActiveStateChangedNotification	@"AIStatusActiveStateChangedNotification"

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
#define	KEY_STATUS_AUTO_AWAY					@"Auto Away"
#define KEY_STATUS_AUTO_AWAY_STATUS_STATE_ID	@"Auto Away Status State ID"
#define KEY_STATUS_FUS							@"Fast User Switching Auto Away"
#define KEY_STATUS_FUS_STATUS_STATE_ID			@"Fast User Switching Status State ID"
#define KEY_STATUS_SS							@"ScreenSaver Auto Away"
#define KEY_STATUS_SS_STATUS_STATE_ID			@"ScreenSaver Status State ID"
#define KEY_STATUS_AUTO_AWAY_INTERVAL			@"Auto Away Interval"

#define KEY_STATUS_SHOW_STATUS_WINDOW				@"Show Status Window"
#define KEY_STATUS_STATUS_WINDOW_ON_TOP				@"Status Window Always On Top"
#define KEY_STATUS_STATUS_WINDOW_HIDE_IN_BACKGROUND	@"Status Window Hide in Background"

//Built-in names and descriptions, which services should use when they support identical or approximately identical states
#define	STATUS_NAME_AVAILABLE				@"Generic Available"
#define STATUS_NAME_FREE_FOR_CHAT			@"Free for Chat"
#define STATUS_NAME_AVAILABLE_FRIENDS_ONLY	@"Available for Friends Only"

#define	STATUS_NAME_AWAY					@"Generic Away"
#define STATUS_NAME_EXTENDED_AWAY			@"Extended Away"
#define STATUS_NAME_AWAY_FRIENDS_ONLY		@"Away for Friends Only"
#define STATUS_NAME_DND						@"DND"
#define STATUS_NAME_NOT_AVAILABLE			@"Not Available"
#define STATUS_NAME_OCCUPIED				@"Occupied"
#define STATUS_NAME_BRB						@"BRB"
#define STATUS_NAME_BUSY					@"Busy"
#define STATUS_NAME_PHONE					@"Phone"
#define STATUS_NAME_LUNCH					@"Lunch"
#define STATUS_NAME_NOT_AT_HOME				@"Not At Home"
#define STATUS_NAME_NOT_AT_DESK				@"Not At Desk"
#define STATUS_NAME_NOT_IN_OFFICE			@"Not In Office"
#define STATUS_NAME_VACATION				@"Vacation"
#define STATUS_NAME_STEPPED_OUT				@"Stepped Out"

#define STATUS_NAME_INVISIBLE				@"Invisible"

#define STATUS_NAME_OFFLINE					@"Offline"

//Current version state ID string
#define STATE_SAVED_STATE					@"State"

@protocol AIStatusController <AIController>
- (NSNumber *)nextUniqueStatusID;

- (void)registerStatus:(NSString *)statusName
	   withDescription:(NSString *)description
				ofType:(AIStatusType)type 
			forService:(AIService *)service;
- (NSMenu *)menuOfStatusesForService:(AIService *)service withTarget:(id)target;

- (NSArray *)flatStatusSet;
- (NSArray *)sortedFullStateArray;
- (AIStatus *)offlineStatusState;
- (AIStatus *)statusStateWithUniqueStatusID:(NSNumber *)uniqueStatusID;

- (void)setActiveStatusState:(AIStatus *)state;
- (void)setDelayStatusMenuRebuilding:(BOOL)shouldDelay;
- (void)applyState:(AIStatus *)statusState toAccounts:(NSArray *)accountArray;
- (AIStatus *)activeStatusState;
- (NSSet *)allActiveStatusStates;
- (AIStatusType)activeStatusTypeTreatingInvisibleAsAway:(BOOL)invisibleIsAway;
- (NSSet *)activeUnavailableStatusesAndType:(AIStatusType *)activeUnvailableStatusType 
								   withName:(NSString **)activeUnvailableStatusName
			 allOnlineAccountsAreUnvailable:(BOOL *)allOnlineAccountsAreUnvailable;
- (AIStatus *)defaultInitialStatusState;

- (NSString *)descriptionForStateOfStatus:(AIStatus *)statusState;
- (NSString *)localizedDescriptionForCoreStatusName:(NSString *)statusName;
- (NSString *)localizedDescriptionForStatusName:(NSString *)statusName statusType:(AIStatusType)statusType;
- (NSString *)defaultStatusNameForType:(AIStatusType)statusType;

//State Editing
- (void)addStatusState:(AIStatus *)state;
- (void)removeStatusState:(AIStatus *)state;
- (void)statusStateDidSetUniqueStatusID;

//State menu support
- (void)setDelayActiveStatusUpdates:(BOOL)shouldDelay;
- (BOOL)removeIfNecessaryTemporaryStatusState:(AIStatus *)originalState;
- (AIStatusGroup *)rootStateGroup;

- (void)savedStatusesChanged;
- (void)statusStateDidSetUniqueStatusID;
@end
