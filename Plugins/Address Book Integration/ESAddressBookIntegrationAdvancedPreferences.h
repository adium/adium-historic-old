//
//  ESAddressBookIntegrationAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 21 2003.
//

@interface ESAddressBookIntegrationAdvancedPreferences : AIPreferencePane {
    IBOutlet    NSTextField             *format_textField;
    IBOutlet	NSPopUpButton           *format_menu;
    IBOutlet    NSButton                *checkBox_syncAutomatic;
    IBOutlet	NSButton                *checkBox_useABImages;
    IBOutlet	NSButton				*checkBox_preferABImages;
	
    IBOutlet    NSButton                *checkBox_useNickName;
    IBOutlet	NSButton                *checkBox_enableImport;
    IBOutlet    NSButton                *checkBox_enableNoteSync;
	
	IBOutlet	NSButton				*checkBox_metaContacts;
}

- (IBAction)changePreference:(id)sender;

@end
