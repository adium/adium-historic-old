//
//  ESContactListWindowHandlingPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Sep 15 2003.
//

@interface ESContactListWindowHandlingPreferences : AIPreferencePane {
	IBOutlet	NSPopUpButton   *window_position_menu;
    IBOutlet	NSButton		*checkBox_hide;
}

- (IBAction)changePreference:(id)sender;

@end
