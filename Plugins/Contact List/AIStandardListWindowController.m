//
//  AIStandardListWindowController.m
//  Adium
//
//  Created by Adam Iser on Mon Jul 26 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIStandardListWindowController.h"

#define TOOLBAR_CONTACT_LIST				@"ContactList"				//Toolbar identifier

@interface AIStandardListWindowController (PRIVATE)
- (void)_configureToolbar;
@end

@implementation AIStandardListWindowController

//Init
- (id)init
{
	[super init];
	
	toolbarItems = nil;

	return(self);
}

- (void)dealloc
{
	[toolbarItems release];
	
	[super dealloc];
}

//Borderless nib
- (NSString *)nibName
{
    return(@"ContactListWindow");    
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	[self _configureToolbar];
	
	//Configure the state menu
	[[popUp_state menu] removeAllItems];
	[[adium statusController] registerStateMenuPlugin:self];

	//Update the selections in our state menu when the active state changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(activeStateChanged:)
									   name:AIActiveStatusStateChangedNotification
									 object:nil];
	[self activeStateChanged:nil];
}

/*
 * @brief Add state menu items to our location
 *
 * Implemented as required by the StateMenuPlugin protocol.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be added to the menu
 */
- (void)addStateMenuItems:(NSArray *)menuItemArray
{
	NSEnumerator	*enumerator = [menuItemArray objectEnumerator];
	NSMenuItem		*menuItem;
	
    while((menuItem = [enumerator nextObject])){
		[[popUp_state menu] addItem:menuItem];
    }
}

/*
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
	
    while((menuItem = [enumerator nextObject])){    
		[[popUp_state menu] removeItem:menuItem];
    }
}

/*
 * Update popup button to match selected menu item
 *
 * The popup button needs an extra push to update its display to match the active item in the menu.
 */
- (void)activeStateChanged:(NSNotification *)notification
{
	int	index = [popUp_state indexOfItemWithRepresentedObject:[notification object]];
	
	if(index >= 0 && index < [popUp_state numberOfItems]){
		[popUp_state selectItemAtIndex:index];
	}else{
		[popUp_state selectItem:[popUp_state lastItem]];
	}
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
    return([AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier]);
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return([NSArray arrayWithObjects:@"ShowPreferences",@"NewMessage",@"ShowInfo",nil]);
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return([[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil]]);
}

- (void)windowDidToggleToolbarShown:(NSWindow *)sender
{
	[contactListController contactListDesiredSizeChanged];
}

@end
