//
//  ESAddressBookIntegrationAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Nov 21 2003.
//

#import "ESAddressBookIntegrationAdvancedPreferences.h"
#import "ESAddressBookIntegrationPlugin.h"

#define ADDRESS_BOOK_FIRST_LAST_OPTION			AILocalizedString(@"First Last","Name display style, e.g. Evan Schoenberg")
#define ADDRESS_BOOK_FIRST_OPTION				AILocalizedString(@"First","Name display style, e.g. Evan")
#define ADDRESS_BOOK_LAST_FIRST_OPTION			AILocalizedString(@"Last, First","Name display style, e.g. Schoenberg, Evan")
#define ADDRESS_BOOK_LAST_FIRST_NO_COMMA_OPTION	AILocalizedString(@"Last, First","Name display style, e.g. Schoenberg Evan")

@interface ESAddressBookIntegrationAdvancedPreferences (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)configureFormatMenu;
- (IBAction)changeFormat:(id)sender;
@end

@implementation ESAddressBookIntegrationAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_ContactList);
}
- (NSString *)label{
    return(AILocalizedString(@"Address Book",nil));
}
- (NSString *)nibName{
    return(@"AddressBookPrefs");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:AB_DISPLAYFORMAT_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_ADDRESSBOOK];
	return(defaultsDict);
}

//Configure the preference view
- (void)viewDidLoad
{
	[self configureFormatMenu];
	
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ADDRESSBOOK];
    
	[checkBox_enableImport setState:[[prefDict objectForKey:KEY_AB_ENABLE_IMPORT] boolValue]];	
	[format_menu selectItemAtIndex:[format_menu indexOfItemWithTag:[[prefDict objectForKey:KEY_AB_DISPLAYFORMAT] intValue]]];
	[checkBox_useNickName setState:[[prefDict objectForKey:KEY_AB_USE_NICKNAME] boolValue]];
	[checkBox_syncAutomatic setState:[[prefDict objectForKey:KEY_AB_IMAGE_SYNC] boolValue]];
	[checkBox_useABImages setState:[[prefDict objectForKey:KEY_AB_USE_IMAGES] boolValue]];
	[checkBox_enableNoteSync setState:[[prefDict objectForKey:KEY_AB_NOTE_SYNC] boolValue]];
	[checkBox_preferABImages setState:[[prefDict objectForKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES] boolValue]];
	[checkBox_metaContacts setState:[[prefDict objectForKey:KEY_AB_CREATE_METACONTACTS] boolValue]];
	
	[self configureControlDimming];
}

- (void)configureControlDimming
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ADDRESSBOOK];
	
	BOOL            enableImport = [[prefDict objectForKey:KEY_AB_ENABLE_IMPORT] boolValue];
	BOOL            useImages = [[prefDict objectForKey:KEY_AB_USE_IMAGES] boolValue];
	
	//Use Nick Name and the format menu are irrelevent if importing of names is not enabled
	[checkBox_useNickName setEnabled:enableImport];	
	[format_menu setEnabled:enableImport];

	//We will not allow image syncing if AB images are preferred
	//so disable the control and uncheck the box to indicate this to the user
	//dchoby98: why are image import and export linked?
	//[checkBox_syncAutomatic setEnabled:!preferABImages];
	//if (preferABImages)
	//	[checkBox_syncAutomatic setState:NSOffState];
	
	//Disable the image priority checkbox if we aren't using images
	[checkBox_preferABImages setEnabled:useImages];
}

- (void)configureFormatMenu
{
    NSMenu		*choicesMenu = [[[NSMenu alloc] init] autorelease];
    NSMenuItem		*menuItem;
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:ADDRESS_BOOK_FIRST_LAST_OPTION
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:FirstLast];
    [choicesMenu addItem:menuItem];
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:ADDRESS_BOOK_FIRST_OPTION
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:First];
    [choicesMenu addItem:menuItem];
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:ADDRESS_BOOK_LAST_FIRST_OPTION
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:LastFirst];
    [choicesMenu addItem:menuItem];

	menuItem = [[[NSMenuItem alloc] initWithTitle:ADDRESS_BOOK_LAST_FIRST_NO_COMMA_OPTION
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:LastFirstNoComma];
    [choicesMenu addItem:menuItem];
	
    [format_menu setMenu:choicesMenu];

    NSRect oldFrame = [format_menu frame];
    [format_menu sizeToFit];
    [format_menu setFrameOrigin:oldFrame.origin];
}

//Save changed preference
- (IBAction)changeFormat:(id)sender
{
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]]
                                            forKey:KEY_AB_DISPLAYFORMAT
                                            group:PREF_GROUP_ADDRESSBOOK];
}

- (IBAction)changePreference:(id)sender
{
    if (sender == checkBox_syncAutomatic){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
                                             forKey:KEY_AB_IMAGE_SYNC
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    }else if (sender == checkBox_useABImages){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
                                             forKey:KEY_AB_USE_IMAGES
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    }else if (sender == checkBox_useNickName){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
                                             forKey:KEY_AB_USE_NICKNAME
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    }else if (sender == checkBox_enableImport){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_ENABLE_IMPORT
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    }else if (sender == checkBox_preferABImages){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    }else if (sender == checkBox_enableNoteSync){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_NOTE_SYNC
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    }else if (sender == checkBox_metaContacts){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_CREATE_METACONTACTS
                                              group:PREF_GROUP_ADDRESSBOOK];
	}

    [self configureControlDimming];
}

@end
