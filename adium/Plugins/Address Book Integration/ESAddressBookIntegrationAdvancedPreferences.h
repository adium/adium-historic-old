//
//  ESAddressBookIntegrationAdvancedPreferences.h
//  Adium XCode
//
//  Created by Evan Schoenberg on Fri Nov 21 2003.
//

#import <Foundation/Foundation.h>


@interface ESAddressBookIntegrationAdvancedPreferences : AIPreferencePane {
    IBOutlet    NSTextField             *format_textField;
    IBOutlet	NSPopUpButton		*format_menu;
    IBOutlet    NSButton                *checkBox_syncAutomatic;
}

- (IBAction)changePreference:(id)sender;

@end
