//
//  CSNewContactAlertWindowController.m
//  Adium
//
//  Created by Chris Serino on Wed Mar 31 2004.
//

#import "CSNewContactAlertWindowController.h"
#import "ESContactAlertsPane.h"
#import "ESContactAlertsPlugin.h"

#define NEW_ALERT_NIB @"NewAlert"

@interface CSNewContactAlertWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName alert:(NSDictionary *)inAlert forListObject:(AIListObject *)inListObject notifyingTarget:(id)inTarget userInfo:(id)inUserInfo;
- (void)configureForEvent;
- (void)saveDetailsPaneChanges;
- (void)configureDetailsPane;
- (void)cleanUpDetailsPane;
@end

@implementation CSNewContactAlertWindowController

//Prompt for a new alert.  Pass nil for a panel prompt.
+ (void)editAlert:(NSDictionary *)inAlert forListObject:(AIListObject *)inListObject onWindow:(NSWindow *)parentWindow notifyingTarget:(id)inTarget userInfo:(id)inUserInfo
{
	CSNewContactAlertWindowController	*newAlertwindow = [[self alloc] initWithWindowNibName:NEW_ALERT_NIB alert:inAlert forListObject:inListObject notifyingTarget:inTarget userInfo:inUserInfo];
	
	if(parentWindow){
		[NSApp beginSheet:[newAlertwindow window]
		   modalForWindow:parentWindow
			modalDelegate:newAlertwindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[newAlertwindow showWindow:nil];
	}
}
	
//Init
- (id)initWithWindowNibName:(NSString *)windowNibName alert:(NSDictionary *)inAlert forListObject:(AIListObject *)inListObject notifyingTarget:(id)inTarget userInfo:(id)inUserInfo
{
	[super initWithWindowNibName:windowNibName];
	
	//
	userInfo = [inUserInfo retain];
	listObject = [inListObject retain];
	target = inTarget;
	detailsPane = nil;
	
	//Create a mutable copy of the alert dictionary we're passed.  If we're passed nil, create the default alert.
	alert = [inAlert mutableCopy];
	if(!alert){
		NSString	*defaultEvent = [[[[adium contactAlertsController] eventHandlers] allKeys] objectAtIndex:0];
		NSString	*defaultAction = [[[[adium contactAlertsController] actionHandlers] allKeys] objectAtIndex:0];
		
		alert = [[NSMutableDictionary alloc] initWithObjectsAndKeys:defaultEvent, @"EventID", defaultAction, @"ActionID", nil];
	}
	
	return(self);
}

//Dealloc
- (void)dealloc
{
	[alert release];
	[userInfo release];
	[detailsPane release];
	[listObject release];
	
	[super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	//Configure window
	[[self window] center];
	[popUp_event setMenu:[[adium contactAlertsController] menuOfEventsWithTarget:self]];
	[popUp_action setMenu:[[adium contactAlertsController] menuOfActionsWithTarget:self]];

	//Set things up for the current event
	[self configureForEvent];
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
	[self cleanUpDetailsPane];
	
    return(YES);
}

//Stop automatic window positioning
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
		if([[self window] isSheet]) [NSApp endSheet:[self window]];
        [[self window] close];
    }
}

//Called as the user list edit sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}


//Buttons --------------------------------------------------------------------------------------------------------------
#pragma mark Buttons
//Cancel changes
- (IBAction)cancel:(id)sender
{
	[self closeWindow:nil];
}

//Save changes
- (IBAction)save:(id)sender
{
	//Save changes in our detail pane
	[self saveDetailsPaneChanges];

	//Pass the modified alert to our target
	[target performSelector:@selector(alertUpdated:userInfo:) withObject:alert withObject:userInfo];
	[self closeWindow:nil];
}


//Controls -------------------------------------------------------------------------------------------------------------
#pragma mark Controls
//Configure window for our current event dict
- (void)configureForEvent
{
	NSEnumerator 	*enumerator;
	NSMenuItem 		*menuItem;

	//Select the correct event
	NSString	*eventID = [alert objectForKey:KEY_EVENT_ID];
	enumerator = [[popUp_event itemArray] objectEnumerator];
	while(menuItem = [enumerator nextObject]){
		if([eventID compare:[menuItem representedObject]] == 0){
			[popUp_event selectItem:menuItem];
			break;
		}
	}
	
	//Select the correct action
	NSString	*actionID = [alert objectForKey:KEY_ACTION_ID];
	enumerator = [[popUp_action itemArray] objectEnumerator];
	while(menuItem = [enumerator nextObject]){
		if([actionID compare:[menuItem representedObject]] == 0){
			[popUp_action selectItem:menuItem];
			break;
		}
	}
	
	//Setup our single-fire option
	[checkbox_oneTime setState:[[alert objectForKey:KEY_ONE_TIME_ALERT] intValue]];
	
	//Configure the action details pane
	[self configureDetailsPane];
}

//Save changes made in the details pane
- (void)saveDetailsPaneChanges
{
	//Save details
	NSDictionary	*actionDetails = [detailsPane actionDetails];
	if(actionDetails){
		[alert setObject:actionDetails forKey:KEY_ACTION_DETAILS];
	}

	//Save our single-fire option
	[alert setObject:[NSNumber numberWithInt:[checkbox_oneTime state]] forKey:KEY_ONE_TIME_ALERT];
}

//Remove details view/pane
- (void)cleanUpDetailsPane
{
	[detailsView removeFromSuperview];
	detailsView = nil;
	[detailsPane closeView];
	[detailsPane release];
	detailsPane = nil;
}

//Configure the details pane for our current alert
- (void)configureDetailsPane
{
	NSString				*actionID = [alert objectForKey:KEY_ACTION_ID];
	id <AIActionHandler>	actionHandler = [[[adium contactAlertsController] actionHandlers] objectForKey:actionID];		

	//Save changes and close down the old pane
	if(detailsPane) [self saveDetailsPaneChanges];
	[self cleanUpDetailsPane];
	
	//Get a new pane for the current action type, and configure it for our alert
	detailsPane = [[actionHandler detailsPaneForActionID:actionID] retain];
	if(detailsPane){
		detailsView = [detailsPane view];
		[detailsPane configureForActionDetails:[alert objectForKey:KEY_ACTION_DETAILS] listObject:listObject];
	}

	//Resize our window for best fit
	int		currentDetailHeight = [view_auxiliary frame].size.height;
	int	 	desiredDetailHeight = [detailsView frame].size.height;
	int		difference = (currentDetailHeight - desiredDetailHeight);
	NSRect	frame = [[self window] frame];
	[[self window] setFrame:NSMakeRect(frame.origin.x, frame.origin.y + difference, frame.size.width, frame.size.height - difference)
					display:[[self window] isVisible]
					animate:[[self window] isVisible]];
	
	//Add the details view
	if(detailsView) [view_auxiliary addSubview:detailsView];
}

//User selected an event from the popup
- (IBAction)selectEvent:(id)sender
{
	if([sender representedObject]){
		[alert setObject:[sender representedObject] forKey:KEY_EVENT_ID];
	}
}
	
//User selected an action from the popup
- (IBAction)selectAction:(id)sender
{
	if([sender representedObject]){
		[alert setObject:[sender representedObject] forKey:KEY_ACTION_ID];
		[self configureDetailsPane];
	}
}

@end
