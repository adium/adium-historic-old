//
//  AIContactAlertsWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AIAdium, AIAlternatingRowTableView, AIListContact;

#define KEY_CONTACT_ALERTS_WINDOW_FRAME		@"Contact Alerts Window"

@interface AIContactAlertsWindowController : NSWindowController {

    IBOutlet	NSPopUpButton			*popUp_addEvent;
    IBOutlet	AIAlternatingRowTableView	*tableView_actions;
    IBOutlet	NSButton			*button_delete;
    IBOutlet	NSTextField			*textField_description_popUp;
    IBOutlet 	NSTextField			*textField_description_textField;
    IBOutlet	NSTextField			*textField_actionDetails;
    IBOutlet	NSPopUpButton			*popUp_actionDetails;
    IBOutlet	NSButton			*button_oneTime;
    IBOutlet	NSPopUpButton			*popUp_contactList;
    NSMenu					*actionMenu;

    IBOutlet	NSView				*view_main;
    IBOutlet	NSView				*view_top;
    IBOutlet	NSView				*view_details_text;
    IBOutlet	NSView				*view_details_menu;

    NSView					*view_blank;
    NSView					*view_details;
    
    
    AIAdium					*owner;
    AIListObject				*activeContactObject;

    NSMutableArray				*eventActionArray;
    NSMutableArray				*eventSoundArray;
}

+ (id)showContactAlertsWindowWithOwner:(id)inOwner forObject:(AIListObject *)inContact;
- (void)configureWindowforObject:(AIListObject *)inContact;

+ (void)closeContactAlertsWindow;
- (IBAction)closeWindow:(id)sender;
- (IBAction)deleteEventAction:(id)sender;
- (IBAction)newEvent:(id)sender;
- (IBAction)actionPlaySound:(id)sender;
- (IBAction)actionSendMessage:(id)sender;
- (IBAction)selectSound:(id)sender;
- (IBAction)selectBehavior:(id)sender;
- (IBAction)oneTimeEvent:(id)sender;
@end
