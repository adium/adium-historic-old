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

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIDockAccountStatusPlugin.h"
#import "AIDockController.h"
#import "AIStatusController.h"
#import "AIPreferenceController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>
#import <Adium/AIStatus.h>

@interface AIDockAccountStatusPlugin (PRIVATE)
- (BOOL)_accountsWithBoolKey:(NSString *)inKey;
- (BOOL)_accountsWithKey:(NSString *)inKey;
- (void)_updateIconForKey:(NSString *)key;
@end

/*!
 * @class AIDockAccountStatusPlugin
 * @brief Maintain the dock icon state in relation to global account status
 *
 * This class manages the dock icon state via the dockController.  It specifies the icon which should be shown based
 * on an aggregated, global account status.
 */
@implementation AIDockAccountStatusPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{
	//Observe account status changes
	[[adium contactController] registerListObjectObserver:self];

    //Observer preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_GENERAL];
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
    //Remove observers
	[[adium preferenceController] unregisterPreferenceObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief Handle preference changes
 *
 * When the active dock icon changes, call updateListObject:keys:silent: to update its state to the global account state
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if(!key || [key isEqualToString:KEY_ACTIVE_DOCK_ICON]){
		[self updateListObject:nil keys:nil silent:NO];
	}
}

/*!
 * @brief Update the dock icon state in response to an account changing status
 *
 * If one ore more accounts are online, set the Online icon state.  Similarly, handle the Connecting, Away, and Idle
 * dock icon states.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if(inObject == nil || [inObject isKindOfClass:[AIAccount class]]){
		BOOL	shouldUpdateStatus = NO;
		
		if(inObject == nil || [inModifiedKeys containsObject:@"Online"]){
			if([self _accountsWithBoolKey:@"Online"] > 0){
				[[adium dockController] setIconStateNamed:@"Online"];
			}else{
				[[adium dockController] removeIconStateNamed:@"Online"];
			}
			shouldUpdateStatus = YES;
		}
		if(inObject == nil || [inModifiedKeys containsObject:@"Connecting"]){
			if([self _accountsWithBoolKey:@"Connecting"] > 0){
				[[adium dockController] setIconStateNamed:@"Connecting"];
			}else{
				[[adium dockController] removeIconStateNamed:@"Connecting"];
			}
			shouldUpdateStatus = YES;
		}
		
		if(inObject == nil || [inModifiedKeys containsObject:@"StatusState"]){
			shouldUpdateStatus = YES;
		}

		if(inObject == nil || [inModifiedKeys containsObject:@"IdleSince"]){
			if([self _accountsWithKey:@"IdleSince"] > 0){
				[[adium dockController] setIconStateNamed:@"Idle"];
			}else{
				[[adium dockController] removeIconStateNamed:@"Idle"];
			}	
		}
		
		if(shouldUpdateStatus){
			if([[adium statusController] activeStatusType] == AIAwayStatusType){
				[[adium dockController] setIconStateNamed:@"Away"];
			}else{
				[[adium dockController] removeIconStateNamed:@"Away"];
			}
		}
	}

	return(nil);
}

/*!
 * @brief Return if any accounts have a TRUE value for the specified key
 *
 * @param inKey The status key to search on
 * @result YES if any account returns TRUE for the boolean status object for inKey
 */
- (BOOL)_accountsWithBoolKey:(NSString *)inKey
{
    NSEnumerator    *enumerator = [[[adium accountController] accountArray] objectEnumerator];
    AIAccount       *account;

    while((account = [enumerator nextObject])){
		if([account integerStatusObjectForKey:inKey]) return(YES);
    }

    return(NO);
}

/*!
 * @brief Return if any accounts have a non-nil value for the specified key
 *
 * @param inKey The status key to search on
 * @result YES if any account returns a non-nil value for the status object for inKey
 */
- (BOOL)_accountsWithKey:(NSString *)inKey
{
    NSEnumerator    *enumerator = [[[adium accountController] accountArray] objectEnumerator];
    AIAccount       *account;

    while((account = [enumerator nextObject])){
		if([account statusObjectForKey:inKey]) return(YES);
    }

    return(NO);
}

@end


