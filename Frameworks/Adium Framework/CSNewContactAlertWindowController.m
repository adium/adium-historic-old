//
//  CSNewContactAlertWindowController.m
//  Adium
//
//  Created by Chris Serino on Wed Mar 31 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "CSNewContactAlertWindowController.h"
#import "ESContactAlertsViewController.h"

#import "AIImageTextCellView.h"

#define NEW_ALERT_NIB @"NewAlert"

@interface CSNewContactAlertWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName 
					  alert:(NSDictionary *)inAlert
			  forListObject:(AIListObject *)inObject
			notifyingTarget:(id)inTarget
				   oldAlert:(id)inOldAlert
		 configureForGlobal:(BOOL)inConfigureForGlobal;
- (void)configureForEvent;
- (void)saveDetailsPaneChanges;
- (void)configureDetailsPane;
- (void)cleanUpDetailsPane;

- (void)updateHeaderView;
@end

@implementation CSNewContactAlertWindowController

//Prompt for a new alert.  Pass nil for a panel prompt.
+ (void)editAlert:(NSDictionary *)inAlert forListObject:(AIListObject *)inObject onWindow:(NSWindow *)parentWindow notifyingTarget:(id)inTarget oldAlert:(id)inOldAlert configureForGlobal:(BOOL)inConfigureForGlobal
{
	CSNewContactAlertWindowController	*newAlertwindow = [[self alloc] initWithWindowNibName:NEW_ALERT_NIB
																						alert:inAlert
																				forListObject:inObject
																			  notifyingTarget:inTarget
																					 oldAlert:inOldAlert
																		   configureForGlobal:inConfigureForGlobal];
	
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
- (id)initWithWindowNibName:(NSString *)windowNibName 
					  alert:(NSDictionary *)inAlert
			  forListObject:(AIListObject *)inListObject
			notifyingTarget:(id)inTarget
				   oldAlert:(id)inOldAlert
		 configureForGlobal:(BOOL)inConfigureForGlobal
{
	[super initWithWindowNibName:windowNibName];
	
	//
	oldAlert = [inOldAlert retain];
	listObject = [inListObject retain];
	target = inTarget;
	detailsPane = nil;
	configureForGlobal = inConfigureForGlobal;
	
	//Create a mutable copy of the alert dictionary we're passed.  If we're passed nil, create the default alert.
	alert = [inAlert mutableCopy];
	if(!alert){
		alert = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[adium contactAlertsController] defaultEventID], KEY_EVENT_ID,
																	[[adium contactAlertsController] defaultActionID], KEY_ACTION_ID, nil];
	}

	[[adium notificationCenter] addObserver:self
								   selector:@selector(alertDetailsForHeaderChanged:)
									   name:CONTACT_ALERTS_DETAILS_FOR_HEADER_CHANGED
									 object:nil];

	return(self);
}

//Dealloc
- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];

	[alert release];
	[oldAlert release];
	[detailsPane release];
	[listObject release];
	
	[super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	if ([[self superclass] instancesRespondToSelector:@selector(windowDidLoad)]){
		   [super windowDidLoad];
	}
	
	//Configure window
	[[self window] center];
	[popUp_event setMenu:[[adium contactAlertsController] menuOfEventsWithTarget:self forGlobalMenu:configureForGlobal]];
	[popUp_action setMenu:[[adium contactAlertsController] menuOfActionsWithTarget:self]];

	[[self window] setTitle:AILocalizedString(@"New Alert",nil)];
	
	[checkbox_oneTime setTitle:AILocalizedString(@"Delete after event occurs","New contact alert pane")];
	[button_OK setTitle:AILocalizedString(@"OK",nil)];
	[button_cancel setTitle:AILocalizedString(@"Cancel",nil)];
	
	[label_Event setStringValue:AILocalizedString(@"Event:","Label for contact alert event (e.g. Contact signed on, Message received, etc.)")];
	[label_Action setStringValue:AILocalizedString(@"Action:","Label for contact alert action (e.g. Send message, Play sound, etc.)")];	

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
	[target performSelector:@selector(alertUpdated:oldAlert:) withObject:alert withObject:oldAlert];
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
		if([eventID isEqualToString:[menuItem representedObject]]){
			[popUp_event selectItem:menuItem];
			break;
		}
	}
	
	//Select the correct action
	NSString	*actionID = [alert objectForKey:KEY_ACTION_ID];
	enumerator = [[popUp_action itemArray] objectEnumerator];
	while(menuItem = [enumerator nextObject]){
		if([actionID isEqualToString:[menuItem representedObject]]){
			[popUp_action selectItem:menuItem];
			break;
		}
	}
	
	//Setup our single-fire option
	if(configureForGlobal){
		if([checkbox_oneTime respondsToSelector:@selector(setHidden:)]){
			[checkbox_oneTime setHidden:YES];
		}else{
			[checkbox_oneTime setFrame:NSZeroRect];
		}
	}else{
		[checkbox_oneTime setState:[[alert objectForKey:KEY_ONE_TIME_ALERT] intValue]];
	}
	
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
	[alert setObject:[NSNumber numberWithBool:([checkbox_oneTime state] == NSOnState)] forKey:KEY_ONE_TIME_ALERT];
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
		NSDictionary	*actionDetails = [alert objectForKey:KEY_ACTION_DETAILS];
		
		detailsView = [detailsPane view];

		[detailsPane configureForActionDetails:actionDetails listObject:listObject];		
		[detailsPane configureForEventID:[alert objectForKey:KEY_EVENT_ID]
							  listObject:listObject];
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
		
	//Pull any default values the pane set in configureForActionDetails
	[self saveDetailsPaneChanges];
	
	//And use them to update our header view
	[self updateHeaderView];
}

//User selected an event from the popup
- (IBAction)selectEvent:(id)sender
{
	NSString	*eventID;
	if(eventID = [sender representedObject]){
		[alert setObject:eventID forKey:KEY_EVENT_ID];
		
		[detailsPane configureForEventID:eventID
							  listObject:listObject];
				
		[self updateHeaderView];
	}
}
	
//User selected an action from the popup
- (IBAction)selectAction:(id)sender
{
	if([sender representedObject]){
		NSString	*newAction = [sender representedObject];
		NSString	*oldAction = [alert objectForKey:KEY_ACTION_ID];
		
		if(![newAction isEqualToString:oldAction]){
			[alert setObject:[sender representedObject] forKey:KEY_ACTION_ID];
			
			[self configureDetailsPane];
		}
	}
}

- (void)alertDetailsForHeaderChanged:(NSNotification *)aNotification
{
	[self saveDetailsPaneChanges];
	[self updateHeaderView];
}

- (void)updateHeaderView
{
	NSString				*actionID = [alert objectForKey:KEY_ACTION_ID];
	NSString				*eventID = [alert objectForKey:KEY_EVENT_ID];
	NSString				*eventDescription = [[adium contactAlertsController] longDescriptionForEventID:eventID 
																							 forListObject:listObject];
	id <AIActionHandler>	actionHandler = [[[adium contactAlertsController] actionHandlers] objectForKey:actionID];

	if(actionHandler && eventDescription){
		[headerView setStringValue:eventDescription];
		[headerView setImage:[actionHandler imageForActionID:actionID]];
		[headerView setSubString:[actionHandler longDescriptionForActionID:actionID
														 withDetails:[alert objectForKey:KEY_ACTION_DETAILS]]];
		[headerView setNeedsDisplay:YES];
	}
}

@end
