//
//  AITabSwitchingPreferences.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 10 2004.
//

#import "AITabSwitchingPreferences.h"
#import "AIDualWindowInterfacePlugin.h"


@implementation AITabSwitchingPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Keys);
}
- (NSString *)label{
    return(AILocalizedString(@"Tab Keys","Label of preference pane for modifying the keys used to switch message tabs"));
}
- (NSString *)nibName{
    return(@"TabSwitchPrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

	[popUp_tabKeys compatibleSelectItemWithTag:[[preferenceDict objectForKey:KEY_TAB_SWITCH_KEYS] intValue]];
}

//User changed a preference
- (IBAction)changePreference:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]]
										 forKey:KEY_TAB_SWITCH_KEYS
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

@end
