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

// $Id$

#import "AIMenuController.h"

@interface AIMenuController (PRIVATE)
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray usingMenu:(NSMenu *)inMenu;
- (void)addMenuItemsForContact:(AIListContact *)inContact toMenu:(NSMenu *)workingMenu separatorItem:(BOOL *)separatorItem;
@end

@implementation AIMenuController

//Init
- (void)initController
{
    //Build the array of menu locations
    locationArray = [[NSMutableArray alloc] initWithObjects:menu_Adium_About, menu_Adium_Preferences,
		menu_File_New, menu_File_Close, menu_File_Save, menu_File_Accounts, menu_File_Additions, menu_File_Status,
		menu_Edit_Bottom, menu_Edit_Additions,
		menu_Format_Styles, menu_Format_Palettes, menu_Format_Additions,
		menu_Window_Top, menu_Window_Commands, menu_Window_Auxiliary, menu_Window_Fixed,
		menu_Help_Local, menu_Help_Web, menu_Help_Additions,
		menu_Contact_Editing, menu_Contact_Manage, menu_Contact_Action, menu_Contact_NegativeAction, menu_Contact_Additions,
		menu_View_General, menu_View_Unnamed_A, menu_View_Unnamed_B, menu_View_Unnamed_C, 
		menu_Dock_Status, nil];
	
    //Set up our contextual menu stuff
    contextualMenu = [[NSMenu alloc] init];
    contextualMenuItemDict = [[NSMutableDictionary alloc] init];
    contactualMenuContact = nil;
    textViewContextualMenu = [[NSMenu alloc] init];
    contextualMenu_TextView = nil;
}

//Close
- (void)closeController
{
    //There's no need to remove the menu items, the system will take them out for us.
}

- (void)dealloc
{
    [super dealloc];
}

//Add a menu item
- (void)addMenuItem:(NSMenuItem *)newItem toLocation:(MENU_LOCATION)location
{
    NSMenuItem  *menuItem;
    NSMenu		*targetMenu = nil;
    int			targetIndex;
    int			destination;
    
    //Find the menu item (or the closest one above it)
    destination = location;
    menuItem = [locationArray objectAtIndex:destination];
    if([menuItem isKindOfClass:[NSMenuItem class]]){
		while((menuItem == nilMenuItem) && (destination > 0)){
			destination--;
			menuItem = [locationArray objectAtIndex:destination];
		}
		targetMenu = [menuItem menu];
		targetIndex = [targetMenu indexOfItem:menuItem];
		
		//Insert the new item and a divider (if necessary)
		if(location != destination){
			[targetMenu insertItem:[NSMenuItem separatorItem] atIndex:targetIndex+1];
			targetIndex++;
		}
		[targetMenu insertItem:newItem atIndex:targetIndex+1];
    }else{
		//If it's attached to an NSMenu (and not an NSMenuItem), insert at the top of the menu
		[(NSMenu *)menuItem insertItem:newItem atIndex:0];
    }
    
    //update the location array
    [locationArray replaceObjectAtIndex:location withObject:newItem];
	
	[[adium notificationCenter] postNotificationName:Menu_didChange object:[newItem menu] userInfo:nil];
}

//Remove a menu item
- (void)removeMenuItem:(NSMenuItem *)targetItem
{
    NSMenu	*targetMenu = [targetItem menu];
    int		targetIndex = [targetMenu indexOfItem:targetItem];
    int		loop;

    //Fix the pointer if this is one
    for(loop = 0; loop < [locationArray count];loop++){
        NSMenuItem	*menuItem = [locationArray objectAtIndex:loop];
		
        //Move to the item above it, nil if a divider
		if(targetIndex != 0){
			if(menuItem == targetItem){
				NSMenuItem	*previousItem = [targetMenu itemAtIndex:(targetIndex - 1)];
				
				if([previousItem isSeparatorItem]){
					[locationArray replaceObjectAtIndex:loop withObject:nilMenuItem];
				}else{
					[locationArray replaceObjectAtIndex:loop withObject:previousItem];
				}
			}
		}else{
			//If there are no more items, attach to the menu
			[locationArray replaceObjectAtIndex:loop withObject:targetMenu];
		}
    }
    
    //Remove the item
    [targetMenu removeItem:targetItem];

    //Remove any double dividers (And dividers at the bottom)
    for(loop = 0;loop < [targetMenu numberOfItems];loop++){
        if(([[targetMenu itemAtIndex:loop] isSeparatorItem]) && 
		   (loop == [targetMenu numberOfItems]-1 || [[targetMenu itemAtIndex:loop+1] isSeparatorItem])){
            [targetMenu removeItemAtIndex:loop];
            loop--;//re-search the location
        }
    }
	
	[[adium notificationCenter] postNotificationName:Menu_didChange object:targetMenu userInfo:nil];
}

- (void)addContextualMenuItem:(NSMenuItem *)newItem toLocation:(CONTEXT_MENU_LOCATION)location
{
    NSNumber			*key;
    NSMutableArray		*itemArray;

    //Search for an existing item array for menu items in this location
    key = [NSNumber numberWithInt:location];
    itemArray = [contextualMenuItemDict objectForKey:key];

    //If one is not found, create it
    if(!itemArray){
        itemArray = [[NSMutableArray alloc] init];
        [contextualMenuItemDict setObject:itemArray forKey:key];
    }

    //Add the passed menu item to the array
    [itemArray addObject:newItem];
}

//Pass an array of NSNumbers corresponding to the desired contextual menu locations
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forListObject:(AIListObject *)inObject
{
	NSMenu		*workingMenu;
	BOOL		separatorItem;
	
	//Remember what our menu is configured for
    [contactualMenuContact release];
    contactualMenuContact = [inObject retain];
	
	//Get the pre-created contextual menu items
	workingMenu = [self contextualMenuWithLocations:inLocationArray usingMenu:contextualMenu];
	
	//Add any account-specific menu items
	separatorItem = YES;
	if([inObject isKindOfClass:[AIMetaContact class]]){
		NSEnumerator	*enumerator;
		AIListContact	*aListContact;
		enumerator = [[(AIMetaContact *)inObject listContacts] objectEnumerator];
		
		while(aListContact = [enumerator nextObject]){
			[self addMenuItemsForContact:aListContact
								  toMenu:workingMenu
						   separatorItem:&separatorItem];	
		}

	}else if([inObject isKindOfClass:[AIListContact class]]){
		[self addMenuItemsForContact:(AIListContact *)inObject
							  toMenu:workingMenu
					   separatorItem:&separatorItem];
	}
	
	return(workingMenu);
}

//Add menuItems for a passed contact to a specified menu.  *seperatorItem can be YES to indicate that a 
//separator item should be inserted before the menu items if desired. It will then be set to NO.
- (void)addMenuItemsForContact:(AIListContact *)inContact toMenu:(NSMenu *)workingMenu separatorItem:(BOOL *)separatorItem
{
	NSArray			*itemArray = [[inContact account] menuItemsForContact:inContact];
	
	if(itemArray && [itemArray count]){
		NSEnumerator	*enumerator;
		NSMenuItem		*menuItem;
		
		if(*separatorItem == YES){
			[workingMenu addItem:[NSMenuItem separatorItem]];
			*separatorItem = NO;
		}

		enumerator = [itemArray objectEnumerator];
		while(menuItem = [enumerator nextObject]){
			[workingMenu addItem:menuItem];
		}
	}
}

- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forTextView:(NSTextView *)inObject
{
    //remember menu config
    [contextualMenu_TextView release];
    contextualMenu_TextView = [inObject retain];
	
	return([self contextualMenuWithLocations:inLocationArray usingMenu:textViewContextualMenu]);
}

- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray usingMenu:(NSMenu *)inMenu
{
    NSEnumerator	*enumerator;
    NSNumber		*location;
    NSMenuItem		*menuItem;
    BOOL		itemsAbove = NO;
    
    //Remove all items from the existing menu
    [inMenu removeAllItems];
 
    //Process each specified location
    enumerator = [inLocationArray objectEnumerator];
    while((location = [enumerator nextObject])){
        NSArray			*menuItems = [contextualMenuItemDict objectForKey:location];
        NSEnumerator	*itemEnumerator;
        
        //Add a seperator
        if(itemsAbove && [menuItems count]){
            [inMenu addItem:[NSMenuItem separatorItem]];
            itemsAbove = NO;
        }
        
        //Add each menu item in the location
        itemEnumerator = [menuItems objectEnumerator];
        while((menuItem = [itemEnumerator nextObject])){
            //Add the menu item
            [inMenu addItem:menuItem];
            itemsAbove = YES;
        }
    }

    return(inMenu);
}

- (AIListContact *)contactualMenuContact
{
    return(contactualMenuContact);
}

- (NSTextView *)contextualMenuTextView
{
    return(contextualMenu_TextView);
}

- (void)removeItalicsKeyEquivalent
{
    [menuItem_Format_Italics setKeyEquivalent:@""];
}

- (void)restoreItalicsKeyEquivalent
{
    [menuItem_Format_Italics setKeyEquivalent:@"i"];    
}

@end

