/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIMenuController.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

@interface AIMenuController (PRIVATE)
@end

@implementation AIMenuController

/*
    Outside code SHOULD USE the enum defined in Adium.h

    Since the internal locations of the menu items may change in the future, those values aren't used directly.  Instead, they're used to lookup the correct offset in locationArray of the desired menu.
*/
static int menuArrayOffset[] = {0,1,  2,3,4,5,6,7,  9,  10,11,12,  14,15,16,  17,18,19,  20,21,22,23,  24};

//init
- (void)initController
{
    //Build the array of menu locations
    locationArray = [[NSMutableArray alloc] initWithObjects:menu_Adium_About, menu_Adium_Preferences, menu_File_New, menu_File_Close, menu_File_Save, menu_File_Accounts, menu_File_Additions, menu_File_Status, menu_Edit_Bottom, menu_Edit_Additions, menu_Format_Styles, menu_Format_Palettes, menu_Format_Additions, menu_Window_Top, menu_Window_Commands, menu_Window_Auxilary, menu_Window_Fixed, menu_Help_Local, menu_Help_Web, menu_Help_Additions, menu_Contact_Manage, menu_Contact_Action, menu_Contact_NegativeAction, menu_Contact_Additions, menu_Dock_Status, nil];

    NSLog (@"Initialized menubar array");

    //Set up our contextual menu stuff
    contextualMenu = [[NSMenu alloc] init];
    contextualMenuItemDict = [[NSMutableDictionary alloc] init];
    contactualMenuContact = nil;
}

//close
- (void)closeController
{
    //There's no need to remove the menu items, the system will take them out for us.
    
    //Unless, of course, we are only switching users, and not quitting.  This might be better in a separate method,
    //not sure.
    /*NSMutableArray	*tempArray = [[NSMutableArray alloc] initWithObjects:menu_Adium_About, menu_Adium_Preferences, menu_File_New, menu_File_Close, menu_File_Save, menu_File_Accounts, menu_File_Additions, menu_File_Status, menu_Edit_Bottom, menu_Edit_Additions, menu_Format_Styles, menu_Format_Palettes, menu_Format_Additions, menu_Window_Top, menu_Window_Commands, menu_Window_Auxilary, menu_Window_Fixed, menu_Help_Local, menu_Help_Web, menu_Help_Additions, menu_Contact_Manage, menu_Contact_Action, menu_Contact_NegativeAction, menu_Contact_Additions, menu_Dock_Status, nil];
    int i, o;
    
    for (o = i = 0; i < [tempArray count]; i++, o++)
    {
        if (menuArrayOffset[o] != i)
            i = menuArrayOffset[o];
    
        NSMenuItem *topItem = [[tempArray objectAtIndex:i] retain],
                   *lastItem = [locationArray objectAtIndex:i],
                   *curItem = lastItem;
        NSMenu	   *targetMenu = [curItem menu]; 
        int			curCount = 1, ind = [targetMenu indexOfItem:topItem] + 1, count = [targetMenu indexOfItem:lastItem] - [targetMenu indexOfItem:topItem];
        
        NSLog (@"About to remove item %@", curItem);
        while (curItem != topItem)
        //for (; curCount <= count; curCount ++)
        {
            int nextInd = [targetMenu indexOfItem:curItem] - 1;
            //curItem = [targetMenu itemAtIndex:ind];
            NSLog (@"Removing item %@", curItem);
            
            if (nextInd >= 0)
            {
                [targetMenu removeItem:curItem];
            
                curItem = [targetMenu itemAtIndex:nextInd];
            }
            else
            {
                NSLog (@"Couldn't remove item %@", curItem);
                curItem = topItem;
                //ind++;
            }
        }
    }
    
    [tempArray release];*/
    
    // Releases to match allocs in initController
    [locationArray release];
    [contactualMenuContact release];
}

- (void)dealloc
{
    //[locationArray release];
    //[contactualMenuContact release];

    [super dealloc];
}

//Add a menu item
- (void)addMenuItem:(NSMenuItem *)newItem toLocation:(MENU_LOCATION)location
{
    NSMenuItem		*menuItem;
    NSMenu		*targetMenu;
    int			targetIndex;
    int			destination;
    
    NSLog (@"Adding menuitem %@", newItem);
    //Offset
    location = menuArrayOffset[location];

    //Find the menu item (or the closest one above it)
    destination = location;
    menuItem = [locationArray objectAtIndex:destination];
    while(menuItem == nilMenuItem){
        destination--;
        menuItem = [locationArray objectAtIndex:destination];
    }
    NSLog (@"Here?");
    targetMenu = [menuItem menu];
    NSLog (@"no");
    targetIndex = [targetMenu indexOfItem:menuItem];
    
    //Insert the new item and a divider (if necessary)
    if(location != destination){
        [targetMenu insertItem:[NSMenuItem separatorItem] atIndex:targetIndex+1];
        targetIndex++;
    }
    [targetMenu insertItem:newItem atIndex:targetIndex+1];

    //update the location array
    [locationArray replaceObjectAtIndex:location withObject:newItem];
    NSLog (@"Done adding menuitem %@", newItem);
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
        if(menuItem == targetItem){
            NSMenuItem	*previousItem = [targetMenu itemAtIndex:(targetIndex - 1)];
            
            if([previousItem isSeparatorItem]){
                [locationArray replaceObjectAtIndex:loop withObject:nilMenuItem];
            }else{
                [locationArray replaceObjectAtIndex:loop withObject:previousItem];
            }
        }
    }
    
    //Remove the item
    [targetMenu removeItem:targetItem];

    //Remove any double dividers
    for(loop = 0;loop < [targetMenu numberOfItems]-1;loop++){
        if([[targetMenu itemAtIndex:loop] isSeparatorItem] && [[targetMenu itemAtIndex:loop+1] isSeparatorItem]){
            [targetMenu removeItemAtIndex:loop];
            loop--;//research the location
        }
    }
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
- (NSMenu *)contextualMenuWithLocations:(NSArray *)inLocationArray forContact:(AIListContact *)inContact
{
    NSEnumerator	*enumerator;
    NSNumber		*location;
    NSEnumerator	*itemEnumerator;
    NSMenuItem		*menuItem;
    BOOL		itemsAbove = NO;
    
    //Remove all items from the existing menu
    [contextualMenu removeAllItems];

    //Remember what our menu is configured for
    [contactualMenuContact release];
    contactualMenuContact = [inContact retain];

    //Process each specified location
    enumerator = [inLocationArray objectEnumerator];
    while((location = [enumerator nextObject])){
        //Add a seperator
        if(itemsAbove){
            [contextualMenu addItem:[NSMenuItem separatorItem]];
            itemsAbove = NO;
        }
        
        //Add each menu item in the location
        itemEnumerator = [[contextualMenuItemDict objectForKey:location] objectEnumerator];
        while((menuItem = [itemEnumerator nextObject])){
            //Add the menu item
            [contextualMenu addItem:menuItem];
            itemsAbove = YES;
        }
    }

    return(contextualMenu);
}

- (AIListContact *)contactualMenuContact
{
    return(contactualMenuContact);
}


@end









