//
//  ESContactAlertsViewController.h
//  Adium
//
//  Created by Evan Schoenberg on 12/14/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define CONTACT_ALERTS_DETAILS_FOR_HEADER_CHANGED	@"ContactAlertDetailsForHeaderChanged"

@class AIAlternatingRowTableView;

@interface ESContactAlertsViewController : AIObject {
	IBOutlet	NSView						*view;
	
	IBOutlet	AIAlternatingRowTableView	*tableView_actions;
	IBOutlet	NSButton					*button_add;
    IBOutlet	NSButton					*button_delete;
    IBOutlet	NSButton					*button_edit;
    
	AIListObject				*listObject;
	NSMutableArray				*alertArray;
	
	id							delegate;
	
	BOOL						configureForGlobal;
}

- (void)configureForListObject:(AIListObject *)inObject;

- (IBAction)addAlert:(id)sender;
- (IBAction)editAlert:(id)sender;
- (IBAction)deleteAlert:(id)sender;

- (void)setDelegate:(id)inDelegate;
- (id)delegate;

- (void)setConfigureForGlobal:(BOOL)inConfigureForGlobal;

- (void)viewWillClose;

@end

@interface NSObject (ESContactAlertsViewControllerDelegate)

//Delegate is notified with the new and old alert dictionaries when the user makes a change
- (void)contactAlertsViewController:(ESContactAlertsViewController *)inController
					   updatedAlert:(NSDictionary *)newAlert
						   oldAlert:(NSDictionary *)oldAlert;

//Delegate is notificed with the deleted dictionary when the user deletes an alert
- (void)contactAlertsViewController:(ESContactAlertsViewController *)inController
					   deletedAlert:(NSDictionary *)deletedAlert;

@end

@interface NSObject (AIActionHandlerOptionalMethods)
- (void)didSelectAlert:(NSDictionary *)alert;
@end