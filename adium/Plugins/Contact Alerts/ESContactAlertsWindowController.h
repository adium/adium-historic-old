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

    IBOutlet	NSTableView			*tableView_actions;
    IBOutlet	NSTableView			*tableView_source;
    
	NSMutableArray					*alertContacts;      //The contacts that have alerts
	NSMutableArray					*actionsArray;
	
	NSToolbar						*toolbar_editing;
	NSMutableDictionary				*toolbarItems;
	NSToolbarItem					*addItem,
									*editItem,
									*deleteItem;
	
    AIListObject					*activeContactObject;
    ESContactAlerts					*instance;
}

+ (id)showContactAlertsWindowForObject:(AIListObject *)inContact;
+ (void)closeContactAlertsWindow;

- (IBAction)closeWindow:(id)sender;
- (IBAction)addAlert:(id)sender;
- (IBAction)editAlert:(id)sender;
- (IBAction)deleteAlert:(id)sender;

@end
