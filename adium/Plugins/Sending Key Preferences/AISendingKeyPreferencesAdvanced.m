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

#import "AISendingKeyPreferencesAdvanced.h"

@implementation AISendingKeyPreferencesAdvanced

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Sending Keys");
}
- (NSString *)nibName{
    return(@"SendingKeyPrefsAdvanced");
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
    
    [checkBox_sendOnReturn setState:[[preferenceDict objectForKey:@"Send On Return"] intValue]];
    [checkBox_sendOnEnter setState:[[preferenceDict objectForKey:@"Send On Enter"] intValue]];
}

//User changed a preference
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_sendOnReturn){
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender state]]
                                             forKey:@"Send On Return"
                                              group:PREF_GROUP_GENERAL];
        
    } else if(sender == checkBox_sendOnEnter){
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender state]]
                                             forKey:@"Send On Enter"
                                              group:PREF_GROUP_GENERAL];
        
    }    
}

@end

