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
    
    [checkBox_signedOff setState:[[preferenceDict objectForKey:KEY_TAB_SIGNED_OFF_ENABLED] boolValue]];
    [checkBox_signedOn setState:[[preferenceDict objectForKey:KEY_TAB_SIGNED_ON_ENABLED] boolValue]];
    [checkBox_away setState:[[preferenceDict objectForKey:KEY_TAB_AWAY_ENABLED] boolValue]];
    [checkBox_idle setState:[[preferenceDict objectForKey:KEY_TAB_IDLE_ENABLED] boolValue]];
    [checkBox_typing setState:[[preferenceDict objectForKey:KEY_TAB_TYPING_ENABLED] boolValue]];
    [checkBox_unviewedContent setState:[[preferenceDict objectForKey:KEY_TAB_UNVIEWED_ENABLED] boolValue]];
    [checkBox_idleAndAway setState:[[preferenceDict objectForKey:KEY_TAB_IDLE_AWAY_ENABLED] boolValue]];
    [checkBox_unviewedFlash setState:[[preferenceDict objectForKey:KEY_TAB_UNVIEWED_FLASH_ENABLED] boolValue]];
    [checkBox_useCustomColors setState:[[preferenceDict objectForKey:KEY_TAB_USE_CUSTOM_COLORS] boolValue]];

    [self configureControlDimming];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [colorWell_signedOff setEnabled:[checkBox_signedOff state]];
    [colorWell_signedOn setEnabled:[checkBox_signedOn state]];
    [colorWell_away setEnabled:[checkBox_away state]];
    [colorWell_idle setEnabled:[checkBox_idle state]];
    [colorWell_typing setEnabled:[checkBox_typing state]];
    [colorWell_unviewedContent setEnabled:[checkBox_unviewedContent state]];
    [colorWell_idleAndAway setEnabled:[checkBox_idleAndAway state]];
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
        

    }else if(sender == checkBox_signedOff){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_SIGNED_OFF_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_signedOn){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_SIGNED_ON_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_away){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_AWAY_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_idle){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_IDLE_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_typing){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_TYPING_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_unviewedContent){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_UNVIEWED_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_idleAndAway){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_IDLE_AWAY_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_unviewedFlash){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_UNVIEWED_FLASH_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }
    else if(sender == checkBox_useCustomColors){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TAB_USE_CUSTOM_COLORS
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];
        // need to deactivate all controls besides this one & flash (all colors)
        // copy over the CL colors first
        NSLog(@"why didn't my programmer fix me?");
    }
}

@end

