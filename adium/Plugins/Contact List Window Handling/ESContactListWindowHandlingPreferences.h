//
//  ESContactListWindowHandlingPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Sep 15 2003.
//

@interface ESContactListWindowHandlingPreferences : AIPreferencePane {
    IBOutlet	NSView		*view_prefView;

    IBOutlet	NSButton	*checkBox_alwaysOnTop;
    IBOutlet	NSButton	*checkBox_hide;
}

//+ (ESContactListWindowHandlingPreferences *)contactListWindowHandlingPreferences;
- (IBAction)changePreference:(id)sender;

@end
