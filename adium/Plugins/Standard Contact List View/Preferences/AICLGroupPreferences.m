/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AICLGroupPreferences.h"
#import "AISCLOutlineView.h"
#import "AISCLViewPlugin.h"

//Handles the interface interaction, and sets preference values
//The outline view plugin is responsible for reading & setting the preferences, as well as observing changes in them

@implementation AICLGroupPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_ContactList_Groups);
}
- (NSString *)label{
    return(@"General Appearance");
}
- (NSString *)nibName{
    return(@"AICLGroupPrefView");
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];

    [checkBox_customGroupColor setState:[[preferenceDict objectForKey:KEY_SCL_CUSTOM_GROUP_COLOR] boolValue]];
    [colorWell_group setColor:[[preferenceDict objectForKey:KEY_SCL_GROUP_COLOR] representedColor]];
	
    [self configureControlDimming];
}

//Preference view is closing
- (void)viewWillClose
{
	[colorWell_group deactivate];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [colorWell_group setEnabled:[checkBox_customGroupColor state]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == colorWell_group){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_GROUP_COLOR
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];        

    }else if(sender == checkBox_customGroupColor){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_CUSTOM_GROUP_COLOR
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
        
    }else if(sender == colorWell_group){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_GROUP_COLOR
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }
	
	[super changePreference:sender];
}

@end
