//
//  ESAddressBookIntegrationAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 21 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

@interface ESAddressBookIntegrationAdvancedPreferences : AIPreferencePane {
    IBOutlet    NSTextField             *format_textField;
    IBOutlet	NSPopUpButton           *popUp_formatMenu;
    IBOutlet    NSButton                *checkBox_syncAutomatic;
    IBOutlet	NSButton                *checkBox_useABImages;
    IBOutlet	NSButton				*checkBox_preferABImages;
	
    IBOutlet    NSButton                *checkBox_useNickName;
    IBOutlet	NSButton                *checkBox_enableImport;
    IBOutlet    NSButton                *checkBox_enableNoteSync;
	
	IBOutlet	NSButton				*checkBox_metaContacts;
	
	IBOutlet	AILocalizationTextField	*textField_formatNamesAs;
}

- (IBAction)changePreference:(id)sender;

@end
