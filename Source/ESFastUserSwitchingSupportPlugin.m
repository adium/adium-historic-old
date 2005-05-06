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
//#import "AIContentController.h"
#import "AIPreferenceController.h"
#import "AISoundController.h"
#import "AIStatusController.h"
#import "ESFastUserSwitchingSupportPlugin.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>
#import <Adium/AIAccount.h>

#define FAST_USER_SWITCH_AWAY_STRING AILocalizedString(@"I have switched logged in users. Someone else may be using the computer.","Fast user switching away message")

@interface ESFastUserSwitchingSupportPlugin (PRIVATE)
-(void)switchHandler:(NSNotification*) notification;
@end

extern NSString *NSWorkspaceSessionDidBecomeActiveNotification __attribute__((weak_import));
extern NSString *NSWorkspaceSessionDidResignActiveNotification __attribute__((weak_import));

/*!
 * @class ESFastUserSwitchingSupportPlugin
 * @brief Handle Fast User Switching with a changed status and sound muting
 *
 * When another user logs in via Fast User Switching (OS X 10.3 and above), this plugin sets a status state if an away
 * state is not already set.  It also mutes sounds as per the HIG.
 *
 * At present, this plugin uses a hardcoded away message.
 */
@implementation ESFastUserSwitchingSupportPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{
	setAwayThroughFastUserSwitch = NO;
	setMuteThroughFastUserSwitch = NO;
	monitoringFastUserSwitch = NO;

	NSNotificationCenter *workspaceCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[workspaceCenter addObserver:self
	                    selector:@selector(switchHandler:)
	                        name:NSWorkspaceSessionDidBecomeActiveNotification
	                      object:nil];

	[workspaceCenter addObserver:self
	                    selector:@selector(switchHandler:)
	                        name:NSWorkspaceSessionDidResignActiveNotification
	                      object:nil];

	//Observe preference changes for updating when and how we should automatically change our state
	[[adium preferenceController] registerPreferenceObserver:self
														forGroup:PREF_GROUP_STATUS_PREFERENCES];
}

/*!
 * @brief Preferences changed
 *
 * Note whether we are supposed to change states on FUS.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	fastUserSwitchStatusID = [prefDict objectForKey:KEY_STATUS_FUS_STATUS_STATE_ID];

	monitoringFastUserSwitch = (fastUserSwitchStatusID ?
								[[prefDict objectForKey:KEY_STATUS_FUS] boolValue] :
								NO);
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
	//Clear the fast switch away if we had it up before
	[self switchHandler:nil];

	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

/*!
 * @brief Handle a fast user switch event
 *
 * Calling this with (notification == nil) is the same as when the user switches back.
 * Do not call this method in OS X 10.2.x.
 *
 * @param notification The notification has a name NSWorkspaceSessionDidResignActiveNotification when the user switches away and NSWorkspaceSessionDidBecomeActiveNotification when the user switches back.
 */
-(void)switchHandler:(NSNotification*) notification
{
	if (notification &&
		[[notification name] isEqualToString:NSWorkspaceSessionDidResignActiveNotification]) {
		//Deactivation - go away

		//Go away if we aren't already away, noting the current status states for restoration later
		NSEnumerator	*enumerator;
		AIAccount		*account;
		AIStatus		*targetStatusState;

		if(!previousStatusStateDict) previousStatusStateDict = [[NSMutableDictionary alloc] init];

		targetStatusState = [[adium statusController] statusStateWithUniqueStatusID:fastUserSwitchStatusID];

		if(targetStatusState){
			enumerator = [[[adium accountController] accountArray] objectEnumerator];
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

		//Set a temporary mute if none already exists
		NSNumber *oldTempMute = [[adium preferenceController] preferenceForKey:KEY_SOUND_TEMPORARY_MUTE
																		 group:PREF_GROUP_SOUNDS];
		if (!oldTempMute || ![oldTempMute boolValue]) {
			[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
												 forKey:KEY_SOUND_TEMPORARY_MUTE
												  group:PREF_GROUP_SOUNDS];
			setMuteThroughFastUserSwitch = YES;
		}
	} else {
		//Activation - return from away

		//Remove the away status flag if we set it originally
		NSEnumerator	*enumerator;
		AIAccount		*account;

		enumerator = [[[adium accountController] accountArray] objectEnumerator];
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

		//Clear the temporary mute if necessary
		if (setMuteThroughFastUserSwitch) {
			[[adium preferenceController] setPreference:nil
												 forKey:KEY_SOUND_TEMPORARY_MUTE
												  group:PREF_GROUP_SOUNDS];
		}
	}
}

@end
