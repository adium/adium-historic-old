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
#import "AILoggerPreferences.h"
#import "AILoggerPlugin.h"

@interface AILoggerPreferences (PRIVATE)
- (void)autoDim;
@end;

@implementation AILoggerPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Messages_Sending);
}
- (NSString *)label{
    return(@"G");
}
- (NSString *)nibName{
    return(@"LoggerPrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_LOGGING];

    [checkBox_enableLogging setState:[[preferenceDict objectForKey:KEY_LOGGER_ENABLE] boolValue]];
    [checkBox_enableFont setState:[[preferenceDict objectForKey:KEY_LOGGER_FONT] boolValue]];
    [checkBox_enableStyle setState:[[preferenceDict objectForKey:KEY_LOGGER_STYLE] boolValue]];
    [checkBox_enableStatus setState:[[preferenceDict objectForKey:KEY_LOGGER_STATUS] boolValue]];
    [checkBox_enableHTML setState:[[preferenceDict objectForKey:KEY_LOGGER_HTML] boolValue]];

    [self autoDim];
}

//
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
    [self autoDim];
}

//Dims style and font if HTML logs are not selected, all if enable logging is not selected.
- (void) autoDim {
    if(![checkBox_enableLogging state]) {
        [checkBox_enableFont setEnabled:NO];
        [checkBox_enableStyle setEnabled:NO];
        [checkBox_enableStatus setEnabled:NO];
        [checkBox_enableHTML setEnabled:NO];
    } else {
        [checkBox_enableStatus setEnabled:YES];
        [checkBox_enableHTML setEnabled:YES];
    }

    if(![checkBox_enableHTML state]) {
        [checkBox_enableFont setEnabled:NO];
        [checkBox_enableStyle setEnabled:NO];
    } else {
        [checkBox_enableFont setEnabled:YES];
        [checkBox_enableStyle setEnabled:YES];
    }
}
@end
