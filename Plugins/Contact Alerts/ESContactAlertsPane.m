//
//  ESContactAlertsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#import "ESContactAlertsPane.h"
#import "ESContactAlertsPlugin.h"
#import "CSNewContactAlertWindowController.h"

@interface ESContactAlertsPane (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

int alertAlphabeticalSort(id objectA, id objectB, void *context);

@implementation ESContactAlertsPane

//Preference pane properties
- (CONTACT_INFO_CATEGORY)contactInfoCategory{
    return(AIInfo_Alerts);
}
- (NSString *)label{
    return(@"Contact Alerts");
}
- (NSString *)nibName{
    return(@"ContactAlerts");
}

//Configure the preference view
- (void)viewDidLoad
{
	AIImageTextCell *actionsCell;
	
	//Configure Table view
	[tableView_actions setDrawsAlternatingRows:YES];
    [tableView_actions setTarget:self];
    [tableView_actions setDoubleAction:@selector(editAlert:)];
	actionsCell = [[[AIImageTextCell alloc] init] autorelease];
    [actionsCell setFont:[NSFont systemFontOfSize:12]];
	[actionsCell setIgnoresFocus:YES];
	[[tableView_actions tableColumnWithIdentifier:@"description"] setDataCell:actionsCell];
	
	//
	[button_edit setTitle:@"Edit"];
	[button_delete setEnabled:NO];
	[button_edit setEnabled:NO];
}

//Preference view is closing
- (void)viewWillClose
{
	[alertArray release]; alertArray = nil;
    [listObject release]; listObject = nil;
	[[adium notificationCenter] removeObserver:self]; 
}

//Configure the pane for a list object
- (void)configureForListObject:(AIListObject *)inObject
{
	//Configure for the list object, using the highest-up metacontact if necessary
	[listObject release];
	listObject = [[[adium contactController] parentContactForListObject:inObject] retain];

	//Observe alert changes for our list object
	[[adium notificationCenter] removeObserver:self name:Preference_GroupChanged object:nil]; 
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:listObject];
	[self preferencesChanged:nil];
}

//Alerts have changed
- (void)preferencesChanged:(NSNotification *)notification
{
	if(notification == nil || 
	   ([notification object] == listObject && 
		[(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_ALERTS])){
		
		//Update our list of alerts
		[alertArray release];
		alertArray = [[[adium contactAlertsController] alertsForListObject:listObject] mutableCopy];

		//Sort them
		[alertArray sortUsingFunction:alertAlphabeticalSort context:nil];
		
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



//Alert Editing --------------------------------------------------------------------------------------------------------
#pragma mark Actions
//Add new alert
- (IBAction)addAlert:(id)sender
{
	[CSNewContactAlertWindowController editAlert:nil forListObject:(AIListContact *)listObject onWindow:[[self view] window] notifyingTarget:self userInfo:nil];
}

//Edit existing alert
- (IBAction)editAlert:(id)sender
{
	int	selectedRow = [tableView_actions selectedRow];
	if(selectedRow >= 0 && selectedRow < [tableView_actions numberOfRows]){
		NSDictionary	*alert = [alertArray objectAtIndex:selectedRow];
		
		[CSNewContactAlertWindowController editAlert:alert forListObject:(AIListContact *)listObject onWindow:[[self view] window] notifyingTarget:self userInfo:alert];
	}
}

//Delete an alert
- (IBAction)deleteAlert:(id)sender
{
	unsigned int selectedRow = [tableView_actions selectedRow];
	if (selectedRow != -1){
		[[adium contactAlertsController] removeAlert:[alertArray objectAtIndex:selectedRow]
									  fromListObject:listObject];
	}
}

//Callback from 'new alert' panel.  (Add the alert, or update existing alert)
- (void)alertUpdated:(NSDictionary *)newAlert userInfo:(NSDictionary *)userInfo
{
	//If this was an edit, remove the old alert first
	if(userInfo) [[adium contactAlertsController] removeAlert:userInfo fromListObject:listObject];

	//Add the new alert
	[[adium contactAlertsController] addAlert:newAlert toListObject:listObject];
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
	id <AIActionHandler>	actionHandler = [[[adium contactAlertsController] actionHandlers] objectForKey:actionID];
	id <AIEventHandler>		eventHandler = [[[adium contactAlertsController] eventHandlers] objectForKey:eventID];

	if(actionHandler && eventHandler){
		[cell setStringValue:[eventHandler longDescriptionForEventID:eventID forListObject:listObject]];
		[cell setImage:[actionHandler imageForActionID:actionID]];
		[cell setSubString:[actionHandler longDescriptionForActionID:actionID
														 withDetails:[alert objectForKey:KEY_ACTION_DETAILS]]];
	}
}

//Enable / disable controls as the user's selection changes
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	BOOL	validSelection = ([tableView_actions selectedRow] >= 0 && [tableView_actions selectedRow] < [alertArray count]);

	[button_delete setEnabled:validSelection];
	[button_edit setEnabled:validSelection];
}

//Delete the selection
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self deleteAlert:nil];
}

@end