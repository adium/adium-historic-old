//
//  AIContactSettingsPane.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 03 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIContactSettingsPane.h"

@interface AIContactSettingsPane (PRIVATE)
- (NSMenu *)encryptionMenu;
@end

@implementation AIContactSettingsPane

//Preference pane properties
- (CONTACT_INFO_CATEGORY)contactInfoCategory{
    return(AIInfo_Settings);
}
- (NSString *)label{
    return(@"Settings");
}
- (NSString *)nibName{
    return(@"ContactSettingsPane");
}

//Configure the preference view
- (void)viewDidLoad
{
	[popUp_encryption setMenu:[self encryptionMenu]];
}

- (NSMenu *)encryptionMenu
{
	NSMenu	*encryptionMenu = [[adium contentController] encryptionMenuNotifyingTarget:nil];
	
	[encryptionMenu addItem:[NSMenuItem separatorItem]];

	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Default",nil)
													  target:nil
													  action:nil
											   keyEquivalent:@""];
	
	[menuItem setTag:EncryptedChat_Default];
	[encryptionMenu addItem:menuItem];
	[menuItem release];
	
	return(encryptionMenu);
}

//Preference view is closing
- (void)viewWillClose
{
	[listObject release]; listObject = nil;
}

//Configure the pane for a list object
- (void)configureForListObject:(AIListObject *)inObject
{
	NSString	*notes;
	NSString	*alias;
	NSNumber	*encryption;

	//Be sure we've set the last changes before changing which object we are editing
	[textField_alias fireImmediately];
	
	//Hold onto the object, using the highest-up metacontact if necessary
	[listObject release];
	listObject = [[[adium contactController] parentContactForListObject:inObject] retain];

	//Fill in the current alias
	if(alias = [listObject preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES ignoreInheritedValues:YES]){
		[textField_alias setStringValue:alias];
	}else{
		[textField_alias setStringValue:@""];
	}
	
	//Current note
    if(notes = [listObject notes]){
        [textField_notes setStringValue:notes];
    }else{
        [textField_notes setStringValue:@""];
    }

	//Encryption
	encryption = [listObject preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE
										group:GROUP_ENCRYPTION];
	if(encryption){
		[popUp_encryption compatibleSelectItemWithTag:[encryption intValue]];		
	}else{
		[popUp_encryption compatibleSelectItemWithTag:EncryptedChat_Default];		
	}
}

//Apply an alias
- (IBAction)setAlias:(id)sender
{
    if(listObject){
        NSString	*alias = [textField_alias stringValue];
		[listObject setDisplayName:alias];
    }
}

//Save contact notes
- (IBAction)setNotes:(id)sender
{
    if(listObject){
        NSString 	*notes = [textField_notes stringValue];
		[listObject setNotes:notes];
    }
}

@end
