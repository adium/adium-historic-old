//
//  AITabSwitchingPreferences.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 10 2004.
//

#import "AIChatCyclingPreferences.h"
#import "AIChatCyclingPlugin.h"

@implementation AIChatCyclingPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Keys);
}
- (NSString *)label{
    return(@"Chat Cycle Keys");
}
- (NSString *)nibName{
    return(@"ChatCyclingPrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CHAT_CYCLING];

	[popUp_tabKeys compatibleSelectItemWithTag:[[preferenceDict objectForKey:KEY_TAB_SWITCH_KEYS] intValue]];
}

//User changed a preference
- (IBAction)changePreference:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]]
										 forKey:KEY_TAB_SWITCH_KEYS
										  group:PREF_GROUP_CHAT_CYCLING];
}

@end
