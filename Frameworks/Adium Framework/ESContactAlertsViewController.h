/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIObject.h"

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