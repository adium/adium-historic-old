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

#import "AIAwayStatusWindowPreferences.h"
#import "AIAwayStatusWindowController.h"
#import "AIAwayStatusWindowPlugin.h"

@implementation AIAwayStatusWindowPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Status);
}
- (NSString *)label{
    return(@"Away Status Window");
}
- (NSString *)nibName{
    return(@"AwayStatusWindowPrefs");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:AWAY_STATUS_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_AWAY_STATUS_WINDOW];	
	return(defaultsDict);
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_AWAY_STATUS_WINDOW];
    
    // Set the values of the checkboxes
    [checkBox_showAway setState:[[preferenceDict objectForKey:KEY_SHOW_AWAY_STATUS_WINDOW] boolValue]];
    [checkBox_floatAway setState:[[preferenceDict objectForKey:KEY_FLOAT_AWAY_STATUS_WINDOW] boolValue]];
    [checkBox_hideInBackground setState:[[preferenceDict objectForKey:KEY_HIDE_IN_BACKGROUND_AWAY_STATUS_WINDOW] boolValue]];
	
	[self configureControlDimming];
}

//Apply a changed controls
- (IBAction)changePreference:(id)sender
{
	if(sender == checkBox_showAway){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_SHOW_AWAY_STATUS_WINDOW
											  group:PREF_GROUP_AWAY_STATUS_WINDOW];
		
	}else if(sender == checkBox_floatAway){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_FLOAT_AWAY_STATUS_WINDOW
											  group:PREF_GROUP_AWAY_STATUS_WINDOW];
		
	}else if(sender == checkBox_hideInBackground){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_HIDE_IN_BACKGROUND_AWAY_STATUS_WINDOW
											  group:PREF_GROUP_AWAY_STATUS_WINDOW];
		
	}
	   
	[super changePreference:sender];
}

//Configure control dimming
- (void)configureControlDimming
{
    [checkBox_floatAway setEnabled:[checkBox_showAway state]];
    [checkBox_hideInBackground setEnabled:[checkBox_showAway state]];
}

@end
