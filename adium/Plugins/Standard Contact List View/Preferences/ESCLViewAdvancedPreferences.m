//
//  ESDualWindowMessageWindowPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
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

- (NSDictionary *)restorablePreferences
{

	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:SCL_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsTemp = [NSDictionary dictionaryWithObjectsAndKeys:
		[defaultPrefs objectForKey:KEY_SCL_BORDERLESS],KEY_SCL_BORDERLESS,
		[defaultPrefs objectForKey:KEY_SCL_SHADOWS],KEY_SCL_SHADOWS,
		[defaultPrefs objectForKey:KEY_SCL_SPACING],KEY_SCL_SPACING,
		[defaultPrefs objectForKey:KEY_SCL_OPACITY],KEY_SCL_OPACITY,
		[defaultPrefs objectForKey:KEY_SCL_OUTLINE_GROUPS],KEY_SCL_OUTLINE_GROUPS,
		[defaultPrefs objectForKey:KEY_SCL_OUTLINE_GROUPS_COLOR],KEY_SCL_OUTLINE_GROUPS_COLOR,
		[defaultPrefs objectForKey:KEY_SCL_BACKGROUND_TOOLTIPS],KEY_SCL_BACKGROUND_TOOLTIPS,
		nil];
								
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultsTemp forKey:PREF_GROUP_CONTACT_LIST_DISPLAY];
	return(defaultsDict);
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
    }else if(sender == checkbox_shadows){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_SHADOWS
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
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_OUTLINE_GROUPS_COLOR
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
    }else if(sender == checkbox_tooltipsInBackground){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_BACKGROUND_TOOLTIPS
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
    [checkbox_shadows setState:[[preferenceDict objectForKey:KEY_SCL_SHADOWS] boolValue]];
    [checkbox_shadows setToolTip:@"Stay close to the Vorlon."];
    
    [slider_rowSpacing setFloatValue:[[preferenceDict objectForKey:KEY_SCL_SPACING] floatValue]];
    [checkbox_outlineGroups setState:[[preferenceDict objectForKey:KEY_SCL_OUTLINE_GROUPS] boolValue]];
    [colorWell_outlineGroupsColor setColor:[[preferenceDict objectForKey:KEY_SCL_OUTLINE_GROUPS_COLOR] representedColor]];
    [checkbox_tooltipsInBackground setState:[[preferenceDict objectForKey:KEY_SCL_BACKGROUND_TOOLTIPS] boolValue]];
    
    [self configureControlDimming];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
//    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
    
    //Outlining of groups uses NSStrokeColorAttributeName, which was introduced in Panther
    if (![NSApp isOnPantherOrBetter]) {
        [checkbox_outlineGroups setEnabled:NO];
        [colorWell_outlineGroupsColor setEnabled:NO];
    } else {
        [colorWell_outlineGroupsColor setEnabled:[checkbox_outlineGroups state]];
    }
}

@end



