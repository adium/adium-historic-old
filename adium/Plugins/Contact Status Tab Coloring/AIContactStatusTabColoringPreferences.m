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

#import "AIContactStatusTabColoringPlugin.h"
#import "AIContactStatusTabColoringPreferences.h"

@implementation AIContactStatusTabColoringPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Status);
}
- (NSString *)label{
    return(@"Tab Status Coloring");
}
- (NSString *)nibName{
    return(@"TabColoringPrefs");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:TAB_COLORING_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_CONTACT_STATUS_COLORING];
	return(defaultsDict);
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_STATUS_COLORING];
    
    [colorWell_away setColor:[[preferenceDict objectForKey:KEY_TAB_AWAY_COLOR] representedColor]];
    [colorWell_idle setColor:[[preferenceDict objectForKey:KEY_TAB_IDLE_COLOR] representedColor]];
    [colorWell_signedOff setColor:[[preferenceDict objectForKey:KEY_TAB_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_signedOn setColor:[[preferenceDict objectForKey:KEY_TAB_SIGNED_ON_COLOR] representedColor]];
    [colorWell_typing setColor:[[preferenceDict objectForKey:KEY_TAB_TYPING_COLOR] representedColor]];
    [colorWell_unviewedContent setColor:[[preferenceDict objectForKey:KEY_TAB_UNVIEWED_COLOR] representedColor]];
    [colorWell_idleAndAway setColor:[[preferenceDict objectForKey:KEY_TAB_IDLE_AWAY_COLOR] representedColor]];
	[colorWell_offline setColor:[[preferenceDict objectForKey:KEY_TAB_OFFLINE_COLOR] representedColor]];

    [checkBox_signedOff setState:[[preferenceDict objectForKey:KEY_TAB_SIGNED_OFF_ENABLED] boolValue]];
    [checkBox_signedOn setState:[[preferenceDict objectForKey:KEY_TAB_SIGNED_ON_ENABLED] boolValue]];
    [checkBox_away setState:[[preferenceDict objectForKey:KEY_TAB_AWAY_ENABLED] boolValue]];
    [checkBox_idle setState:[[preferenceDict objectForKey:KEY_TAB_IDLE_ENABLED] boolValue]];
    [checkBox_typing setState:[[preferenceDict objectForKey:KEY_TAB_TYPING_ENABLED] boolValue]];
    [checkBox_unviewedContent setState:[[preferenceDict objectForKey:KEY_TAB_UNVIEWED_ENABLED] boolValue]];
    [checkBox_idleAndAway setState:[[preferenceDict objectForKey:KEY_TAB_IDLE_AWAY_ENABLED] boolValue]];
    [checkBox_offline setState:[[preferenceDict objectForKey:KEY_TAB_OFFLINE_ENABLED] boolValue]];
    [checkBox_unviewedFlash setState:[[preferenceDict objectForKey:KEY_TAB_UNVIEWED_FLASH_ENABLED] boolValue]];
    [checkBox_useCustomColors setState:[[preferenceDict objectForKey:KEY_TAB_USE_CUSTOM_COLORS] boolValue]];

    [self configureControlDimming];
}

- (void)viewWillClose
{
	[colorWell_away deactivate];
	[colorWell_idle deactivate];
	[colorWell_signedOff deactivate];
	[colorWell_signedOn deactivate];
	[colorWell_typing deactivate];
	[colorWell_unviewedContent deactivate];
	[colorWell_idleAndAway deactivate];
	[colorWell_offline deactivate];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
	BOOL useCustomColors = [checkBox_useCustomColors state];
	
	//Enable/disable checkboxes depending on the "use custom colors" checkbox's state
	[checkBox_signedOff setEnabled:useCustomColors];
    [checkBox_signedOn setEnabled:useCustomColors];
    [checkBox_away setEnabled:useCustomColors];
    [checkBox_idle setEnabled:useCustomColors];
    [checkBox_typing setEnabled:useCustomColors];
    [checkBox_unviewedContent setEnabled:useCustomColors];
    [checkBox_idleAndAway setEnabled:useCustomColors];
	[checkBox_offline setEnabled:useCustomColors];
	
	//Enable/disable color wells depending on their checkbox's state
    [colorWell_signedOff setEnabled:([checkBox_signedOff state] && useCustomColors)];
    [colorWell_signedOn setEnabled:([checkBox_signedOn state] && useCustomColors)];
    [colorWell_away setEnabled:([checkBox_away state] && useCustomColors)];
    [colorWell_idle setEnabled:([checkBox_idle state] && useCustomColors)];
    [colorWell_typing setEnabled:([checkBox_typing state] && useCustomColors)];
    [colorWell_unviewedContent setEnabled:([checkBox_unviewedContent state] && useCustomColors)];
    [colorWell_idleAndAway setEnabled:([checkBox_idleAndAway state] && useCustomColors)];
	[colorWell_offline setEnabled:([checkBox_offline state] && useCustomColors)];

}

//Save changed preference
- (IBAction)changePreference:(id)sender
{
    if(sender == colorWell_away){
        [[adium preferenceController] setPreference:[[colorWell_away color] stringRepresentation]
                                             forKey:KEY_TAB_AWAY_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        
    }else if(sender == colorWell_idle){
        [[adium preferenceController] setPreference:[[colorWell_idle color] stringRepresentation]
                                             forKey:KEY_TAB_IDLE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        
    }else if(sender == colorWell_signedOff){
        [[adium preferenceController] setPreference:[[colorWell_signedOff color] stringRepresentation]
                                             forKey:KEY_TAB_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        
    }else if(sender == colorWell_signedOn){
        [[adium preferenceController] setPreference:[[colorWell_signedOn color] stringRepresentation]
                                             forKey:KEY_TAB_SIGNED_ON_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        
    }else if(sender == colorWell_typing){
        [[adium preferenceController] setPreference:[[colorWell_typing color] stringRepresentation]
                                             forKey:KEY_TAB_TYPING_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
	
    }else if(sender == colorWell_unviewedContent){
        [[adium preferenceController] setPreference:[[colorWell_unviewedContent color] stringRepresentation]
                                             forKey:KEY_TAB_UNVIEWED_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_idleAndAway){
        [[adium preferenceController] setPreference:[[colorWell_idleAndAway color] stringRepresentation]
                                             forKey:KEY_TAB_IDLE_AWAY_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        
	}else if(sender == colorWell_offline){
        [[adium preferenceController] setPreference:[[colorWell_offline color] stringRepresentation]
                                             forKey:KEY_TAB_OFFLINE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
		
    }else if(sender == checkBox_signedOff){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_SIGNED_OFF_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
	
    }else if(sender == checkBox_signedOn){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_SIGNED_ON_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == checkBox_away){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_AWAY_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == checkBox_idle){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_IDLE_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == checkBox_typing){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_TYPING_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
	
    }else if(sender == checkBox_unviewedContent){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_UNVIEWED_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == checkBox_idleAndAway){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_IDLE_AWAY_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
		
	}else if(sender == checkBox_offline){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_OFFLINE_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        
		
    }else if(sender == checkBox_unviewedFlash){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_UNVIEWED_FLASH_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
    }
    else if(sender == checkBox_useCustomColors){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_USE_CUSTOM_COLORS
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
    }
	
	//Always validate -- no harm done if we didn't need to
	[self configureControlDimming];
}


@end

