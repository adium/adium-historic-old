//
//  ESWKMVAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Apr 30 2004.
//

#import "ESWKMVAdvancedPreferences.h"
#import "AIWebKitMessageViewPlugin.h"

@implementation ESWKMVAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(AILocalizedString(@"Display Options","Message Display Options advanced preferences label"));
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
    NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];

	[popUp_nameFormat selectItemWithTag:[[prefDict objectForKey:KEY_WEBKIT_NAME_FORMAT] intValue]];
	[checkBox_customNameFormatting setState:[[prefDict objectForKey:KEY_WEBKIT_USE_NAME_FORMAT] boolValue]];
	[checkBox_combineConsecutive setState:[[prefDict objectForKey:KEY_WEBKIT_COMBINE_CONSECUTIVE] boolValue]];
	
	[self configureControlDimming];
}

- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_combineConsecutive){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_WEBKIT_COMBINE_CONSECUTIVE
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];	
	}else if(sender == checkBox_customNameFormatting){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_WEBKIT_USE_NAME_FORMAT
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	}else if(sender == popUp_nameFormat){
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[[sender selectedItem] tag]]
											 forKey:KEY_WEBKIT_NAME_FORMAT
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	}
	
	[self configureControlDimming];
}

- (void)configureControlDimming
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
	
	[popUp_nameFormat setEnabled:[[prefDict objectForKey:KEY_WEBKIT_USE_NAME_FORMAT] boolValue]];
}

@end
