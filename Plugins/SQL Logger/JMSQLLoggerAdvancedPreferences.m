//
//  JMSQLLoggerAdvancedPreferences.m
//  Adium
//
//  Created by Jeffrey Melloy on Sun Nov 09 2003.
//

#import "JMSQLLoggerAdvancedPreferences.h"
#import "AISQLLoggerPlugin.h"

@interface JMSQLLoggerAdvancedPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation JMSQLLoggerAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}

- (NSString *)label{
    return(@"SQL Logging");
}
- (NSString *)nibName{
    return(@"SQL_Logger_Prefs");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:SQL_LOGGING_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_SQL_LOGGING];
	return(defaultsDict);
}

//Configure the preference view
- (void)viewDidLoad
{
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SQL_LOGGING];
}

- (void)viewWillClose
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

//Reflect new preferences in view
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	id				tmp;
	
	[checkbox_enableSQLLogging setState:[[prefDict objectForKey:KEY_SQL_LOGGER_ENABLE] boolValue]];
	
	//This ugliness is because setStringValue doesn't like being passed nil
	[text_Username setStringValue:(tmp = [prefDict objectForKey:KEY_SQL_USERNAME]) ? tmp : @""];
	[text_Port setStringValue:(tmp = [prefDict objectForKey:KEY_SQL_PORT]) ? tmp: @""];
	[text_database setStringValue:(tmp = [prefDict objectForKey:KEY_SQL_DATABASE]) ? tmp: @""];
	[text_Password setStringValue:(tmp = [prefDict objectForKey:KEY_SQL_PASSWORD]) ? tmp: @""];
	[text_URL setStringValue:(tmp = [prefDict objectForKey:KEY_SQL_URL]) ? tmp: @""];
}

//Save changed preference
- (IBAction)changePreference:(id)sender
{
    if(sender == checkbox_enableSQLLogging) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SQL_LOGGER_ENABLE
                                              group:PREF_GROUP_SQL_LOGGING];
    } else if (sender == text_Username) {
		[[adium preferenceController] setPreference:[sender stringValue]
                                             forKey:KEY_SQL_USERNAME
                                              group:PREF_GROUP_SQL_LOGGING];
	} else if (sender == text_URL) {
		[[adium preferenceController] setPreference:[sender stringValue]
                                             forKey:KEY_SQL_URL
                                              group:PREF_GROUP_SQL_LOGGING];
	} else if (sender == text_Port) {
		[[adium preferenceController] setPreference:[sender stringValue]
                                             forKey:KEY_SQL_PORT
                                              group:PREF_GROUP_SQL_LOGGING];
	} else if (sender == text_database) {
		[[adium preferenceController] setPreference:[sender stringValue]
                                             forKey:KEY_SQL_DATABASE
                                              group:PREF_GROUP_SQL_LOGGING];
	} else if (sender == text_Password) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SQL_PASSWORD
                                              group:PREF_GROUP_SQL_LOGGING];
	}
}

@end
