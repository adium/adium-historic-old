//
//  ESAddressBookIntegrationAdvancedPreferences.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Fri Nov 21 2003.
//

#import "ESAddressBookIntegrationAdvancedPreferences.h"
#import "ESAddressBookIntegrationPlugin.h"

#define ADDRESS_BOOK_FIRST_LAST_OPTION  @"First Last"
#define ADDRESS_BOOK_FIRST_OPTION       @"First"
#define ADDRESS_BOOK_LAST_FIRST_OPTION  @"Last, First"
#define ADDRESS_BOOK_NONE_OPTION        @"<Disabled>"

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
    return(AILocalizedString(@"Address Book Integration",nil));
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
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self configureFormatMenu];
    [self preferencesChanged:nil];
}

- (void)viewWillClose
{
    [[adium notificationCenter] removeObserver:self];
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

    [format_menu setMenu:choicesMenu];

    NSRect oldFrame = [format_menu frame];
    [format_menu sizeToFit];
    [format_menu setFrameOrigin:oldFrame.origin];
}

//Reflect new preferences in view
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_ADDRESSBOOK compare:[[notification userInfo] objectForKey:@"Group"]] == 0){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ADDRESSBOOK];
        bool			enableImport = [[prefDict objectForKey:KEY_AB_ENABLE_IMPORT] boolValue];

		[checkBox_enableImport setState:enableImport];

        [format_menu selectItemAtIndex:[format_menu indexOfItemWithTag:[[prefDict objectForKey:KEY_AB_DISPLAYFORMAT] intValue]]];
		[format_menu setEnabled:enableImport];

		[checkBox_syncAutomatic setState:[[prefDict objectForKey:KEY_AB_IMAGE_SYNC] boolValue]];
		[checkBox_useNickName setState:[[prefDict objectForKey:KEY_AB_USE_NICKNAME] boolValue]];
		[checkBox_useNickName setEnabled:enableImport];
    }
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
    if (sender == checkBox_syncAutomatic) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
                                             forKey:KEY_AB_IMAGE_SYNC
                                              group:PREF_GROUP_ADDRESSBOOK];
    } else if (sender == checkBox_useNickName) {
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
                                             forKey:KEY_AB_USE_NICKNAME
                                              group:PREF_GROUP_ADDRESSBOOK];
    } else if (sender == checkBox_enableImport) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_ENABLE_IMPORT
                                              group:PREF_GROUP_ADDRESSBOOK];
	}
}

@end
