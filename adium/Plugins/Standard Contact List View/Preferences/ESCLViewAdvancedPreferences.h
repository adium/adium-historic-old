//
//  ESDualWindowMessageWindowPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//

@interface ESCLViewAdvancedPreferences : AIPreferencePane {
    IBOutlet    NSSlider        *slider_opacity;
    IBOutlet	NSButton	*checkbox_borderless;
    IBOutlet    NSSlider        *slider_rowSpacing;
    IBOutlet    NSButton        *checkbox_outlineGroups;
    IBOutlet    NSColorWell     *colorWell_outlineGroupsColor;
    IBOutlet    NSButton        *checkbox_tooltipsInBackground;
    IBOutlet    NSButton        *checkbox_labelAroundContact;
}

@end