/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIContactSortSelectionPlugin.h"
#import "ESContactSortConfigurationWindowController.h"

#define CONTACT_SORTING_DEFAULT_PREFS	@"SortingDefaults"
#define CONFIGURE_SORT_MENU_TITLE		AILocalizedString(@"Configure Sort...",nil)
#define SORT_MENU_TITLE					AILocalizedString(@"Sort Contacts",nil)

@interface AIContactSortSelectionPlugin (PRIVATE)
- (void)sortControllerListChanged:(NSNotification *)notification;
- (NSMenu *)_sortSelectionMenu;
- (void)_setActiveSortControllerFromPreferences;
- (void)_setConfigureSortMenuItemTitleForController:(AISortController *)controller;
@end

@implementation AIContactSortSelectionPlugin

- (void)installPlugin
{
	enableConfigureSort = NO;
	menu_sortSubmenu = nil;
	
    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_SORTING_DEFAULT_PREFS 
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_CONTACT_SORTING];

	//Observe
    [[adium notificationCenter] addObserver:self
								   selector:@selector(sortControllerListChanged:)
									   name:Contact_SortSelectorListChanged 
									 object:nil];
	
	//Create the menu item
	menuItem_sort = [[[NSMenuItem alloc] initWithTitle:SORT_MENU_TITLE
												target:nil
												action:nil
										 keyEquivalent:@""] autorelease];
	
	//Add the menu item (which will have _sortSelectionMenu as its submenu)
	[[adium menuController] addMenuItem:menuItem_sort toLocation:LOC_View_Unnamed_A];
	
	[self sortControllerListChanged:nil];
}

//Our available sort controllers changed
- (void)sortControllerListChanged:(NSNotification *)notification
{
	AISortController	*activeSortController;
	int					index;

	//Inform the contactController of the active sort controller
	[self _setActiveSortControllerFromPreferences];
	
	[menu_sortSubmenu release];
	menu_sortSubmenu = [[self _sortSelectionMenu] retain];
	[menuItem_sort setSubmenu:menu_sortSubmenu];
	
	//Show a check by the active sort controller's menu item...
	activeSortController = [[adium contactController] activeSortController];

	index = [menu_sortSubmenu indexOfItemWithRepresentedObject:activeSortController];
	if (index != NSNotFound)
		[[menu_sortSubmenu itemAtIndex:index] setState:NSOnState];

	///...and set the Configure Sort menu title appropriately
	[self _setConfigureSortMenuItemTitleForController:activeSortController];
}

- (void)uninstallPlugin
{
	[menu_sortSubmenu release]; menu_sortSubmenu = nil;
}

//Tell the contactController the currently active sort controller based on the stored NSString* identifier
- (void)_setActiveSortControllerFromPreferences
{
	NSEnumerator				*enumerator;
	AISortController 			*controller;
	NSString					*identifier;
	
	//
	identifier = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_SORTING] objectForKey:KEY_CURRENT_SORT_MODE_IDENTIFIER];
	
	//
	enumerator = [[[adium contactController] sortControllerArray] objectEnumerator];
	while((controller = [enumerator nextObject])){
		if([identifier compare:[controller identifier]] == NSOrderedSame){
			[[adium contactController] setActiveSortController:controller];
			break;
		}
	}
	
	//Temporary failsafe for old preferences
	if (!controller)
		[[adium contactController] setActiveSortController:[[[adium contactController] sortControllerArray] objectAtIndex:0]];
}

//Menu of sort choices, a seperator, and the "configure sort" menu item
- (NSMenu *)_sortSelectionMenu
{
    NSMenu				*sortSelectionMenu;
    NSMenuItem			*menuItem;
    NSEnumerator		*enumerator;
	AISortController	*controller;
	
    //Create the menu
    sortSelectionMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	
	//Add each sort controller
	enumerator = [[[adium contactController] sortControllerArray] objectEnumerator];
	while((controller = [enumerator nextObject])){
		menuItem = [[[NSMenuItem alloc] initWithTitle:[controller displayName]
											   target:self
											   action:@selector(changedSortSelection:)
										keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:controller];
		[sortSelectionMenu addItem:menuItem];
	}
	
	//Add a seperator
	[sortSelectionMenu addItem:[NSMenuItem separatorItem]];
	
	//Add the menu item for configuring the sort
	menuItem_configureSort = [[[NSMenuItem alloc] initWithTitle:CONFIGURE_SORT_MENU_TITLE
														 target:self
														 action:@selector(configureSort:)
												  keyEquivalent:@""] autorelease];
	[sortSelectionMenu addItem:menuItem_configureSort];
	
	return sortSelectionMenu;
}

//Must be called by a menu item
- (void)changedSortSelection:(id)sender
{
	AISortController	*controller = [sender representedObject];
	
	//Uncheck the old active sort controller
	int index = [menu_sortSubmenu indexOfItemWithRepresentedObject:[[adium contactController] activeSortController]];
	if (index != NSNotFound)
		[[menu_sortSubmenu itemAtIndex:index] setState:NSOffState];
	
	//Save the new preference
	[[adium preferenceController] setPreference:[controller identifier] forKey:KEY_CURRENT_SORT_MODE_IDENTIFIER group:PREF_GROUP_CONTACT_SORTING];

	//Inform the contact controller of the new active sort controller
	[[adium contactController] setActiveSortController:controller];
	
	//Check the menu item and update the configure sort menu item title
	[sender setState:NSOnState];
	[self _setConfigureSortMenuItemTitleForController:controller];
}

//Update the "configure sort" menu item for controller
- (void)_setConfigureSortMenuItemTitleForController:(AISortController *)controller
{
	NSString *configureSortMenuItemTitle = [controller configureSortMenuItemTitle];
	if (configureSortMenuItemTitle) {
		[menuItem_configureSort setTitle:configureSortMenuItemTitle];
		enableConfigureSort = YES;
	} else {
		[menuItem_configureSort setTitle:CONFIGURE_SORT_MENU_TITLE];
		enableConfigureSort = NO;
	}
}

//Configure the currently active sort
- (void)configureSort:(id)sender
{
	AISortController *controller = [[adium contactController] activeSortController];
	[ESContactSortConfigurationWindowController showSortConfigurationWindowForController:controller];
}

//All memu items should always be enabled except for menuItem_configureSort, which may be disabled
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if (menuItem == menuItem_configureSort)
		return enableConfigureSort;
	else
		return YES;
}
@end
