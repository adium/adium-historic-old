//
//  GBiTunerPreferences.m
//  Adium XCode
//
//  Created by Gregory Barchard on Mon Jan 05 2004.
//
#import "GBiTunerPlugin.h"
#import "GBiTunerPreferences.h"

@implementation GBiTunerPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Other);
}
- (NSString *)label{
    return(@"iTunes Integration");
}
- (NSString *)nibName{
    return(@"GBiTuner");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:ITUNER_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_ITUNER];
	return(defaultsDict);
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ITUNER];
	
	[checkBox_enable setState:[[preferenceDict objectForKey:@"enabled"] boolValue]];
}

//User changed a preference
- (IBAction)changePreference:(id)sender
{
	if(sender == checkBox_enable){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
									  forKey:@"enabled"
									  group:PREF_GROUP_ITUNER];
	}
}

@end
