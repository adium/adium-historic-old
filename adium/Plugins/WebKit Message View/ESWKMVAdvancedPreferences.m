//
//  ESWKMVAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Apr 30 2004.
//

#import "ESWKMVAdvancedPreferences.h"

@implementation ESWKMVAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Display Options");
}
- (NSString *)nibName{
    return(@"WebKitAdvancedPreferencesView");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];	
	return(defaultsDict);
}


//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
}

- (IBAction)changePreference:(id)sender
{
	
}

- (void)configureControlDimming
{

}

@end
