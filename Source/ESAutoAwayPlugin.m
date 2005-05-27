//
//  ESAutoAwayPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESAutoAwayPlugin.h"
#import "AIAccountController.h"
#import "AIPreferenceController.h"
#import "AIStatusController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIStatus.h>

/*!
 * @class ESAutoAwayPlugin
 * @brief Provides auto-away functionality for the state system
 *
 * This class implements auto-away.  When the user is inactive for a period of time specified by the user,
 * all accounts which are online and available are set to a specified status state. 
 */
@implementation ESAutoAwayPlugin

/*!
 * @brief Initialize the auto-away system
 *
 * When AIMachineIdleUpdateNotification is posted, check the time idle against the time at which to switch available
 * accounts to a state (as specified by the user in the preferences).
 */
- (void)installPlugin
{
	automaticAwaySet = NO;

	[[adium notificationCenter] addObserver:self
								   selector:@selector(machineIdleUpdate:)
									   name:AIMachineIdleUpdateNotification
									 object:nil];
	[[adium notificationCenter] addObserver:self
								   selector:@selector(machineIsActive:)
									   name:AIMachineIsActiveNotification
									 object:nil];
	
	//Observe preference changes for updating when and how we should automatically change our state
	[[adium preferenceController] registerPreferenceObserver:self 
													forGroup:PREF_GROUP_STATUS_PREFERENCES];	
}

/*!
* Deallocate
 */
- (void)dealloc
{
	[previousStatusStateDict release];
	[[adium notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[super dealloc];
}

/*!
 * @brief Preferences changed
 *
 * Note whether we are supposed to change states after a specified time.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	autoAwayID = [prefDict objectForKey:KEY_STATUS_ATUO_AWAY_STATUS_STATE_ID];

	autoAway = (autoAwayID ? 
				[[prefDict objectForKey:KEY_STATUS_AUTO_AWAY] boolValue] :
				NO);

	autoAwayInterval = [[prefDict objectForKey:KEY_STATUS_AUTO_AWAY_INTERVAL] doubleValue];
}

/*!
* @brief Invoked when machine idle updates
 *
 * Invoked when Adium has an update on machine activity.  If we are not yet idle, and the current length of inactivity
 * is over the threshold, set our accounts to idle status.
 */
- (void)machineIdleUpdate:(NSNotification *)notification
{
	if(!automaticAwaySet && autoAway){
		double	duration = [[[notification userInfo] objectForKey:@"Duration"] doubleValue];
		
		//If we are over the away threshold, set our available accounts to away
		if(duration > autoAwayInterval){
			NSEnumerator	*enumerator;
			AIAccount		*account;
			AIStatus		*targetStatusState;
			
			if(!previousStatusStateDict) previousStatusStateDict = [[NSMutableDictionary alloc] init];
			
			targetStatusState = [[adium statusController] statusStateWithUniqueStatusID:autoAwayID];
			
			if(targetStatusState){
				enumerator = [[[adium accountController] accounts] objectEnumerator];
				while((account = [enumerator nextObject])){
					AIStatus	*currentStatusState = [account statusState];
					if([currentStatusState statusType] == AIAvailableStatusType){
						//Store the state the account is in at present
						[previousStatusStateDict setObject:currentStatusState
													forKey:[NSNumber numberWithUnsignedInt:[account hash]]];
						
						if([account online]){
							//If online, set the state
							[account setStatusState:targetStatusState];
						}else{
							//If offline, set the state without coming online
							[account setStatusStateAndRemainOffline:targetStatusState];
						}
					}
				}
			}

			automaticAwaySet = YES;
		}
	}
}

/*!
* @brief Invoked when machine becomes active
 *
 * Invoked when Adium has an update on machine activity.  Restore any status states we overrode with auto-away.
 */
- (void)machineIsActive:(NSNotification *)notification
{
	if(automaticAwaySet){
		NSEnumerator	*enumerator;
		AIAccount		*account;
		
		enumerator = [[[adium accountController] accounts] objectEnumerator];
		while((account = [enumerator nextObject])){
			AIStatus		*targetStatusState;
			NSNumber		*accountHash = [NSNumber numberWithUnsignedInt:[account hash]];
			
			targetStatusState = [previousStatusStateDict objectForKey:accountHash];
			if(targetStatusState){
				if([account online]){
					//If online, set the state
					[account setStatusState:targetStatusState];
				}else{
					//If offline, set the state without coming online
					[account setStatusStateAndRemainOffline:targetStatusState];
				}
				
				[previousStatusStateDict removeObjectForKey:accountHash];
			}
		}

		automaticAwaySet = NO;
	}
}

@end
