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

#import "DCMessagePushPreferences.h"
#import "DCMessagePushPreferencesPlugin.h"

@implementation DCMessagePushPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Push / Pop Messages");
}
- (NSString *)nibName{
    return(@"MessagePushPreferences");
}


//Configure the preference view
- (void)viewDidLoad
{

    //Load prefs dictionary
	NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_PUSH_PREFS];
    
    // Set the values of the checkboxes
    [checkBox_autoPop setState:[[preferenceDict objectForKey:KEY_AUTOPOP] boolValue]];

 }

-(void)changePreference:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                         forKey:KEY_AUTOPOP
                                          group:PREF_GROUP_PUSH_PREFS];
}


//Preference view is closing
- (void)viewWillClose
{
    [view_prefView release]; view_prefView = nil;
}
    

@end
