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

#import "AIAwayStatusWindowPlugin.h"
#import "AIAwayStatusWindowController.h"
#import "AIAwayStatusWindowPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>

@interface AIAwayStatusWindowPlugin (PRIVATE)
- (void)accountPropertiesChanged:(NSNotification *)notification;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIAwayStatusWindowPlugin

- (void)installPlugin
{
    //Register our default preferences
	NSDictionary	*defaults = [NSDictionary dictionaryNamed:AWAY_STATUS_DEFAULT_PREFS forClass:[self class]];
    [[adium preferenceController] registerDefaults:defaults forGroup:PREF_GROUP_AWAY_STATUS_WINDOW];

	//Install our preference view
    preferences = [[AIAwayStatusWindowPreferences preferencePane] retain];

    //Observe pref changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_AWAY_STATUS_WINDOW];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:GROUP_ACCOUNT_STATUS];
}

- (void)uninstallPlugin
{
	[preferences release];
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[AIAwayStatusWindowController closeAwayStatusWindow];
}

//Update our away window when the away status changes
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if(!object){
		//Hide or show the away status window
		if([[[adium preferenceController] preferenceForKey:KEY_SHOW_AWAY_STATUS_WINDOW group:PREF_GROUP_AWAY_STATUS_WINDOW] boolValue] && 
		   [[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS]){
			[AIAwayStatusWindowController openAwayStatusWindow];
		}else{
			[AIAwayStatusWindowController closeAwayStatusWindow];
		}
		
	}
}

@end

