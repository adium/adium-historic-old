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

#define ADDESS_BOOK_NAME_FORMAT_INSTRUCTIONS @"Address Book Name Format: "

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
    return(@"Address Book Integration");
}
- (NSString *)nibName{
    return(@"AddressBookPrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self configureFormatMenu];
    [self preferencesChanged:nil];
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
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:ADDRESS_BOOK_NONE_OPTION
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:None];
    [choicesMenu addItem:menuItem];
    
    [format_menu setMenu:choicesMenu];
    
    [format_textField setStringValue:ADDESS_BOOK_NAME_FORMAT_INSTRUCTIONS];
    [format_textField sizeToFit];
    
    [format_menu sizeToFit];
    NSRect instructionFrame = [format_textField frame];
    [format_menu setFrameOrigin:NSMakePoint(instructionFrame.size.width + instructionFrame.origin.x, 
                                            (instructionFrame.origin.y+(instructionFrame.size.height-[format_menu frame].size.height)/2))];
}

//Reflect new preferences in view
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [PREF_GROUP_ADDRESSBOOK compare:[[notification userInfo] objectForKey:@"Group"]] == 0){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_ADDRESSBOOK];
        
        [format_menu selectItemAtIndex:[format_menu indexOfItemWithTag:[[prefDict objectForKey:KEY_AB_DISPLAYFORMAT] intValue]]];
    
        [checkBox_syncAutomatic setState:[[prefDict objectForKey:KEY_AB_IMAGE_SYNC] boolValue]];
    }
}

//Save changed preference
- (IBAction)changeFormat:(id)sender
{
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]]
                                             forKey:KEY_AB_DISPLAYFORMAT
                                              group:PREF_GROUP_ADDRESSBOOK];
}

- (IBAction)changePreference:(id)sender
{
    if (sender == checkBox_syncAutomatic) {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:([checkBox_syncAutomatic state]==NSOnState)]
                                             forKey:KEY_AB_IMAGE_SYNC
                                              group:PREF_GROUP_ADDRESSBOOK];
    }
}

@end
