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

#import "AIAutoIdlePlugin.h"
#import "AIPreferenceController.h"
#import "AIStatusController.h"
#import <Adium/AIAccount.h>

//#define IDLE_TIME_PREFERENCE	(60*10)  //XXX - This needs to be a preference(?), seconds before auto-idle. -ai.

/*!
 * @class AIAutoIdlePlugin
 * @brief Provides auto-idle functionality for the state system
 *
 * This class implements auto-idling.  When the user is inactive for a period of time, the idle status flag is set
 * for all accounts.  Once the user returns this flag is removed.  This plugin works independently of the state
 * system, so this automatic idle flag won't interfere with the currently active state.
 */
@implementation AIAutoIdlePlugin

/*!
 * @brief Initialize the auto-idle system
 *
 * Initialize the auto-idle system to monitor
 *
 * Initialize the auto-reply system to monitor account status.  When an account auto-reply flag is set we begin to
 * monitor chat messaging and auto-reply as necessary.
 */
- (void)installPlugin
{
	automaticIdleSet = NO;
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(machineIdleUpdate:)
									   name:AIMachineIdleUpdateNotification
									 object:nil];
	[[adium notificationCenter] addObserver:self
								   selector:@selector(machineIsActive:)
									   name:AIMachineIsActiveNotification
									 object:nil];
	
	//Observe preference changes for updating sending key settings
	[[adium preferenceController] registerPreferenceObserver:self 
													forGroup:PREF_GROUP_STATUS_PREFERENCES];	
}

/*!
 * Deallocate
 */
- (void)dealloc
{
	[automaticIdleDate release];
	[[adium notificationCenter] removeObserver:self];

	[super dealloc];
}

/*
 * @brief Preferences changed
 *
 * Note whether we are supposed to report idle time, and, if so, after how much time.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	reportIdleTime = [[prefDict objectForKey:KEY_STATUS_REPORT_IDLE] boolValue];
	idleTimeInterval = [[prefDict objectForKey:KEY_STATUS_REPORT_IDLE_INTERVAL] doubleValue];	
}

/*!
 * @brief Invoked when machine idle updates
 *
 * Invoked when Adium has an update on machine activity.  If we are not yet idle, and the current length of inactivity
 * is over the threshold, set our accounts to idle status.
 */
- (void)machineIdleUpdate:(NSNotification *)notification
{
	if(!automaticIdleSet && reportIdleTime){
		double	duration = [[[notification userInfo] objectForKey:@"Duration"] doubleValue];
		
		if(duration > idleTimeInterval){
			//If we are over the idle threshold, set our accounts to idle
			automaticIdleSet = YES;
			automaticIdleDate = [[[notification userInfo] objectForKey:@"IdleSince"] retain];
			[[adium preferenceController] setPreference:automaticIdleDate
												 forKey:@"IdleSince"
												  group:GROUP_ACCOUNT_STATUS];
		}
	}
}

/*!
 * @brief Invoked when machine becomes active
 *
 * Invoked when Adium has an update on machine activity.  If we are currently idle, set our accounts back to active.
 * This method checks to make sure that the current idle is the one we've set.  If it is not, we do not remove the
 * idle time (It's not nice to remove an idle you didn't set).
 */
- (void)machineIsActive:(NSNotification *)notification
{
	if(automaticIdleSet){
		//Only clear the idle status if it's the one we set, otherwise it's not ours to touch.
		if([[adium preferenceController] preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS] == automaticIdleDate){
			[[adium preferenceController] setPreference:nil
												 forKey:@"IdleSince"
												  group:GROUP_ACCOUNT_STATUS];
		}
		
		//Clean up
		[automaticIdleDate release];
		automaticIdleDate = nil;
		automaticIdleSet = NO;
	}
}

@end
