/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "Adium.h"
#import "AILoggerAdvancedPreferences.h"
#import "AILoggerPlugin.h"

@interface AILoggerAdvancedPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end;

@implementation AILoggerAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Logging");
}
- (NSString *)nibName{
    return(@"LoggerAdvancedPrefs");
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
        
        [checkBox_enableLogging setState:[[preferenceDict objectForKey:KEY_LOGGER_ENABLE] boolValue]];
        [checkBox_enableFont setState:[[preferenceDict objectForKey:KEY_LOGGER_FONT] boolValue]];
        [checkBox_enableStyle setState:[[preferenceDict objectForKey:KEY_LOGGER_STYLE] boolValue]];
        [checkBox_enableStatus setState:[[preferenceDict objectForKey:KEY_LOGGER_STATUS] boolValue]];
        [checkBox_enableHTML setState:[[preferenceDict objectForKey:KEY_LOGGER_HTML] boolValue]];
        
        [self configureControlDimming];
    }
}

//Save changed preference
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_enableLogging) {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LOGGER_ENABLE
                                              group:PREF_GROUP_LOGGING];
    } else if (sender == checkBox_enableStatus) {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LOGGER_STATUS
                                              group:PREF_GROUP_LOGGING];
    } else if (sender == checkBox_enableFont) {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LOGGER_FONT
                                              group:PREF_GROUP_LOGGING];
    } else if (sender == checkBox_enableStyle) {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LOGGER_STYLE
                                              group:PREF_GROUP_LOGGING];
    } else if (sender == checkBox_enableHTML) {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LOGGER_HTML
                                              group:PREF_GROUP_LOGGING];
    }
}

//Dims style and font if HTML logs are not selected, all if enable logging is not selected.
- (void)configureControlDimming
{
    BOOL    loggingEnabled = [checkBox_enableLogging state];
    BOOL    htmlEnabled = [checkBox_enableHTML state];
    
    [checkBox_enableHTML setEnabled:loggingEnabled];
    [checkBox_enableFont setEnabled:(loggingEnabled && htmlEnabled)];
    [checkBox_enableStyle setEnabled:(loggingEnabled && htmlEnabled)];
    [checkBox_enableStatus setEnabled:loggingEnabled];
}

@end
