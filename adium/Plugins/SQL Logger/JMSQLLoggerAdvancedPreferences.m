//
//  JMSQLLoggerAdvancedPreferences.m
//  Adium XCode
//
//  Created by Jeffrey Melloy on Sun Nov 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
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

//Configure the preference view
- (void)viewDidLoad
{
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

//Reflect new preferences in view
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_LOGGING compare:[[notification userInfo] objectForKey:@"Group"]] == 0){
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_LOGGING];

        [self configureControlDimming];
    }
}

//Save changed preference
- (IBAction)changePreference:(id)sender
{
    if(sender == checkbox_enableSQLLogging) {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SQL_LOGGER_ENABLE
                                              group:PREF_GROUP_LOGGING];
    } 
}

@end