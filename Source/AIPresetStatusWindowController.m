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

#import "AIPresetStatusWindowController.h"
#import "AIEditStateWindowController.h"
#import "AIStatusController.h"
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>

#define STATE_DRAG_TYPE	@"AIState"

/*!
 * @class AIPresetStatusWindowController
 * @brief A window that displays and allows editing of preset states
 *
 * This class provides a window which lists and allows creating, deleting, re-arranging, and editing of preset states.
 */
@implementation AIPresetStatusWindowController

/*!
 * @brief Returns the shared preset status window
 *
 * Creates (if necessary) the preset status window and returns it.  If a preset status window already exists it will
 * be returned.
 */
AIPresetStatusWindowController *sharedStatusWindowInstance = nil;
+ (AIPresetStatusWindowController *)presetStatusWindowController
{
    if(!sharedStatusWindowInstance){
        sharedStatusWindowInstance = [[self alloc] initWithWindowNibName:@"PresetStatusWindow"];
    }
    return(sharedStatusWindowInstance);
}

/*!
 * Deallocate
 */
- (void)dealloc
{    
	[stateArray release];
    [super dealloc];
}

/*!
 * Configure the window after it loads
 */
- (void)windowDidLoad
{
	//Center the window
	[[self window] center];
	
	//Configure the controls
	[self configureStateList];
	[button_editState setTitle:@"Edit"];

	//Register as an observer of state array changes, we'll need to refresh our list in response to these
	[[adium notificationCenter] addObserver:self
								   selector:@selector(stateArrayChanged:)
									   name:AIStatusStateArrayChangedNotification
									 object:nil];
	[self stateArrayChanged:nil];
}

/*!
 * @brief Window should close
 *
 * Invoked before our window is closed.  We always allow closing of the state window, so always return YES here.
 */
- (BOOL)windowShouldClose:(id)sender
{
	return(YES);
}

/*!
 * @brief Frame save name
 *
 * Return a frame save name so Adium saves our window position & size
 */
- (NSString *)adiumFrameAutosaveName
{
	return(@"AIPresetStatusWindow");
}

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
	[tableView_stateList setDoubleAction:@selector(editState:)];
	[tableView_stateList setIntercellSpacing:NSMakeSize(4,4)];
    [scrollView_stateList setAutoHideScrollBar:YES];
	
	//Enable dragging of states
	[tableView_stateList registerForDraggedTypes:[NSArray arrayWithObjects:STATE_DRAG_TYPE,nil]];
	
    //Custom vertically-centered text cell for account names
    cell = [[AIVerticallyCenteredTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:13]];
    [[tableView_stateList tableColumnWithIdentifier:@"name"] setDataCell:cell];
	[cell release];
}

/*!
 * @brief Update control availability
 *
 * Updates control availability based on the current state selection.  If no states are selected this method dims the
 * edit and delete buttons since they require a selection to function.
 */
- (void)updateControlAvailability
{
	BOOL	selection = ([tableView_stateList selectedRow] != -1);
	
	[button_editState setEnabled:selection];
	[button_deleteState setEnabled:selection];
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
		[AIEditStateWindowController editCustomState:[stateArray objectAtIndex:selectedIndex]
											onWindow:[self window]
									 notifyingTarget:self];
	}
}

/*!
 * @brief State edited callback
 *
 * Invoked when the user successfully edits a state.  This method adds the new or updated state to Adium's state array.
 */
- (void)customStatusState:(AIStatus *)originalState changedTo:(AIStatus *)newState
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
										onWindow:[self window]
								 notifyingTarget:self];
}


//State List Table Delegate --------------------------------------------------------------------------------------------
#pragma mark State List (Table Delegate)
/*
 * @brief Number of rows
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([stateArray count]);
}

/*
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

/*
 * @brief Delete the selected row
 */
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteState:nil];
}

/*
 * @brief Selection change
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateControlAvailability];
}
	
/*
 * @brief Drag start
 */
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    tempDragState = [stateArray objectAtIndex:[[rows objectAtIndex:0] intValue]];
	
    [pboard declareTypes:[NSArray arrayWithObject:STATE_DRAG_TYPE] owner:self];
    [pboard setString:@"State" forType:STATE_DRAG_TYPE]; //Arbitrary state
    
    return(YES);
}

/*
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

/*
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

@end
