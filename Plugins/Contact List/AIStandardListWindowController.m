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
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>

#define TOOLBAR_CONTACT_LIST				@"ContactList"				//Toolbar identifier

@interface AIStandardListWindowController (PRIVATE)
- (void)_configureToolbar;
- (void)activeStateChanged:(NSNotification *)notification;
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
									   name:AIStatusStateArrayChangedNotification
									 object:nil];
	[self activeStateChanged:nil];
	
	[[adium contactController] registerListObjectObserver:self];
}

/*!
 * @brief Window should close?
 */
- (BOOL)windowShouldClose:(id)sender
{
	[[adium contactController] unregisterListObjectObserver:self];
	
	return [super windowShouldClose:sender];
}

/*!
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
	if([[adium accountController] oneOrMoreConnectedAccounts]){
		AIStatus	*activeStatusState;
		NSArray		*stateArrayForMenuItems;
		unsigned	index, numberOfItems;

		activeStatusState = [[adium statusController] activeStatusState];;
		stateArrayForMenuItems = [[adium statusController] stateArrayForMenuItems];
		numberOfItems =  [popUp_state numberOfItems];;

		if([stateArrayForMenuItems containsObjectIdenticalTo:activeStatusState]){
			for(index = 0 ; index < numberOfItems ; index++){
				NSMenuItem	*menuItem = [popUp_state itemAtIndex:index];
				if(activeStatusState == [[menuItem representedObject] objectForKey:@"AIStatus"]){
					[popUp_state selectItemAtIndex:index];
					break;
				}
			}
		}else{
			//A custom state is active
			AIStatusType statusType = [activeStatusState statusType];
			
			for(index = 0 ; index < numberOfItems ; index++){
				NSMenuItem	*menuItem = [popUp_state itemAtIndex:index];
				
				//Find the menu item with the appropriate tag and no AIStatus associated with it
				if(([menuItem tag] == statusType) && ([[menuItem representedObject] objectForKey:@"AIStatus"] == nil)){
					[popUp_state selectItemAtIndex:index];
					break;
				}
				
			}
		}
	}else{
		//Offline
		[popUp_state selectItemAtIndex:[popUp_state indexOfItemWithTag:AIOfflineStatusType]];		
	}
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if([inObject isKindOfClass:[AIAccount class]]){
		if([inModifiedKeys containsObject:@"Online"] ||
		   [inModifiedKeys containsObject:@"StatusState"]){
			
			[self activeStateChanged:nil];
		}
	}
    
    return(nil);
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
