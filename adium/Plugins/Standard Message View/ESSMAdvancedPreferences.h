//
//  ESSMAdvancedPreferences.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Sun Nov 23 2003.

@interface ESSMAdvancedPreferences : AIPreferencePane {
    IBOutlet    NSSlider        *slider_consolidatedIndentation;
    
    BOOL                        shouldEnableConsolidatedIndentationSlider;
}

@end
