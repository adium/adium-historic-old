//
//  ESContactAlertsWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import "ESContactAlerts.h"

@class AIAdium, AIAlternatingRowTableView, AIListContact;

#define KEY_CONTACT_ALERTS_WINDOW_FRAME		@"Contact Alerts Window"

@interface ESContactAlertsWindowController : NSWindowController {

    IBOutlet	NSPopUpButton			*popUp_addEvent;
    IBOutlet	AIAlternatingRowTableView	*tableView_actions;
    IBOutlet	NSButton			*button_delete;
    IBOutlet	NSButton			*button_oneTime;
    IBOutlet	NSPopUpButton			*popUp_contactList;
    IBOutlet	NSView				*view_main;

    NSMenu					*actionMenu;

    AIAdium					*owner;
    AIListObject				*activeContactObject;

    ESContactAlerts				*instance;
}

+ (id)showContactAlertsWindowWithOwner:(id)inOwner forObject:(AIListObject *)inContact;
+ (void)closeContactAlertsWindow;

- (IBAction)deleteEventAction:(id)sender;
- (IBAction)closeWindow:(id)sender;
- (IBAction)oneTimeEvent:(id)sender;

@end
