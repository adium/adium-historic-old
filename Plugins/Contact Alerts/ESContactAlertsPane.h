//
//  ESContactAlertsWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

@class AIAlternatingRowTableView;

@interface ESContactAlertsPane : AIContactInfoPane {
    IBOutlet	AIAlternatingRowTableView	*tableView_actions;
    IBOutlet	NSButton					*button_delete;
    IBOutlet	NSButton					*button_edit;
    
	AIListObject				*listObject;
	NSMutableArray				*alertArray;
}

- (IBAction)addAlert:(id)sender;
- (IBAction)editAlert:(id)sender;
- (IBAction)deleteAlert:(id)sender;

@end
