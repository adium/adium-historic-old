//
//  ESStatusAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 1/6/06.
//

#import "CBStatusMenuItemPlugin.h"
#import "ESStatusAdvancedPreferences.h"
#import "AIStatusController.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import "AIPreferenceWindowController.h"
#import <AIUtilities/AIImageAdditions.h>

@implementation ESStatusAdvancedPreferences
//Preference pane properties
- (AIPreferenceCategory)category{
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
	} else if (sender == checkBox_statusMenuItemBadge) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_MENU_ITEM_BADGE
											  group:PREF_GROUP_STATUS_MENU_ITEM];
	} else if (sender == checkBox_statusMenuItemFlash) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_MENU_ITEM_FLASH
											  group:PREF_GROUP_STATUS_MENU_ITEM];		
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
	
	prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_MENU_ITEM];
	[checkBox_statusMenuItemBadge setState:[[prefDict objectForKey:KEY_STATUS_MENU_ITEM_BADGE] boolValue]];
	[checkBox_statusMenuItemFlash setState:[[prefDict objectForKey:KEY_STATUS_MENU_ITEM_FLASH] boolValue]];
	
	[label_statusMenuItem setLocalizedString:AILocalizedString(@"Status Menu Item", nil)];
	[checkBox_statusMenuItemBadge setLocalizedString:AILocalizedString(@"Badge the menu item with current status", nil)];
	[checkBox_statusMenuItemFlash setLocalizedString:AILocalizedString(@"Flash when there are unread messages", nil)];
	
	[super viewDidLoad];
}


@end
