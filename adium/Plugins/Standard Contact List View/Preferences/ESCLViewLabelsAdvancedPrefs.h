//
//  ESDualWindowMessageWindowPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//

@interface ESCLViewLabelsAdvancedPrefs : AIPreferencePane {
    //General
    IBOutlet    NSSlider        *slider_labelOpacity;
    IBOutlet    NSButton        *checkbox_outlineLabels;
    IBOutlet    NSButton        *checkbox_labelAroundContact;
	IBOutlet	NSButton		*checkbox_useGradient;
    
    //Groups
    IBOutlet    NSButton        *checkbox_labelGroups;
    IBOutlet    NSColorWell     *colorWell_labelGroupsColor;
}

@end