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

#import "AIIdleTimeDisplayPlugin.h"
#import "AIIdleTimeDisplayPreferences.h"

@interface AIIdleTimeDisplayPreferences (PRIVATE)
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation AIIdleTimeDisplayPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_ContactList_Contacts);
}
- (NSString *)label{
    return(@"Idle Time Display");
}
- (NSString *)nibName{
    return(@"IdleTimeDisplayPrefs");
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME_DISPLAY];
	
    [checkBox_displayIdle setState:[[preferenceDict objectForKey:KEY_DISPLAY_IDLE_TIME] boolValue]];
    [checkBox_displayIdleOnLeft setState:[[preferenceDict objectForKey:KEY_DISPLAY_IDLE_TIME_ON_LEFT] boolValue]];
    [checkBox_displayIdleOnRight setState:![[preferenceDict objectForKey:KEY_DISPLAY_IDLE_TIME_ON_LEFT] boolValue]];
    [colorWell_idleColor setColor:[[preferenceDict objectForKey:KEY_IDLE_TIME_COLOR] representedColor]];
	
    [self configureControlDimming];
}

//Preference view is closing
- (void)viewWillClose
{
	if([colorWell_idleColor isActive]) [colorWell_idleColor deactivate];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_displayIdle){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DISPLAY_IDLE_TIME
                                              group:PREF_GROUP_IDLE_TIME_DISPLAY];
		
    }else if(sender == checkBox_displayIdleOnLeft){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
											 forKey:KEY_DISPLAY_IDLE_TIME_ON_LEFT
											  group:PREF_GROUP_IDLE_TIME_DISPLAY];
        [checkBox_displayIdleOnRight setState:NSOffState];
		
    }else if(sender == checkBox_displayIdleOnRight){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:NO]
											 forKey:KEY_DISPLAY_IDLE_TIME_ON_LEFT
											  group:PREF_GROUP_IDLE_TIME_DISPLAY];
        [checkBox_displayIdleOnLeft setState:NSOffState];
		
    }else if(sender == colorWell_idleColor){
        [[adium preferenceController] setPreference:[[colorWell_idleColor color] stringRepresentation]
                                             forKey:KEY_IDLE_TIME_COLOR
                                              group:PREF_GROUP_IDLE_TIME_DISPLAY];
		
    }
	
	[super changePreference:sender];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [checkBox_displayIdleOnLeft setEnabled:[checkBox_displayIdle state]];
    [checkBox_displayIdleOnRight setEnabled:[checkBox_displayIdle state]];
    [colorWell_idleColor setEnabled:[checkBox_displayIdle state]];
}

@end
