//
//  AITabSwitchingPreferences.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 10 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AITabSwitchingPreferences.h"
#import "AIDualWindowInterfacePlugin.h"


@implementation AITabSwitchingPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Keys);
}
- (NSString *)label{
    return(@"Tab Keys");
}
- (NSString *)nibName{
    return(@"TabSwitchPrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

	[popUp_tabKeys selectItemWithTag:[[preferenceDict objectForKey:KEY_TAB_SWITCH_KEYS] intValue]];
}

//User changed a preference
- (IBAction)changePreference:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]]
										 forKey:KEY_TAB_SWITCH_KEYS
										  group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

@end
