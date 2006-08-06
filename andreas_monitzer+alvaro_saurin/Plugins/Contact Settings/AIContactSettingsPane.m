/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactSettingsPane.h"
#import "AIContentController.h"
#import <AIUtilities/AIDelayedTextField.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringFormatter.h>
#import <Adium/AIChat.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>

@interface AIContactSettingsPane (PRIVATE)
- (void)localizeTitles;
@end

@implementation AIContactSettingsPane

//Preference pane properties
- (CONTACT_INFO_CATEGORY)contactInfoCategory{
    return AIInfo_Settings;
}
- (NSString *)nibName{
    return @"ContactSettingsPane";
}

//Configure the preference view
- (void)viewDidLoad
{
	[popUp_encryption setMenu:[[adium contentController] encryptionMenuNotifyingTarget:self
																		   withDefault:YES]];
	[[popUp_encryption menu] setAutoenablesItems:NO];

	NSMutableCharacterSet *noNewlinesCharacterSet;
	noNewlinesCharacterSet = [[[NSCharacterSet characterSetWithCharactersInString:@""] invertedSet] mutableCopy];
	[noNewlinesCharacterSet removeCharactersInString:@"\n\r"];
	[textField_alias setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:noNewlinesCharacterSet
																				length:0 /* No length limit */
																		 caseSensitive:NO
																		  errorMessage:nil]];
	[noNewlinesCharacterSet release];

	[self localizeTitles];
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
	listObject = ([inObject isKindOfClass:[AIListContact class]] ?
				  [(AIListContact *)inObject parentContact] :
				  inObject);
	[listObject retain];

	//Fill in the current alias
	if ((alias = [listObject preferenceForKey:@"Alias" group:PREF_GROUP_ALIASES ignoreInheritedValues:YES])) {
		[textField_alias setStringValue:alias];
	} else {
		[textField_alias setStringValue:@""];
	}
	
	//Current note
    if ((notes = [listObject notes])) {
        [textField_notes setStringValue:notes];
    } else {
        [textField_notes setStringValue:@""];
    }

	//Encryption
	encryption = [listObject preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE
										group:GROUP_ENCRYPTION];
	if (encryption) {
		[popUp_encryption compatibleSelectItemWithTag:[encryption intValue]];		
	} else {
		[popUp_encryption compatibleSelectItemWithTag:EncryptedChat_Default];		
	}
}

//Apply an alias
- (IBAction)setAlias:(id)sender
{
    if (listObject) {
        NSString	*alias = [textField_alias stringValue];
		[listObject setDisplayName:alias];
    }
}

//Save contact notes
- (IBAction)setNotes:(id)sender
{
    if (listObject) {
        NSString 	*notes = [textField_notes stringValue];
		[listObject setNotes:notes];
    }
}

- (IBAction)selectedEncryptionPreference:(id)sender
{
	[listObject setPreference:[NSNumber numberWithInt:[sender tag]]
					   forKey:KEY_ENCRYPTED_CHAT_PREFERENCE
						group:GROUP_ENCRYPTION];
}

- (void)localizeTitles
{
	[label_alias setLocalizedString:AILocalizedString(@"Alias:","Label beside the field for a contact's alias in the settings tab of the Get Infow indow")];
	[label_notes setLocalizedString:AILocalizedString(@"Notes:","Label beside the field for contact notes in the Settings tab of the Get Info window")];
	[label_encryption setLocalizedString:AILocalizedString(@"Encryption:","Label besides the field for contact encryption settings")];
}

@end
