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

#import "AIStandardListWindowController.h"
#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIStatusController.h"
#import "AIToolbarController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>
#import <Adium/AIStatusMenu.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>

#define TOOLBAR_CONTACT_LIST				@"ContactList"				//Toolbar identifier

@interface AIStandardListWindowController (PRIVATE)
- (void)_configureToolbar;
- (void)activeStateChanged:(NSNotification *)notification;
@end

@implementation AIStandardListWindowController

/*
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init]))
	{
		toolbarItems = nil;
	}

	return self;
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];
	[toolbarItems release];
	
	[super dealloc];
}

/*
 * @brief Nib name
 */
- (NSString *)nibName
{
    return @"ContactListWindow";
}

/*
 * @brief Window loaded
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	[self _configureToolbar];
	[[self window] setTitle:AILocalizedString(@"Contacts","Contact List window title")];

	//Configure the state menu
	statusMenu = [[AIStatusMenu statusMenuWithDelegate:self] retain];
	
	[[popUp_state cell] setUsesItemFromMenu:NO];
	[[popUp_state cell] setAltersStateOfSelectedItem:NO];

	//Update the selections in our state menu when the active state changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(activeStateChanged:)
									   name:AIStatusActiveStateChangedNotification
									 object:nil];
	[self activeStateChanged:nil];
}

/*!
 * @brief Window closing
 */
- (void)windowWillClose:(id)sender
{
	[statusMenu release];
	
	[super windowWillClose:sender];
}

/*!
 * @brief Add state menu items to our location
 *
 * Implemented as required by the StateMenuPlugin protocol.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be added to the menu
 */
- (void)statusMenu:(AIStatusMenu *)inStatusMenu didRebuildStatusMenuItems:(NSArray *)menuItemArray
{
    NSMenu			*menu = [[NSMenu alloc] init];
	NSEnumerator	*enumerator = [menuItemArray objectEnumerator];
	NSMenuItem		*menuItem;
	
	//Add a dummy menu item for the pulldown to display
	[menu addItem:[[[NSMenuItem alloc] init] autorelease]];
	
	//Add a menu item for each state
	while ((menuItem = [enumerator nextObject])) {
		[menu addItem:menuItem];
	}
	
	[popUp_state setMenu:menu];
	[menu release];
}

/*
 * Update popup button to match selected menu item
 */
- (void)activeStateChanged:(NSNotification *)notification
{
	AIStatus	*activeStatus = [[adium statusController] activeStatusState];
	NSMenuItem	*menuItem = [[NSMenuItem alloc] initWithTitle:[activeStatus title]
													   target:self
													   action:@selector(selectCustomState:)
												keyEquivalent:@""];
	
	[menuItem setImage:[activeStatus icon]];

	[[popUp_state cell] setMenuItem:menuItem];
	[menuItem release];
}


//Toolbar --------------------------------------------------------------------------------------------------------------
#pragma mark Toolbar
//Install our toolbar
- (void)_configureToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_CONTACT_LIST] autorelease];
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode:NSToolbarSizeModeSmall];
    [toolbar setVisible:NO];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
	
    //
    toolbarItems = [[[adium toolbarController] toolbarItemsForToolbarTypes:[NSArray arrayWithObjects:@"General", @"ListObject", @"ContactList",nil]] retain];
	[[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return[NSArray arrayWithObjects:@"OfflineContacts", NSToolbarSeparatorItemIdentifier,
		@"ShowInfo", @"NewMessage", NSToolbarFlexibleSpaceItemIdentifier, @"AddContact", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil]];
}

- (void)windowDidToggleToolbarShown:(NSWindow *)sender
{
	[contactListController contactListDesiredSizeChanged];
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
	return [contactListController _desiredWindowFrameUsingDesiredWidth:YES
														 desiredHeight:YES];
}

#pragma mark Dock-like hiding

- (AIRectEdgeMask)slidableEdgesAdjacentToWindow
{
	// no edges are slidable if the window has a border.
	// Attempting to use -[NSWindow setFrame:display:animate:] to slide a bordered window off screen will 
	// cause the application to crash.  So why is Dock-like hiding implemented in AIListWindowController instead of 
	// AIBorderlessWindowController?  This is because it would be a good thing (tm) if we could make it work
	// for bordered windows as well.  We should try implementing -[NSWindow constrainFrameRect:toScreen:].
	return 0;
}

@end
