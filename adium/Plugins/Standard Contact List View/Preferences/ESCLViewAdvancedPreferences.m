//
//  ESDualWindowMessageWindowPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESCLViewAdvancedPreferences.h"
#import "AISCLViewPlugin.h"


@implementation ESCLViewAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_ContactList);
}
- (NSString *)label{
    return(AILocalizedString(@"Display Preferences",nil));
}
- (NSString *)nibName{
    return(@"CLViewAdvancedPrefs");
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == slider_opacity){
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:[sender floatValue]]
                                             forKey:KEY_SCL_OPACITY
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == checkbox_borderless){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_BORDERLESS
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == slider_rowSpacing){
        [[adium preferenceController] setPreference:[NSNumber numberWithFloat:[sender floatValue]]
                                             forKey:KEY_SCL_SPACING
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];   
    }else if(sender == checkbox_outlineGroups){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_OUTLINE_GROUPS
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == colorWell_outlineGroupsColor){
        [[adium preferenceController] setPreference:[[colorWell_outlineGroupsColor color] stringRepresentation]
                                             forKey:KEY_SCL_OUTLINE_GROUPS_COLOR
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == checkbox_tooltipsInBackground){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_BACKGROUND_TOOLTIPS
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == checkbox_labelAroundContact){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_LABEL_AROUND_CONTACT
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];       
    }
           
    [self configureControlDimming];
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];

    [slider_opacity setFloatValue:[[preferenceDict objectForKey:KEY_SCL_OPACITY] floatValue]];
    [checkbox_borderless setState:[[preferenceDict objectForKey:KEY_SCL_BORDERLESS] boolValue]];
    [slider_rowSpacing setFloatValue:[[preferenceDict objectForKey:KEY_SCL_SPACING] floatValue]];
    [checkbox_outlineGroups setState:[[preferenceDict objectForKey:KEY_SCL_OUTLINE_GROUPS] boolValue]];
    [colorWell_outlineGroupsColor setColor:[[preferenceDict objectForKey:KEY_SCL_OUTLINE_GROUPS_COLOR] representedColor]];
    [checkbox_tooltipsInBackground setState:[[preferenceDict objectForKey:KEY_SCL_BACKGROUND_TOOLTIPS] boolValue]];
    [checkbox_labelAroundContact setState:[[preferenceDict objectForKey:KEY_SCL_LABEL_AROUND_CONTACT] boolValue]];
    
    [self configureControlDimming];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];

    [checkbox_labelAroundContact setEnabled:[[prefDict objectForKey:KEY_SCL_SHOW_LABELS] boolValue]];
    [colorWell_outlineGroupsColor setEnabled:[checkbox_outlineGroups state]];
}

@end



