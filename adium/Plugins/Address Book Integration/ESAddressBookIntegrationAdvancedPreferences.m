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
    [menuItem setTag:ADDRESS_BOOK_FIRST_LAST];
    [choicesMenu addItem:menuItem];
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:ADDRESS_BOOK_FIRST_OPTION
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:ADDRESS_BOOK_FIRST];
    [choicesMenu addItem:menuItem];
    
    menuItem = [[[NSMenuItem alloc] initWithTitle:ADDRESS_BOOK_LAST_FIRST_OPTION
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:ADDRESS_BOOK_LAST_FIRST];
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
        [format_menu selectItemAtIndex:[format_menu indexOfItemWithTag:[[[owner preferenceController] preferenceForKey:KEY_AB_DISPLAYFORMAT group:PREF_GROUP_ADDRESSBOOK object:nil] intValue]]];
    
        switch ([[[owner preferenceController] preferenceForKey:KEY_AB_IMAGE_SYNC group:PREF_GROUP_ADDRESSBOOK object:nil] intValue]) {
            case ADDRESS_BOOK_SYNC_NO:
                [radioButton_syncNothing setState: NSOnState];
                [radioButton_syncAutomatic setState: NSOffState];
            break;
            case ADDRESS_BOOK_SYNC_AUTO:
                [radioButton_syncNothing setState: NSOffState];
                [radioButton_syncAutomatic setState: NSOnState];
            break;
        }
    }
}

//Save changed preference
- (IBAction)changeFormat:(id)sender
{
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]]
                                             forKey:KEY_AB_DISPLAYFORMAT
                                              group:PREF_GROUP_ADDRESSBOOK];
}

- (IBAction)changeSyncMethod:(id)sender
{
    if (sender == radioButton_syncNothing) {
        [[owner preferenceController] setPreference: [NSNumber numberWithInt: ADDRESS_BOOK_SYNC_NO]
                                             forKey: KEY_AB_IMAGE_SYNC
                                              group: PREF_GROUP_ADDRESSBOOK];
        [radioButton_syncAutomatic setState: NSOffState];
    } else if (sender == radioButton_syncAutomatic) {
        [[owner preferenceController] setPreference: [NSNumber numberWithInt: ADDRESS_BOOK_SYNC_AUTO]
                                             forKey: KEY_AB_IMAGE_SYNC
                                              group: PREF_GROUP_ADDRESSBOOK];
        [radioButton_syncNothing setState: NSOffState];
    }
}

@end
