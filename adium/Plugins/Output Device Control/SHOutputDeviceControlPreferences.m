//
//  SHOutputDeviceControlPreferences.m
//  Adium
//
//  Created by Stephen Holt on Mon Apr 12 2004.

#import "SHOutputDeviceControlPlugin.h"
#import "SHOutputDeviceControlPreferences.h"


@implementation SHOutputDeviceControlPreferences

// Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Other);
}

- (NSString *)label{
    return(@"Sound Output");
}

- (NSString *)nibName{
    return(@"OutputControlPrefs");
}

- (void)viewDidLoad
{
    NSDictionary        *preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
    
    
    if([[preferenceDict objectForKey:KEY_USE_SYSTEM_SOUND_OUTPUT] boolValue] == YES)
        [checkBox_useAlertOutput setState:YES];
    else
        [checkBox_useAlertOutput setState:NO];
    
    //for some reason this will crash Jag. Force disabled for now.
    if(![NSApp isOnPantherOrBetter]){
        [[adium preferenceController] setPreference:NO
                                             forKey:KEY_USE_SYSTEM_SOUND_OUTPUT
                                              group:PREF_GROUP_GENERAL];
                                              
        [checkBox_useAlertOutput setEnabled:NO];
    }
}

- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_useAlertOutput){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_useAlertOutput state]]
                                             forKey:KEY_USE_SYSTEM_SOUND_OUTPUT
                                              group:PREF_GROUP_GENERAL];
    }
}

@end
