//
//  LNStatusIconsPreferences.m
//  Adium
//
//  Created by Laura Natcher on Wed Oct 01 2003.
//

#import "LNStatusIconsPlugin.h"
#import "LNStatusIconsPreferences.h"

@implementation LNStatusIconsPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Sound);
}
- (NSString *)label{
    return(@"Status Icons Display");
}
- (NSString *)nibName{
    return(@"StatusIconsPrefs");
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_ICONS];
    [checkBox_displayStatusIcons setState:[[preferenceDict objectForKey:KEY_DISPLAY_STATUS_ICONS] boolValue]];
}

- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_displayStatusIcons){
    	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
					     forKey:KEY_DISPLAY_STATUS_ICONS
					      group:PREF_GROUP_STATUS_ICONS];
    }
}

@end
