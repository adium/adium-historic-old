//
//  ESContactAlertsView.h
//  Adium
//
//  Created by Evan Schoenberg on 12/14/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAlternatingRowTableView;

@interface ESContactAlertsViewController : AIObject {
	IBOutlet	NSView						*view;
	
	IBOutlet	AIAlternatingRowTableView	*tableView_actions;
	IBOutlet	NSButton					*button_add;
    IBOutlet	NSButton					*button_delete;
    IBOutlet	NSButton					*button_edit;
    
	AIListObject				*listObject;
	NSMutableArray				*alertArray;	
}

- (void)configureForListObject:(AIListObject *)inObject;

- (IBAction)addAlert:(id)sender;
- (IBAction)editAlert:(id)sender;
- (IBAction)deleteAlert:(id)sender;

@end
