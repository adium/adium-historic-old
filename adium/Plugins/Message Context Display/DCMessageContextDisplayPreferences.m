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

#import "DCMessageContextDisplayPlugin.h"
#import "DCMessageContextDisplayPreferences.h"


@implementation DCMessageContextDisplayPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Message History");
}
- (NSString *)nibName{
    return(@"MessageContextDisplayPrefs");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:CONTEXT_DISPLAY_DEFAULTS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_CONTEXT_DISPLAY];	
	return(defaultsDict);
}


//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTEXT_DISPLAY];
    
    // Set the values of the controls and fields
    [checkBox_showContext setState:[[preferenceDict objectForKey:KEY_DISPLAY_CONTEXT] boolValue]];
	[textField_linesToDisplay setIntValue:[[preferenceDict objectForKey:KEY_DISPLAY_LINES] intValue]];
	[textField_haveTalkedDays setIntValue:[[preferenceDict objectForKey:KEY_HAVE_TALKED_DAYS] intValue]];
	[textField_haveNotTalkedDays setIntValue:[[preferenceDict objectForKey:KEY_HAVE_NOT_TALKED_DAYS] intValue]];
	[matrix_radioButtons selectCellAtRow:[[preferenceDict objectForKey:KEY_DISPLAY_MODE] intValue] column:0];
	[menu_haveTalkedUnits selectItemAtIndex:[[preferenceDict objectForKey:KEY_HAVE_TALKED_UNITS] intValue]];
	[menu_haveNotTalkedUnits selectItemAtIndex:[[preferenceDict objectForKey:KEY_HAVE_NOT_TALKED_UNITS] intValue]];
		
	[self configureControlDimming];
}

- (IBAction)changePreference:(id)sender
{
	if( sender == checkBox_showContext ) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_DISPLAY_CONTEXT
											  group:PREF_GROUP_CONTEXT_DISPLAY];
		[self configureControlDimming];
		
	} else if( sender == textField_linesToDisplay ) {
		
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
											 forKey:KEY_DISPLAY_LINES
											  group:PREF_GROUP_CONTEXT_DISPLAY];
	} else if( sender == textField_haveTalkedDays ) {
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
											 forKey:KEY_HAVE_TALKED_DAYS
											  group:PREF_GROUP_CONTEXT_DISPLAY];
	} else if (sender == textField_haveNotTalkedDays ) {
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
											 forKey:KEY_HAVE_NOT_TALKED_DAYS
											  group:PREF_GROUP_CONTEXT_DISPLAY];
	} else if( sender == matrix_radioButtons ) {
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender selectedRow]]
											 forKey:KEY_DISPLAY_MODE
											  group:PREF_GROUP_CONTEXT_DISPLAY];
		[self configureControlDimming];
	} else if( sender == menu_haveTalkedUnits ) {
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender indexOfSelectedItem]]
											 forKey:KEY_HAVE_TALKED_UNITS
											  group:PREF_GROUP_CONTEXT_DISPLAY];
	} else if( sender == menu_haveNotTalkedUnits ) {
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender indexOfSelectedItem]]
											 forKey:KEY_HAVE_NOT_TALKED_UNITS
											  group:PREF_GROUP_CONTEXT_DISPLAY];
	}
	
}

- (void)configureControlDimming
{
	
	int selectedRow = [matrix_radioButtons selectedRow];
	
	if( [checkBox_showContext state] ) {
		[textField_linesToDisplay setEnabled:YES];
		[stepper_linesToDisplay setEnabled:YES];
		
		[textField_haveTalkedDays setEnabled:YES];
		[stepper_haveTalkedDays setEnabled:YES];
		[textField_haveNotTalkedDays setEnabled:YES];
		[stepper_haveNotTalkedDays setEnabled:YES];
		
		[menu_haveTalkedUnits setEnabled:YES];
		[menu_haveNotTalkedUnits setEnabled:YES];
		
		[matrix_radioButtons setEnabled:YES];
	}else{
		[textField_linesToDisplay setEnabled:NO];
		[stepper_linesToDisplay setEnabled:NO];
		
		[textField_haveTalkedDays setEnabled:NO];
		[stepper_haveTalkedDays setEnabled:NO];
		[textField_haveNotTalkedDays setEnabled:NO];
		[stepper_haveNotTalkedDays setEnabled:NO];
		
		[menu_haveTalkedUnits setEnabled:NO];
		[menu_haveNotTalkedUnits setEnabled:NO];
		
		[matrix_radioButtons setEnabled:NO];
	}
	
	if( [checkBox_showContext state] ) {
		switch( selectedRow ) {
			case 0:
				[textField_haveTalkedDays setEnabled:NO];
				[stepper_haveTalkedDays setEnabled:NO];
				[textField_haveNotTalkedDays setEnabled:NO];
				[stepper_haveNotTalkedDays setEnabled:NO];
				[menu_haveTalkedUnits setEnabled:NO];
				[menu_haveNotTalkedUnits setEnabled:NO];
				break;
			case 1:
				[textField_haveTalkedDays setEnabled:YES];
				[stepper_haveTalkedDays setEnabled:YES];
				[textField_haveNotTalkedDays setEnabled:NO];
				[stepper_haveNotTalkedDays setEnabled:NO];
				[menu_haveTalkedUnits setEnabled:YES];
				[menu_haveNotTalkedUnits setEnabled:NO];
				break;
			case 2:
				[textField_haveTalkedDays setEnabled:NO];
				[stepper_haveTalkedDays setEnabled:NO];
				[textField_haveNotTalkedDays setEnabled:YES];
				[stepper_haveNotTalkedDays setEnabled:YES];
				[menu_haveTalkedUnits setEnabled:NO];
				[menu_haveNotTalkedUnits setEnabled:YES];
		}
	}
}
@end
