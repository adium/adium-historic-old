//
//  ESContactAlertsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#import "ESContactAlertsWindowController.h"
#import "ESContactAlertsPlugin.h"
#import "CSNewContactAlertWindowController.h"

#define CONTACT_ALERT_WINDOW_NIB	@"ContactAlerts"

@interface ESContactAlertsWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName forObject:(AIListObject *)inListObject;
- (void)preferencesChanged:(NSNotification *)notification;
@end

int alertAlphabeticalSort(id objectA, id objectB, void *context);

@implementation ESContactAlertsWindowController

//Open a new info window
+ (void)showContactAlertsWindowForObject:(AIListObject *)inListObject
{
	ESContactAlertsWindowController	*controller;
	controller = [[self alloc] initWithWindowNibName:CONTACT_ALERT_WINDOW_NIB forObject:inListObject];
    [controller showWindow:nil];
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName forObject:(AIListObject *)inListObject
{
    [super initWithWindowNibName:windowNibName];
	
	listObject = [inListObject retain];
	
    return(self);
}

//Dealloc
- (void)dealloc
{
	[listObject release];
	[super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	AIImageTextCell *actionsCell;

	//Configure Window
	[[self window] setTitle:[NSString stringWithFormat:@"%@'s Alerts",[listObject displayName]]];
	
	//Configure Table view
	[tableView_actions setDrawsAlternatingRows:YES];
    [tableView_actions setTarget:self];
    [tableView_actions setDoubleAction:@selector(editAlert:)];
	actionsCell = [[[AIImageTextCell alloc] init] autorelease];
    [actionsCell setFont:[NSFont systemFontOfSize:12]];
	[[tableView_actions tableColumnWithIdentifier:@"description"] setDataCell:actionsCell];
	
	//Observe alert changes for our list object
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:listObject];
	[self preferencesChanged:nil];
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
	//remove all observers
	[[adium notificationCenter] removeObserver:self]; 
	
	//Close ourself
	[self autorelease];

    return(YES);
}

//Stop automatic window positioning
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//Close the window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Alerts have changed
- (void)preferencesChanged:(NSNotification *)notification
{
	if(notification == nil || 
	   ([notification object] == listObject && 
		[(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:@"Contact Alerts"] == 0)){

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
	[CSNewContactAlertWindowController editAlert:nil forListObject:listObject onWindow:[self window] notifyingTarget:self userInfo:nil];
}

//Edit existing alert
- (IBAction)editAlert:(id)sender
{
	NSDictionary	*alert = [alertArray objectAtIndex:[tableView_actions selectedRow]];

	[CSNewContactAlertWindowController editAlert:alert forListObject:listObject onWindow:[self window] notifyingTarget:self userInfo:alert];
}

//Delete an alert
- (IBAction)deleteAlert:(id)sender
{
	[[adium contactAlertsController] removeAlert:[alertArray objectAtIndex:[tableView_actions selectedRow]]
								  fromListObject:listObject];
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