/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@interface AIMenuController (PRIVATE)
@end

@implementation AIMenuController

/*
    Outside code SHOULD USE the enum defined in Adium.h

    Since the internal locations of the menu items may change in the future, those values aren't used directly.  Instead, they're used to lookup the correct offset in locationArray of the desired menu.
*/
static int menuArrayOffset[] = {0,1,  2,3,4,5,6,7,  9,  10,11,12,  14,15,16,  17,18,19,  20,21,22,23};

//init
- (void)initController
{
    //Build the array of menu locations
    locationArray = [[NSMutableArray alloc] initWithObjects:menu_Adium_About, menu_Adium_Preferences, menu_File_New, menu_File_Close, menu_File_Save, menu_File_Accounts, menu_File_Additions, menu_File_Status, menu_Edit_Bottom, menu_Edit_Additions, menu_Format_Styles, menu_Format_Palettes, menu_Format_Additions, menu_Window_Top, menu_Window_Commands, menu_Window_Auxilary, menu_Window_Fixed, menu_Help_Local, menu_Help_Web, menu_Help_Additions, menu_Contact_Manage, menu_Contact_Action, menu_Contact_NegativeAction, menu_Contact_Additions, nil];
}

//close
- (void)closeController
{
    //There's no need to remove the menu items, the system will take them out for us.
}

- (void)dealloc
{
    [locationArray release]; locationArray = nil;

    [super dealloc];
}

//Add a menu item
- (void)addMenuItem:(NSMenuItem *)newItem toLocation:(MENU_LOCATION)location
{
    NSMenuItem		*menuItem;
    NSMenu		*targetMenu;
    int			targetIndex;
    int			destination;
    
    //Offset
    location = menuArrayOffset[location];

    //Find the menu item (or the closest one above it)
    destination = location;
    menuItem = [locationArray objectAtIndex:destination];
    while(menuItem == nilMenuItem){
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

    //update the location array
    [locationArray replaceObjectAtIndex:location withObject:newItem];
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


@end
