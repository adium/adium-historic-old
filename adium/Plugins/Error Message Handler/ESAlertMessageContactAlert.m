//
//  ESAlertMessageContactAlert.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Sat Nov 29 2003.
//

#import "ESAlertMessageContactAlert.h"
#import "ErrorMessageHandlerPlugin.h"

#define CONTACT_ALERT_ACTION_NIB @"AlertMessageContactAlert"

#define SHOW_TEXT_ALERT AILocalizedString(@"Show a text alert",nil)

@implementation ESAlertMessageContactAlert

-(NSString *)nibName
{
    return CONTACT_ALERT_ACTION_NIB;
}

- (NSMenuItem *)alertMenuItem
{
    NSMenuItem * menuItem = [[[NSMenuItem alloc] initWithTitle:SHOW_TEXT_ALERT
                                                        target:self
                                                        action:@selector(selectedAlert:)
                                                 keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:CONTACT_ALERT_IDENTIFIER];
    
    return (menuItem);
}

//setup display for playing a sound
- (IBAction)selectedAlert:(id)sender
{   
    //Get the current dictionary
    NSDictionary *currentDict = [[adium contactAlertsController] currentDictForContactAlert:self];
    
    //Set the menu to its previous setting if the stored event matches
    if ([(NSString *)[currentDict objectForKey:KEY_EVENT_ACTION] isEqualToString:CONTACT_ALERT_IDENTIFIER]) {
		NSString	*details = [currentDict objectForKey:KEY_EVENT_DETAILS];
        [textField_actionDetails setStringValue:details ? details : @""];
    } else {
        [textField_actionDetails setStringValue:@""];   
    }
    
    [textField_actionDetails setDelegate:self];
    
    [self configureWithSubview:view_details_text];
    [[view_details_text window] makeFirstResponder:textField_actionDetails];
}

//Our text field was modified - save in KEY_EVENT_DETAILS (catch here instead of when it sends its action so a sudden window closure won't leave us without saving
- (void)controlTextDidChange:(NSNotification *)notification
{
    [self setObject:[[notification object] stringValue] forKey:KEY_EVENT_DETAILS];
    
    [self saveEventActionArray];
}
@end
