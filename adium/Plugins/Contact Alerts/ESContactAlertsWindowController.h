//
//  ESContactAlertsWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

@class AIAlternatingRowTableView;

@interface ESContactAlertsWindowController : AIWindowController {
    IBOutlet	AIAlternatingRowTableView	*tableView_actions;
    IBOutlet	NSButton					*button_delete;
    IBOutlet	NSButton					*button_edit;
    
	AIListObject				*listObject;
	NSMutableArray				*alertArray;
}

+ (void)showContactAlertsWindowForObject:(AIListObject *)inListObject;

- (IBAction)closeWindow:(id)sender;
- (IBAction)addAlert:(id)sender;
- (IBAction)editAlert:(id)sender;
- (IBAction)deleteAlert:(id)sender;

@end
