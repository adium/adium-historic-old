//
//  AIContactSettingsPane.h
//  Adium
//
//  Created by Adam Iser on Thu Jun 03 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface AIContactSettingsPane : AIContactInfoPane {
	IBOutlet	ESDelayedTextField		*textField_alias;
	IBOutlet	ESDelayedTextField		*textField_notes;
	IBOutlet	NSPopUpButton			*popUp_encryption;

	AIListObject		*listObject;
}

- (IBAction)setAlias:(id)sender;
- (IBAction)setNotes:(id)sender;

@end
