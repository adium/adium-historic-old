/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIStateMenuPlugin.h"
#import "AIEditStateWindowController.h"

#define ELIPSIS_STRING				[NSString stringWithUTF8String:"…"]
#define STATE_TITLE_MENU_LENGTH		30

/*!
 * @class AIStateMenuPlugin
 * @brief Implements a list of preset states in the status menu
 *
 * This plugin places a list of preset states in the status menu, allowing the user to easily view and change the
 * active state.
 */
@implementation AIStateMenuPlugin

/*!
 * @brief Initialize the state menu plugin
 *
 * Initialize the state menu, registering this class as an observer for state array changes.  When anything related to
 * states changes we will be notified and will update our state menu as necessary.
 */
- (void)installPlugin
{
	//Observe changes to the state array and active state
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateStateMenuSelection)
									   name:AIActiveStatusStateChangedNotification
									 object:nil];
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateStateMenu)
									   name:AIStatusStateArrayChangedNotification
									 object:nil];

	//Observe status icon pack changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(statusIconSetDidChange:)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];
	
	//Prepare and build our user-defined state menu
	[self updateStateMenu];
}

/*!
 * Deallocate
 */
- (void)dealloc
{
	//Clean up
	[stateMenuItemArray release];
	[customStateMenuItem release];
	[selectedStateMenuItem release];
	
	//Stop observing
	[[adium notificationCenter] removeObserver:self];
	
	[super dealloc];
}

/*!
 * @brief Invoked when Adium's status icons have changed
 *
 * When the status icons change, update our menu to use the new icons.
 */
- (void)statusIconSetDidChange:(NSNotification *)aNotification
{
	[self updateStateMenu];
}

/*!
 * @brief Update the status menu
 *
 * Updates the status menu content to reflect the current state array.  This completely rebuilds the menu and will
 * call updateStateMenuSelection when it's done to re-select the active state.
 */
- (void)updateStateMenu
{
	NSEnumerator	*enumerator;
	NSMenuItem		*menuItem;
	AIStatus		*statusState;
	
	//Remove any existing menu items
	enumerator = [stateMenuItemArray objectEnumerator];
	while(menuItem = [enumerator nextObject]){
		[[adium menuController] removeMenuItem:menuItem];
	}
	[stateMenuItemArray release];
	stateMenuItemArray = [[NSMutableArray alloc] init];
	
	//Build the updated menu
	enumerator = [[[adium statusController] stateArray] objectEnumerator];
	while(statusState = [enumerator nextObject]){
		menuItem = [[NSMenuItem alloc] initWithTitle:[self titleForMenuDisplayOfState:statusState]
											  target:self
											  action:@selector(selectState:)
									   keyEquivalent:@""];
		
		[menuItem setImage:[[[statusState icon] copy] autorelease]];
		[menuItem setRepresentedObject:statusState];
		[stateMenuItemArray addObject:menuItem];
		[[adium menuController] addMenuItem:menuItem toLocation:LOC_Status_State];
		[menuItem release];
	}
	
	//Add the "Custom..." state option
	[customStateMenuItem release];
	customStateMenuItem = [[NSMenuItem alloc] initWithTitle:@"Custom..."
													 target:self
													 action:@selector(selectCustomState:)
											  keyEquivalent:@""];
	//[customStateMenuItem setImage:[AIStatusIcons statusIconForStatusID:@"unknown" type:AIStatusIconList direction:AIIconNormal]];
	[stateMenuItemArray addObject:customStateMenuItem];
	[[adium menuController] addMenuItem:customStateMenuItem toLocation:LOC_Status_State];
	
	//Re-fresh selection for the new menu
	[selectedStateMenuItem release]; selectedStateMenuItem = nil;
	[self updateStateMenuSelection];
}

/*!
 * @brief Update the selected state in our menu
 *
 * Updates the selected state in our menu to reflect the currently active state.
 */
- (void)updateStateMenuSelection
{
	//Deselect old menu item
	if(selectedStateMenuItem){
		[selectedStateMenuItem setState:NSOffState];
		[selectedStateMenuItem release];
		selectedStateMenuItem = nil;
	}
	
	//Select current one
	if([[adium statusController] activeStatusState]){
		int index = [[[adium statusController] stateArray] indexOfObject:[[adium statusController] activeStatusState]];
		
		if(index != NSNotFound){
			selectedStateMenuItem = [[stateMenuItemArray objectAtIndex:index] retain];
		}else{
			selectedStateMenuItem = [customStateMenuItem retain];
		}
		[selectedStateMenuItem setState:NSOnState];
	}
}

/*!
 * @brief Menu validation
 *
 * Our menu items should always be active, so always return YES for validation.
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	return(YES);
}

/*!
 * @brief Select a state menu item
 *
 * Invoked by a state menu item, sets the state corresponding to the menu item as the active state.
 */
- (void)selectState:(id)sender
{
	[[adium statusController] setActiveStatusState:[sender representedObject]];
}

/*!
 * @brief Select the custom state menu item
 *
 * Invoked by the custom state menu item, opens a custom state window.
 */
- (IBAction)selectCustomState:(id)sender
{
	[AIEditStateWindowController editCustomState:/*[[adium statusController] activeStatusState]*/nil
										onWindow:nil
								 notifyingTarget:self];
}

/*!
 * @brief Apply a custom state
 *
 * Invoked when the custom state window is closed by the user clicking OK.  In response this method sets the custom
 * state as the active state.
 */
- (void)customStatusState:(AIStatus *)originalState changedTo:(AIStatus *)newState
{
	[[adium statusController] setActiveStatusState:newState];
}

/*!
 * @brief Determine a string to use as a menu title
 *
 * This method truncates a state title string for display as a menu item.  It also strips newlines which can cause odd
 * menu item display.  Wide menus aren't pretty and may cause crashing in certain versions of OS X, so all state
 * titles should be run through this method before being used as menu item titles.
 *
 * @param statusState The state for which we want a title
 *
 * @result An appropriate NSString title
 */
- (NSString *)titleForMenuDisplayOfState:(AIStatus *)statusState
{
	NSRange		fullRange = NSMakeRange(0,0);
	NSRange		trimRange;
	NSString	*title = [statusState title];
	
	//Strip newlines, they'll screw up menu display
	title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	//Truncate by length
	trimRange = [title lineRangeForRange:fullRange];
	if(!NSEqualRanges(trimRange, NSMakeRange(0, [title length]-1))){
		title = [title substringWithRange:trimRange];
	}
	if([title length] > STATE_TITLE_MENU_LENGTH){
		title = [[title substringToIndex:STATE_TITLE_MENU_LENGTH] stringByAppendingString:ELIPSIS_STRING];
	}
	
	return(title);
}

@end
