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

#import "AILoggerPreferences.h"
#import "AILoggerPlugin.h"

@interface AILoggerPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end;

@implementation AILoggerPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Messages);
}
- (NSString *)label{
    return(@"Z");
}
- (NSString *)nibName{
    return(@"LoggerPrefs");
}

//Setup preferences
- (void)viewDidLoad
{
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

- (void)viewWillClose
{
	[[adium notificationCenter] removeObserver:self];
}

//Reflect new preferences in view
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_LOGGING compare:[[notification userInfo] objectForKey:@"Group"]] == 0){
        NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_LOGGING];

        [checkBox_enableLogging setState:[[preferenceDict objectForKey:KEY_LOGGER_ENABLE] boolValue]];
		[checkBox_enableHTML setState:![[preferenceDict objectForKey:KEY_LOGGER_HTML] boolValue]];
    }
}

//Save changed preference
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_enableLogging) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LOGGER_ENABLE
                                              group:PREF_GROUP_LOGGING];
    } else if(sender == checkBox_enableHTML) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:![sender state]]
                                             forKey:KEY_LOGGER_HTML
                                              group:PREF_GROUP_LOGGING];
    }
}

@end
