//
//  AIContactAlertsWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium, AIAlternatingRowTableView, AIListContact;

//@protocol AIListObjectObserver;

@interface AIContactAlertsWindowController : NSWindowController {
    IBOutlet	NSTextField	*textField_contactName;
    IBOutlet	NSPopUpButton			*popUp_addEvent;
    IBOutlet	AIAlternatingRowTableView	*tableView_actions;
    IBOutlet	NSButton			*button_delete;
        
    AIAdium		*owner;

    AIListContact	*activeContactObject;

    NSMutableArray			*eventActionArray;

    NSMutableArray			*eventSoundArray;
}

+ (id)showContactAlertsWindowWithOwner:(id)inOwner forContact:(AIListContact *)inContact;
+ (void)closeContactAlertsWindow;
- (void)configureWindowForContact:(AIListContact *)inContact;
- (IBAction)closeWindow:(id)sender;

@end
