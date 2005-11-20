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

#import "AIStateMenuPlugin.h"
#import "AIAccountController.h"
#import "AIEditStateWindowController.h"
#import "AIMenuController.h"
#import "AIStatusController.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIAccountMenu.h>
#import <Adium/AIAccount.h>

@interface AIStateMenuPlugin (PRIVATE)
- (void)updateKeyEquivalents;
@end

/*!
 * @class AIStateMenuPlugin
 * @brief Implements a list of preset states in the status menu
 *
 * This plugin places a list of preset states in the status menu, allowing the user to easily view and change the
 * active state.  It also manages a list of accounts in the status menu with associate statuses for setting account
 * statuses individually.
 */
@implementation AIStateMenuPlugin

/*!
 * @brief Initialize the state menu plugin
 *
 * Initialize the state menu, registering this class as a state menu plugin.  The status controller will then instruct
 * us to add and remove state menu items and handle all other details on its own.
 */
- (void)installPlugin
{
	//Wait for Adium to finish launching before we perform further actions
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self submenuType:AIAccountStatusSubmenu showTitleVerbs:NO] retain];

	dockStatusMenuRoot = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Status",nil)
																			  target:self
																			  action:@selector(dummyAction:)
																	   keyEquivalent:@""];
	[[adium menuController] addMenuItem:dockStatusMenuRoot toLocation:LOC_Dock_Status];

	[[adium statusController] registerStateMenuPlugin:self];


	[[adium notificationCenter] addObserver:self
								   selector:@selector(stateMenuSelectionsChanged:)
									   name:AIStatusStateMenuSelectionsChangedNotification
									 object:nil];
		
}

- (void)uninstallPlugin
{
	[[adium statusController] unregisterStateMenuPlugin:self];
	[[adium notificationCenter] removeObserver:self];
	
	[accountMenu release]; accountMenu = nil;
}

/*!
 * @brief Add state menu items to our location
 *
 * Implemented as required by the StateMenuPlugin protocol.  Also assigns key equivalents to appropriate
 * menu items depending on the current status.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be added to the menu
 */
- (void)addStateMenuItems:(NSArray *)menuItemArray
{
	NSEnumerator	*enumerator;
	NSMenuItem		*menuItem;
	NSMenu			*dockStatusMenu = [[NSMenu alloc] init];

	enumerator = [menuItemArray objectEnumerator];
    while ((menuItem = [enumerator nextObject])) {
		NSMenuItem	*dockMenuItem;

		[[adium menuController] addMenuItem:menuItem toLocation:LOC_Status_State];
		
		dockMenuItem = [menuItem copy];
		[dockStatusMenu addItem:dockMenuItem];
		[dockMenuItem release];
    }
	
	[dockStatusMenuRoot setSubmenu:dockStatusMenu];

	//Tell the status controller to update these items as necessary
	[[adium statusController] plugin:self didAddMenuItems:[dockStatusMenu itemArray]];
	[dockStatusMenu release];
	
	[currentMenuItemArray release]; currentMenuItemArray = [menuItemArray retain];
	[self updateKeyEquivalents];
}

/*!
 * @brief Remove state menu items from our location
 *
 * Implemented as required by the StateMenuPlugin protocol.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be removed from the menu
 */
- (void)removeStateMenuItems:(NSArray *)menuItemArray
{
	NSEnumerator	*enumerator = [menuItemArray objectEnumerator];
	NSMenuItem		*menuItem;
	
    while ((menuItem = [enumerator nextObject])) {    
        [[adium menuController] removeMenuItem:menuItem];
    }
	
	[dockStatusMenuRoot setSubmenu:nil];
	[currentMenuItemArray release]; currentMenuItemArray = nil;
}

- (void)dummyAction:(id)sender {};

/*!
 * @brief Update key equivalents for our main status menu
 *
 * When available, cmd-y is mapped to custom away.
 * When away, cmd-y is mapped to available and cmd-option-y is always mapped to custom away.
 */
- (void)updateKeyEquivalents
{
	NSEnumerator	*enumerator;
	NSMenuItem		*menuItem;

	AIStatusType	activeStatusType = [[adium statusController] activeStatusTypeTreatingInvisibleAsAway:YES];
	AIStatusType	targetStatusType = AIAvailableStatusType;
	AIStatus		*targetStatusState = nil;
	BOOL			assignCmdOptionY;
	
	if (activeStatusType == AIAvailableStatusType) {
		//If currently available, set an equivalent for the base away
		targetStatusType = AIAwayStatusType;
		targetStatusState = nil;
		assignCmdOptionY = NO;

	} else {
		//If away, invisible, or offline, set an equivalent for the available state
		targetStatusType = AIAvailableStatusType;		
		targetStatusState = [[adium statusController] defaultInitialStatusState];
		assignCmdOptionY = YES;
	}

	enumerator = [currentMenuItemArray objectEnumerator];
    while ((menuItem = [enumerator nextObject])) {
		AIStatus	*representedStatus = [[menuItem representedObject] objectForKey:@"AIStatus"];

		int			tag = [menuItem tag];
		if ((tag == targetStatusType) && 
		   (representedStatus == targetStatusState)) {			
			[menuItem setKeyEquivalent:@"y"];
			[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask];

		} else if (assignCmdOptionY && ((tag == AIAwayStatusType) && (representedStatus == nil))) {
			[menuItem setKeyEquivalent:@"y"];
			[menuItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
			
		} else if ((tag == AIAvailableStatusType) && (representedStatus == nil)) {
			[menuItem setKeyEquivalent:@"Y"];
			[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
			
		} else {
			[menuItem setKeyEquivalent:@""];
			
		}
	}
}

/*!
 * @brief State menu selections changed
 */
- (void)stateMenuSelectionsChanged:(NSNotification *)notification
{
	[self updateKeyEquivalents];
}

#pragma mark Account menu items

/*!
* @brief Add account menu items to our location
 *
 * Implemented as required by the AccountMenuPlugin protocol.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be added to the menu
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems
{
	NSEnumerator	*enumerator;
	NSMenuItem		*menuItem;
	
	//Remove any existing menu items
	enumerator = [installedMenuItems objectEnumerator];
    while ((menuItem = [enumerator nextObject])) {    
		[[adium menuController] removeMenuItem:menuItem];
    }
	
	//Add the new menu items
	enumerator = [menuItems objectEnumerator];
    while ((menuItem = [enumerator nextObject])) {    
		[[adium menuController] addMenuItem:menuItem toLocation:LOC_Status_Accounts];
    }
	
	//Remember the installed items so we can remove them later
	[installedMenuItems release]; 
	installedMenuItems = [menuItems retain];
}

- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[inAccount toggleOnline];
}

@end
