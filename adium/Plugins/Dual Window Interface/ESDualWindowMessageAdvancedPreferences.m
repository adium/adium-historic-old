//
//  ESDualWindowMessageWindowPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//

#import "ESDualWindowMessageAdvancedPreferences.h"
#import "AIDualWindowInterfacePlugin.h"


@implementation ESDualWindowMessageAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(AILocalizedString(@"Window Preferences",nil));
}
- (NSString *)nibName{
    return(@"DualWindowMessageAdvanced");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:DUAL_INTERFACE_WINDOW_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsTemp = [NSDictionary dictionaryWithObjectsAndKeys:
		[defaultPrefs objectForKey:KEY_ALWAYS_CREATE_NEW_WINDOWS],KEY_ALWAYS_CREATE_NEW_WINDOWS,
		[defaultPrefs objectForKey:KEY_USE_LAST_WINDOW],KEY_USE_LAST_WINDOW,
		[defaultPrefs objectForKey:KEY_AUTOHIDE_TABBAR],KEY_AUTOHIDE_TABBAR,
		[defaultPrefs objectForKey:KEY_ENABLE_INACTIVE_TAB_CLOSE],KEY_ENABLE_INACTIVE_TAB_CLOSE,
		nil];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultsTemp forKey:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	return(defaultsDict);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{

    if(sender == autohide_tabBar){
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:![sender state]]
				      forKey:KEY_AUTOHIDE_TABBAR
				       group:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    }else if(sender == checkBox_allowInactiveClosing){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                      forKey:KEY_ENABLE_INACTIVE_TAB_CLOSE
                                       group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
	
    }

    [self configureControlDimming];
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];

    [autohide_tabBar setState:![[preferenceDict objectForKey:KEY_AUTOHIDE_TABBAR] boolValue]];
    [checkBox_allowInactiveClosing setState:[[preferenceDict objectForKey:KEY_ENABLE_INACTIVE_TAB_CLOSE] boolValue]];
    
    [self configureControlDimming];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{

}

@end



