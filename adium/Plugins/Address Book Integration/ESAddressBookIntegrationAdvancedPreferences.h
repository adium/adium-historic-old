//
//  ESAddressBookIntegrationAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 21 2003.
//

@interface ESAddressBookIntegrationAdvancedPreferences : AIPreferencePane {
    IBOutlet    NSTextField             *format_textField;
    IBOutlet	NSPopUpButton			*format_menu;
    IBOutlet    NSButton				*checkBox_syncAutomatic;
	IBOutlet	NSButton				*checkBox_useABImages;
	IBOutlet	NSButtonCell			*checkBox_preferABImages;
	
    IBOutlet    NSButton                *checkBox_useNickName;
	IBOutlet	NSButton				*checkBox_enableImport;
}

- (IBAction)changePreference:(id)sender;

@end
