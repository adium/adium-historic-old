//
//  ESContactAlertsWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#import "ESContactAlerts.h"

@class AIAlternatingRowTableView, AIListContact;

#define KEY_CONTACT_ALERTS_WINDOW_FRAME		@"Contact Alerts Window"

@interface ESContactAlertsWindowController : AIWindowController {

    IBOutlet	NSPopUpButton			*popUp_addEvent;
    IBOutlet	AIAlternatingRowTableView	*tableView_actions;
    IBOutlet	NSButton			*button_delete;
    IBOutlet	NSButton			*button_oneTime;
    IBOutlet	NSButton			*button_active;
    IBOutlet	NSPopUpButton			*popUp_contactList;
    IBOutlet	NSView				*view_main;
    
    NSPopUpButtonCell				*dataCell;
    NSMenu					*actionMenu;
    AIListObject				*activeContactObject;
    ESContactAlerts				*instance;
}

+ (id)showContactAlertsWindowForObject:(AIListObject *)inContact;
+ (void)closeContactAlertsWindow;

- (IBAction)deleteEventAction:(id)sender;
- (IBAction)closeWindow:(id)sender;
- (IBAction)oneTimeEvent:(id)sender;
- (IBAction)addedEvent:(id)sender;
- (IBAction)onlyWhileActive:(id)sender;

- (void)accountListChanged:(NSNotification *)notification;

@end
