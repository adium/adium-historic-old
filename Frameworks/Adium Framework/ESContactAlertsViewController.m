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

#import "AIContactController.h"
#import "AIListObject.h"
#import "AIPreferenceController.h"
#import "CSNewContactAlertWindowController.h"
#import "ESContactAlertsController.h"
#import "ESContactAlertsViewController.h"
#import <AIUtilities/AIAlternatingRowTableView.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/ESImageAdditions.h>

@interface ESContactAlertsViewController (PRIVATE)
- (void)configureActionsCell;
@end

int alertAlphabeticalSort(id objectA, id objectB, void *context);
int globalAlertAlphabeticalSort(id objectA, id objectB, void *context);

@implementation ESContactAlertsViewController

//Configure the preference view
- (void)awakeFromNib
{
	//Configure Table view
	[tableView_actions setDrawsAlternatingRows:YES];
    [tableView_actions setTarget:self];
    [tableView_actions setDoubleAction:@selector(editAlert:)];
	[tableView_actions setDelegate:self];
	[tableView_actions setDataSource:self];
	
	[scrollView_actions setAlwaysDrawFocusRingIfFocused:YES];
	
	[self configureActionsCell];
	
	//Manually size and position our buttons
	{
		NSRect	newFrame, oldFrame;

		//Edit, right justified and far enough away from Remove that it can't conceivably overlap
		oldFrame = [button_edit frame];
		[button_edit setTitle:AILocalizedString(@"Edit",nil)];
		[button_edit sizeToFit];
		newFrame = [button_edit frame];
		if(newFrame.size.width < oldFrame.size.width) newFrame.size.width = oldFrame.size.width;
		newFrame.origin.x = oldFrame.origin.x + oldFrame.size.width - newFrame.size.width;
		[button_edit setFrame:newFrame];
	}

	//Disable edit and delete by default; if a selection is made they will be enabled
	[button_delete setEnabled:NO];
	[button_edit setEnabled:NO];

	configureForGlobal = NO;
	showEventsInEditSheet = YES;

	//
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_ALERTS];
}

//Preference view is closing
- (void)viewWillClose
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

- (void)dealloc
{
	[alertArray release]; alertArray = nil;
    [listObject release]; listObject = nil;
	
	[super dealloc];
}

- (void)setDelegate:(id)inDelegate
{
	NSParameterAssert([inDelegate respondsToSelector:@selector(contactAlertsViewController:updatedAlert:oldAlert:)]);
	NSParameterAssert([inDelegate respondsToSelector:@selector(contactAlertsViewController:deletedAlert:)]);
	delegate = inDelegate;
}

- (id)delegate
{
	return(delegate);
}


//Configure the pane for a list object
- (void)configureForListObject:(AIListObject *)inObject
{
	[self configureForListObject:inObject showingAlertsForEventID:nil];
}

- (void)configureForListObject:(AIListObject *)inObject showingAlertsForEventID:(NSString *)inTargetEventID
{
	//Configure for the list object, using the highest-up metacontact if necessary
	[listObject release];
	listObject = [[[adium contactController] parentContactForListObject:inObject] retain];
	
	[targetEventID release];
	targetEventID = [inTargetEventID retain];
	
	//
	[self preferencesChangedForGroup:nil key:nil object:nil preferenceDict:nil firstTime:NO];
}

//Alerts have changed
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if(!firstTime && (!object || object == listObject)){
		//Update our list of alerts
		[alertArray release];
		alertArray = [[[adium contactAlertsController] alertsForListObject:listObject 
															   withEventID:targetEventID
																  actionID:nil] mutableCopy];

		//Sort them
		[alertArray sortUsingFunction:(configureForGlobal ? globalAlertAlphabeticalSort : alertAlphabeticalSort)
							  context:nil];
		
		//Refresh
		[tableView_actions reloadData];
	}
}

//Sort by event ID, then Action ID
int alertAlphabeticalSort(id objectA, id objectB, void *context)
{
	NSComparisonResult	result = [(NSString *)[objectA objectForKey:KEY_EVENT_ID] compare:(NSString *)[objectB objectForKey:KEY_EVENT_ID]];
	if(result == NSOrderedSame){
		result = [(NSString *)[objectA objectForKey:KEY_ACTION_ID] compare:(NSString *)[objectB objectForKey:KEY_ACTION_ID]];
	}
	
	return(result);
}

int globalAlertAlphabeticalSort(id objectA, id objectB, void *context)
{
	NSComparisonResult	result = [(NSString *)[objectA objectForKey:KEY_ACTION_ID] compare:(NSString *)[objectB objectForKey:KEY_ACTION_ID]];

	if(result == NSOrderedSame){
		result = [(NSString *)[objectA objectForKey:KEY_EVENT_ID] compare:(NSString *)[objectB objectForKey:KEY_EVENT_ID]];
	}
	
	return(result);
}

//Alert Editing --------------------------------------------------------------------------------------------------------
#pragma mark Actions
//Add new alert
- (IBAction)addAlert:(id)sender
{
	[CSNewContactAlertWindowController editAlert:nil 
								   forListObject:listObject
										onWindow:[view window]
								 notifyingTarget:self
										delegate:delegate
										oldAlert:nil
							  configureForGlobal:configureForGlobal
						   showEventsInEditSheet:showEventsInEditSheet];
}

//Edit existing alert
- (IBAction)editAlert:(id)sender
{
	int	selectedRow = [tableView_actions selectedRow];
	if(selectedRow >= 0 && selectedRow < [tableView_actions numberOfRows]){
		NSDictionary	*alert = [alertArray objectAtIndex:selectedRow];
		
		[CSNewContactAlertWindowController editAlert:alert
									   forListObject:listObject
											onWindow:[view window]
									 notifyingTarget:self
											delegate:delegate
											oldAlert:alert
								  configureForGlobal:configureForGlobal
							   showEventsInEditSheet:showEventsInEditSheet];
	}
}

//Delete an alert
- (IBAction)deleteAlert:(id)sender
{
	unsigned int selectedRow = [tableView_actions selectedRow];
	if (selectedRow != -1){
		NSDictionary	*deletedAlert = [alertArray objectAtIndex:selectedRow];

		[deletedAlert retain];
		
		[[adium contactAlertsController] removeAlert:deletedAlert
									  fromListObject:listObject];
		if(delegate){
			[delegate contactAlertsViewController:self
									 deletedAlert:deletedAlert];
		}
		
		[deletedAlert release];
		
	}
}

//Callback from 'new alert' panel.  (Add the alert, or update existing alert)
- (void)alertUpdated:(NSDictionary *)newAlert oldAlert:(NSDictionary *)oldAlert
{
	[oldAlert retain];
	
	//If this was an edit, remove the old alert first
	if(oldAlert) [[adium contactAlertsController] removeAlert:oldAlert fromListObject:listObject];
	
	//Add the new alert
	[[adium contactAlertsController] addAlert:newAlert toListObject:listObject setAsNewDefaults:YES];
	
	if(delegate){
		[delegate contactAlertsViewController:self
								 updatedAlert:newAlert
									 oldAlert:oldAlert];
	}
	
	[oldAlert release];
}


//Table View Data Sources ----------------------------------------------------------------------------------------------
#pragma mark TableView Data Sources
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([alertArray count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return(@""); //We'll set this in 'willDisplayCell' below
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSDictionary			*alert = [alertArray objectAtIndex:row];
	NSString				*actionID = [alert objectForKey:KEY_ACTION_ID];
	NSString				*eventID = [alert objectForKey:KEY_EVENT_ID];
	NSString				*eventDescription = [[adium contactAlertsController] longDescriptionForEventID:eventID 
																							 forListObject:listObject];
	id <AIActionHandler>	actionHandler = [[[adium contactAlertsController] actionHandlers] objectForKey:actionID];
	
	if(actionHandler && eventDescription){
		if(configureForGlobal){
			//Just show the action description for global
			[cell setObjectValue:[actionHandler longDescriptionForActionID:actionID
															   withDetails:[alert objectForKey:KEY_ACTION_DETAILS]]];						
		}else{
			//Show event and action descriptions for object-specific
			[cell setObjectValue:eventDescription];
			[cell setSubString:[actionHandler longDescriptionForActionID:actionID
															 withDetails:[alert objectForKey:KEY_ACTION_DETAILS]]];			
		}
		
		[cell setImage:[actionHandler imageForActionID:actionID]];
	}
}

//Enable / disable controls as the user's selection changes
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	unsigned	row = [tableView_actions selectedRow];
	BOOL		validSelection = ((row >= 0) && (row < [alertArray count]));
	
	[button_delete setEnabled:validSelection];
	[button_edit setEnabled:validSelection];

	if(validSelection){
		NSDictionary				*alert = [alertArray objectAtIndex:row];
		NSString					*actionID = [alert objectForKey:KEY_ACTION_ID];
		NSObject<AIActionHandler>	*actionHandler = [[[adium contactAlertsController] actionHandlers] objectForKey:actionID];

		if([actionHandler respondsToSelector:@selector(performPreviewForAlert:)]){
			[actionHandler performPreviewForAlert:alert];
		}
	}
}

//Delete the selection
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self deleteAlert:nil];
}

#pragma mark Global configuration
- (void)setConfigureForGlobal:(BOOL)inConfigureForGlobal
{
	configureForGlobal = inConfigureForGlobal;
	[self configureActionsCell];
}

- (void)setShowEventsInEditSheet:(BOOL)inShowEventsInEditSheet
{
	showEventsInEditSheet = inShowEventsInEditSheet;
}

- (void)configureActionsCell
{
	AIImageTextCell *actionsCell;

	actionsCell = [[AIImageTextCell alloc] init];
	[actionsCell setIgnoresFocus:YES];
	[actionsCell setDrawsGradientHighlight:YES];

	if(configureForGlobal){
		[actionsCell setFont:[NSFont boldSystemFontOfSize:13]];

		[tableView_actions setRowHeight:38];
		[actionsCell setMaxImageWidth:36];
		[actionsCell setImageTextPadding:14];

	}else{
		[actionsCell setFont:[NSFont systemFontOfSize:12]];
		[tableView_actions setRowHeight:30];		
	}

	[[tableView_actions tableColumnWithIdentifier:@"description"] setDataCell:actionsCell];
	[actionsCell release];
}
@end
