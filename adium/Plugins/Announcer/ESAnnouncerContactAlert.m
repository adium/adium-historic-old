//
//  ESAnnouncerContactAlert.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESAnnouncerContactAlert.h"
#import "ESAnnouncerPlugin.h"

#define CONTACT_ALERT_ACTION_NIB @"AnnouncerContactAlert"

@implementation ESAnnouncerContactAlert

-(NSString *)nibName
{
    return CONTACT_ALERT_ACTION_NIB;
}

- (NSMenuItem *)alertMenuItem
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"Speak text"
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
        [textField_actionDetails setStringValue:[currentDict objectForKey:KEY_EVENT_DETAILS]];
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
