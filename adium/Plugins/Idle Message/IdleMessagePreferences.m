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

#import "IdleMessagePreferences.h"
#import "IdleMessagePlugin.h"

@implementation IdleMessagePreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Status);
}
- (NSString *)label{
    return(@"Idle Message");
}
- (NSString *)nibName{
    return(@"IdleMessagePrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_IDLE_MESSAGE];
    NSAttributedString	*idleMessage = [NSAttributedString stringWithData:[[owner accountController] propertyForKey:@"IdleMessage" account:nil]];

    //Idle message
    [checkBox_enableIdleMessage setState:[[preferenceDict objectForKey:KEY_IDLE_MESSAGE_ENABLED] boolValue]];
    [[textView_idleMessage textStorage] setAttributedString:idleMessage];
}

// Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_enableIdleMessage) {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_MESSAGE_ENABLED
                                              group:PREF_GROUP_IDLE_MESSAGE];
    }
}

//User finished editing their idle message
- (void)textDidEndEditing:(NSNotification *)notification;
{
    [[owner accountController] setProperty:[[textView_idleMessage textStorage] dataRepresentation] forKey:@"IdleMessage" account:nil];
    [[owner preferenceController] setPreference:[[textView_idleMessage textStorage] dataRepresentation]
                                         forKey:KEY_IDLE_MESSAGE
                                          group:PREF_GROUP_IDLE_MESSAGE];
}

@end
