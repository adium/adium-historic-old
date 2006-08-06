//
//  ESStatusAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 1/6/06.
//

#import "ESStatusAdvancedPreferences.h"
#import "AIStatusController.h"
#import "AIPreferenceController.h"
#import "AIPreferenceWindowController.h"
#import <AIUtilities/AIImageAdditions.h>

@implementation ESStatusAdvancedPreferences
//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return AIPref_Advanced;
}
- (NSString *)label{
    return AILocalizedString(@"Status",nil);
}
- (NSString *)nibName{
    return @"StatusPreferencesAdvanced";
}
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-status" forClass:[AIPreferenceWindowController class]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_statusWindowHideInBackground) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_STATUS_WINDOW_HIDE_IN_BACKGROUND
											  group:PREF_GROUP_STATUS_PREFERENCES];		
		
	} else if (sender == checkBox_statusWindowAlwaysOnTop) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_STATUS_WINDOW_ON_TOP
											  group:PREF_GROUP_STATUS_PREFERENCES];
	}
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*prefDict;
	
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_PREFERENCES];
	[checkBox_statusWindowHideInBackground setState:[[prefDict objectForKey:KEY_STATUS_STATUS_WINDOW_HIDE_IN_BACKGROUND] boolValue]];
	[checkBox_statusWindowAlwaysOnTop setState:[[prefDict objectForKey:KEY_STATUS_STATUS_WINDOW_ON_TOP] boolValue]];
	
	[label_statusWindow setLocalizedString:AILocalizedString(@"Away Status Window", nil)];
	[checkBox_statusWindowHideInBackground setLocalizedString:AILocalizedString(@"Hide the status window when Adium is not active", nil)];
	[checkBox_statusWindowAlwaysOnTop setLocalizedString:AILocalizedString(@"Show the status window above other windows", nil)];
	
	[super viewDidLoad];
}


@end
