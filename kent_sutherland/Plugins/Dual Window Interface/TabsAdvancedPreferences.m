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

#import "TabsAdvancedPreferences.h"
#import "AIDualWindowInterfacePlugin.h"
#import "AIInterfaceController.h"
#import "AIPreferenceWindowController.h"

@implementation TabsAdvancedPreferences

- (PREFERENCE_CATEGORY)category {
    return AIPref_Advanced;
}
- (NSString *)label {
    return AILocalizedString(@"Tabs", nil);
}
- (NSString *)nibName {
    return @"TabsAdvanced";
}
- (NSImage *)image {
	//return [NSImage imageNamed:@"pref-messages" forClass:[AIPreferenceWindowController class]];
	return nil;
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if (sender == autohide_tabBar) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:![sender state]]
											 forKey:KEY_AUTOHIDE_TABBAR
											  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    } else if (sender == checkBox_allowInactiveClosing) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_ENABLE_INACTIVE_TAB_CLOSE
											  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	} else if (sender == popUp_orientation) {
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_TABBAR_POSITION
											  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	}
}

//Configure the preference view
- (void)viewDidLoad
{
	NSDictionary *prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
    [autohide_tabBar setState:![[prefDict objectForKey:KEY_AUTOHIDE_TABBAR] boolValue]];
    [checkBox_allowInactiveClosing setState:[[prefDict objectForKey:KEY_ENABLE_INACTIVE_TAB_CLOSE] boolValue]];
	[popUp_orientation selectItemWithTag:[[prefDict objectForKey:KEY_TABBAR_POSITION] intValue]];
}

@end
