//
//  ESStatusPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on 2/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESStatusPreferences.h"
#import "AIStatusController.h"
#import <Adium/AIEditStateWindowController.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>

#define STATE_DRAG_TYPE	@"AIState"

@interface ESStatusPreferences (PRIVATE)
- (void)configureOtherControls;
@end

@implementation ESStatusPreferences

/*
 * @brief Category
 */
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Status);
}
/*
 * @brief Label
 */
- (NSString *)label{
    return(AILocalizedString(@"Status",nil));
}

/*
 * @brief Nib name
 */
- (NSString *)nibName{
    return(@"StatusPreferences");
}

/*
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	//Configure the controls
	[self configureStateList];
	[button_editState setTitle:AILocalizedString(@"Edit",nil)];
	
	/* Register as an observer of state array changes so we can refresh our list
	 * in response to changes. */
	[[adium notificationCenter] addObserver:self
								   selector:@selector(stateArrayChanged:)
									   name:AIStatusStateArrayChangedNotification
									 object:nil];
	[self stateArrayChanged:nil];

	[self configureOtherControls];
}

/*
 * @brief Preference view is closing
 */
- (void)viewWillClose
{
	[self saveTimeValues];
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[stateArray release];

	[super dealloc];
}

#pragma mark Status state list and controls
/*!
* @brief Configure the state list
 *
 * Configure the state list table view, setting up the custom table cells, padding, scroll view settings and other
 * state list interface related setup.
 */
- (void)configureStateList
{
    AIImageTextCell			*cell;

	//Configure the table view
	[tableView_stateList setTarget:self];
	[tableView_stateList setDoubleAction:@selector(editState:)];
	[tableView_stateList setIntercellSpacing:NSMakeSize(4,4)];
    [scrollView_stateList setAutoHideScrollBar:YES];
	
	//Enable dragging of states
	[tableView_stateList registerForDraggedTypes:[NSArray arrayWithObjects:STATE_DRAG_TYPE,nil]];
	
    //Custom vertically-centered text cell for status state names
    cell = [[AIVerticallyCenteredTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:13]];
    [[tableView_stateList tableColumnWithIdentifier:@"name"] setDataCell:cell];
	[cell release];
}

/*!
* @brief Update table control availability
 *
 * Updates table control availability based on the current state selection.  If no states are selected this method dims the
 * edit and delete buttons since they require a selection to function.  The edit and delete buttons are also
 * dimmed if the selected state is a built-in state.
 */
- (void)updateTableControlAvailability
{
	int		selectedRow = [tableView_stateList selectedRow];
	BOOL	shouldEnable;
	
	shouldEnable = ((selectedRow != -1) &&
					([[stateArray objectAtIndex:selectedRow] mutabilityType] == AIEditableStatusState));

	[button_editState setEnabled:shouldEnable];
	[button_deleteState setEnabled:shouldEnable];
}

/*!
* @brief Invoked when the state array changes
 *
 * This method is invoked when the state array changes.  In response, we hold onto the new array and refresh our state
 * list.
 */
- (void)stateArrayChanged:(NSNotification *)notification
{
	[stateArray release];
	stateArray = [[[adium statusController] stateArray] retain];

	[tableView_stateList reloadData];
}

//State Editing --------------------------------------------------------------------------------------------------------
#pragma mark State Editing
/*!
* @brief Edit the selected state
 *
 * Opens an edit state sheet for the selected state.  If the sheet is closed with success our
 * customStatusState:changedTo: method will be invoked and we can save the changes
 */
- (IBAction)editState:(id)sender
{
	int		selectedIndex = [tableView_stateList selectedRow];
	
	if(selectedIndex >= 0 && selectedIndex < [stateArray count]){
		AIStatus	*statusState = [stateArray objectAtIndex:selectedIndex];
		[AIEditStateWindowController editCustomState:statusState
											 forType:[statusState statusType]
										  andAccount:nil
											onWindow:[[self view] window]
									 notifyingTarget:self];
	}
}

/*!
* @brief State edited callback
 *
 * Invoked when the user successfully edits a state.  This method adds the new or updated state to Adium's state array.
 */
- (void)customStatusState:(AIStatus *)originalState changedTo:(AIStatus *)newState forAccount:(AIAccount *)account
{
	if(originalState){
		[[adium statusController] replaceExistingStatusState:originalState withStatusState:newState];
	}else{
		[[adium statusController] addStatusState:newState];
	}
}

/*!
* @brief Delete the selected state
 *
 * Deletes the selected state from Adium's state array.
 */
- (IBAction)deleteState:(id)sender
{
	int		selectedIndex = [tableView_stateList selectedRow];
	
	if(selectedIndex >= 0 && selectedIndex < [stateArray count]){
		[[adium statusController] removeStatusState:[stateArray objectAtIndex:selectedIndex]];
	}
}

/*!
* @brief Add a new state
 *
 * Creates a new state.  This is done by invoking an edit window without passing it a base state.  When the edit window
 * returns successfully, it will invoke our customStatusState:changedTo: which adds the new state to Adium's state
 * array.
 */
- (IBAction)newState:(id)sender
{
	[AIEditStateWindowController editCustomState:nil
										 forType:AIAwayStatusType
									  andAccount:nil
										onWindow:[[self view] window]
								 notifyingTarget:self];
}


//State List Table Delegate --------------------------------------------------------------------------------------------
#pragma mark State List (Table Delegate)
/*!
* @brief Number of rows
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([stateArray count]);
}

/*!
* @brief Table values
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString 		*identifier = [tableColumn identifier];
	AIStatus		*statusState = [stateArray objectAtIndex:row];
	
	if([identifier isEqualToString:@"icon"]){
		return([statusState icon]);
		
	}else if([identifier isEqualToString:@"name"]){
		return([statusState title]); 
		
	}
	
	return(nil);
}

/*!
* @brief Delete the selected row
 */
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteState:nil];
}

/*!
* @brief Selection change
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateTableControlAvailability];
}

/*!
* @brief Drag start
 */
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    tempDragState = [stateArray objectAtIndex:[[rows objectAtIndex:0] intValue]];
	
    [pboard declareTypes:[NSArray arrayWithObject:STATE_DRAG_TYPE] owner:self];
    [pboard setString:@"State" forType:STATE_DRAG_TYPE]; //Arbitrary state
    
    return(YES);
}

/*!
* @brief Drag validate
 */
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if(op == NSTableViewDropAbove && row != -1){
        return(NSDragOperationPrivate);
    }else{
        return(NSDragOperationNone);
    }
}

/*!
* @brief Drag complete
 */
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:STATE_DRAG_TYPE]];
	
    if([avaliableType isEqualToString:STATE_DRAG_TYPE]){
        int	newIndex;
		
        //Move the state and select it in the new location
        newIndex = [[adium statusController] moveStatusState:tempDragState toIndex:row];
        [tableView_stateList selectRow:newIndex byExtendingSelection:NO];
		
        return(YES);
    }else{
        return(NO);
    }
}

#pragma mark Other status-related controls

/*
 * @brief Configure initial values for idle, auto-away, etc., preferences.
 */

- (void)configureOtherControls
{
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_PREFERENCES];
	
	[checkBox_idle setState:[[prefDict objectForKey:KEY_STATUS_REPORT_IDLE] boolValue]];
	[textField_idleMinutes setDoubleValue:([[prefDict objectForKey:KEY_STATUS_REPORT_IDLE_INTERVAL] doubleValue] / 60.0)];
	
	[self configureControlDimming];
}

/*
 * @brief Configure control dimming for idle, auto-away, etc., preferences.
 */
- (void)configureControlDimming
{
	BOOL	idleControlsEnabled, autoAwayControlsEnabled;

	idleControlsEnabled = ([checkBox_idle state] == NSOnState);
	[textField_idleMinutes setEnabled:idleControlsEnabled];
	[stepper_idleMinutes setEnabled:idleControlsEnabled];
	
	autoAwayControlsEnabled = ([checkBox_autoAway state] == NSOnState);
	[popUp_autoAwayStatusState setEnabled:autoAwayControlsEnabled];
	[textField_autoAwayMinutes setEnabled:autoAwayControlsEnabled];
	[stepper_autoAwayMinutes setEnabled:autoAwayControlsEnabled];	
}

/*
 * @brief Change preference
 *
 * Sent when controls are clicked
 */
- (void)changePreference:(id)sender
{
	if(sender == checkBox_idle){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_REPORT_IDLE
											  group:PREF_GROUP_STATUS_PREFERENCES];
		[self configureControlDimming];
	}else if(sender == checkBox_autoAway){
		/*
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_STATUS_REPORT_IDLE
											  group:PREF_GROUP_STATUS_PREFERENCES];
		 */
		[self configureControlDimming];
	}
}

/*
 * @brief Control text did end editing
 *
 * In an attempt to get closer to a live-apply of preferences, save the preference when the
 * text field loses focus.  See saveTimeValues for more information.
 */
- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	[self saveTimeValues];
}

/*
 * @brief Save time text field values
 *
 * We can't get notified when the associated NSStepper is clicked, so we just save as requested.
 * This method should be called before the view closes.
 */
- (void)saveTimeValues
{
	[[adium preferenceController] setPreference:[NSNumber numberWithDouble:([textField_idleMinutes doubleValue]*60.0)]
										 forKey:KEY_STATUS_REPORT_IDLE_INTERVAL
										  group:PREF_GROUP_STATUS_PREFERENCES];

	/*
	[[adium preferenceController] setPreference:[NSNumber numberWithDouble:([textField_autoAwayMinutes doubleValue]*60.0)]
										 forKey:KEY_STATUS_REPORT_IDLE_INTERVAL
										  group:PREF_GROUP_STATUS_PREFERENCES];
	 */
}

@end
