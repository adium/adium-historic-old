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

#import "AIContactController.h"
#import "ESAddressBookIntegrationAdvancedPreferences.h"
#import "ESAddressBookIntegrationPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AILocalizationTextField.h>

#define ADDRESS_BOOK_FIRST_LAST_OPTION			AILocalizedString(@"First Last","Name display style, e.g. Evan Schoenberg")
#define ADDRESS_BOOK_FIRST_OPTION				AILocalizedString(@"First","Name display style, e.g. Evan")
#define ADDRESS_BOOK_LAST_FIRST_OPTION			AILocalizedString(@"Last, First","Name display style, e.g. Schoenberg, Evan")
#define ADDRESS_BOOK_LAST_FIRST_NO_COMMA_OPTION	AILocalizedString(@"Last First","Name display style, e.g. Schoenberg Evan")

@interface ESAddressBookIntegrationAdvancedPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)configureFormatMenu;
- (IBAction)changeFormat:(id)sender;
@end

/*!
 * @class ESAddressBookIntegrationAdvancedPreferences
 * @brief Provide advanced preferences for the address book integration
 */
@implementation ESAddressBookIntegrationAdvancedPreferences

/*!
 * @brief Category
 */
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced);
}
/*!
 * @brief Label
 */
- (NSString *)label{
    return(AILocalizedString(@"Address Book",nil));
}
/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return(@"AddressBookPrefs");
}
/*!
 * @brief Image for advanced preferences
 */
- (NSImage *)image{
	return [NSImage imageNamed:@"AddressBook" forClass:[self class]];
}

/*!
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	[self configureFormatMenu];
	
	[label_formatNamesAs setLocalizedString:AILocalizedString(@"Format name as:", "Format name as: [popup menu of choices like 'First, Last']")];
	[label_names setLocalizedString:AILocalizedString(@"Names",nil)];
	[label_images setLocalizedString:AILocalizedString(@"Images",nil)];
	[label_contacts setLocalizedString:AILocalizedString(@"Contacts",nil)];
	
	[checkBox_enableImport setLocalizedString:AILocalizedString(@"Import my contacts' names from the Address Book",nil)];
	[checkBox_useNickName setLocalizedString:AILocalizedString(@"Use nickname if available",nil)];
	[checkBox_useABImages setLocalizedString:AILocalizedString(@"Use Address Book images as contacts' icons",nil)];
	[checkBox_preferABImages setLocalizedString:AILocalizedString(@"Even if the contact already has a contact icon",nil)];
	[checkBox_syncAutomatic setLocalizedString:AILocalizedString(@"Overwrite Address Book images with contacts' icons",nil)];
	[checkBox_metaContacts setLocalizedString:AILocalizedString(@"Consolidate contacts listed in the card",nil)];	

	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ADDRESSBOOK];
    
	[checkBox_enableImport setState:[[prefDict objectForKey:KEY_AB_ENABLE_IMPORT] boolValue]];	
	[popUp_formatMenu selectItemAtIndex:[popUp_formatMenu indexOfItemWithTag:[[prefDict objectForKey:KEY_AB_DISPLAYFORMAT] intValue]]];
	[checkBox_useNickName setState:[[prefDict objectForKey:KEY_AB_USE_NICKNAME] boolValue]];
	[checkBox_syncAutomatic setState:[[prefDict objectForKey:KEY_AB_IMAGE_SYNC] boolValue]];
	[checkBox_useABImages setState:[[prefDict objectForKey:KEY_AB_USE_IMAGES] boolValue]];
	[checkBox_enableNoteSync setState:[[prefDict objectForKey:KEY_AB_NOTE_SYNC] boolValue]];
	[checkBox_preferABImages setState:[[prefDict objectForKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES] boolValue]];
	[checkBox_metaContacts setState:[[prefDict objectForKey:KEY_AB_CREATE_METACONTACTS] boolValue]];
	
	[self configureControlDimming];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[super dealloc];
}

/*!
 * @brief Configure control dimming
 */
- (void)configureControlDimming
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ADDRESSBOOK];
	
	BOOL            enableImport = [[prefDict objectForKey:KEY_AB_ENABLE_IMPORT] boolValue];
	BOOL            useImages = [[prefDict objectForKey:KEY_AB_USE_IMAGES] boolValue];
	
	//Use Nick Name and the format menu are irrelevent if importing of names is not enabled
	[checkBox_useNickName setEnabled:enableImport];	
	[popUp_formatMenu setEnabled:enableImport];

	//We will not allow image syncing if AB images are preferred
	//so disable the control and uncheck the box to indicate this to the user
	//dchoby98: why are image import and export linked?
	//[checkBox_syncAutomatic setEnabled:!preferABImages];
	//if (preferABImages)
	//	[checkBox_syncAutomatic setState:NSOffState];
	
	//Disable the image priority checkbox if we aren't using images
	[checkBox_preferABImages setEnabled:useImages];
}

/*!
 * @brief Configure the menu of name formats
 */
- (void)configureFormatMenu
{
    NSMenu		*choicesMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] init] autorelease];
    NSMenuItem		*menuItem;
    
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADDRESS_BOOK_FIRST_LAST_OPTION
																	 target:self
																	 action:@selector(changeFormat:)
															  keyEquivalent:@""] autorelease];
    [menuItem setTag:FirstLast];
    [choicesMenu addItem:menuItem];
    
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADDRESS_BOOK_FIRST_OPTION
																	 target:self
																	 action:@selector(changeFormat:)
															  keyEquivalent:@""] autorelease];
    [menuItem setTag:First];
    [choicesMenu addItem:menuItem];
    
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADDRESS_BOOK_LAST_FIRST_OPTION
																	 target:self
																	 action:@selector(changeFormat:)
															  keyEquivalent:@""] autorelease];
    [menuItem setTag:LastFirst];
    [choicesMenu addItem:menuItem];
	
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ADDRESS_BOOK_LAST_FIRST_NO_COMMA_OPTION
																	 target:self
																	 action:@selector(changeFormat:)
															  keyEquivalent:@""] autorelease];
    [menuItem setTag:LastFirstNoComma];
    [choicesMenu addItem:menuItem];
	
    [popUp_formatMenu setMenu:choicesMenu];
	
    NSRect oldFrame = [popUp_formatMenu frame];
    [popUp_formatMenu sizeToFit];
    [popUp_formatMenu setFrameOrigin:oldFrame.origin];
}

/*!
 * @brief Save changed name format preference
 */
- (IBAction)changeFormat:(id)sender
{
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]]
                                            forKey:KEY_AB_DISPLAYFORMAT
                                            group:PREF_GROUP_ADDRESSBOOK];
}

/*!
 * @brief Save changed preference
 */
- (IBAction)changePreference:(id)sender
{
    if (sender == checkBox_syncAutomatic) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
                                             forKey:KEY_AB_IMAGE_SYNC
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    } else if (sender == checkBox_useABImages) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
                                             forKey:KEY_AB_USE_IMAGES
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    } else if (sender == checkBox_useNickName) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
                                             forKey:KEY_AB_USE_NICKNAME
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    } else if (sender == checkBox_enableImport) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_ENABLE_IMPORT
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    } else if (sender == checkBox_preferABImages) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    } else if (sender == checkBox_enableNoteSync) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_NOTE_SYNC
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    } else if (sender == checkBox_metaContacts) {
		BOOL shouldCreateMetaContacts = ([sender state] == NSOnState);
		
		//If we now shouldn't create metaContacts, clear 'em all... not pretty, but effective.
		if (!shouldCreateMetaContacts) {
			//Delay to the next run loop to give better UI responsiveness
			[[adium contactController] performSelector:@selector(clearAllMetaContactData)
											withObject:nil
											afterDelay:0.0001];
		}

		[[adium preferenceController] setPreference:[NSNumber numberWithBool:shouldCreateMetaContacts]
                                             forKey:KEY_AB_CREATE_METACONTACTS
                                              group:PREF_GROUP_ADDRESSBOOK];
	}

    [self configureControlDimming];
}

@end
