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

// $Id$

#import "AIToolbarController.h"

#define TOOLBAR_DEFAULT_PREFS                   @"ToolbarPrefs"
#define TOOLBAR_ITEMS_PREFIX			@"ToolbarItems_"

@interface AIToolbarController (PRIVATE)
- (void)toolbarItemsChanged:(NSNotification *)notification;
@end

@implementation AIToolbarController

//Internal --------------------------------------------------------
//init
- (void)initController
{
    toolbarItems = [[NSMutableDictionary alloc] init];
    
}

//close
- (void)closeController
{

}

//
- (void)registerToolbarItem:(NSToolbarItem *)item forToolbarType:(NSString *)type
{
    NSMutableDictionary    *itemDict = [toolbarItems objectForKey:type];
	
    if(!itemDict){
		itemDict = [NSMutableDictionary dictionary];
		[toolbarItems setObject:itemDict forKey:type];
    }
	
    [itemDict setObject:item forKey:[item itemIdentifier]];
}

- (void)unregisterToolbarItem:(NSToolbarItem *)item forToolbarType:(NSString *)type
{
    NSMutableDictionary    *itemDict = [toolbarItems objectForKey:type];
    [itemDict removeObjectForKey:[item itemIdentifier]];
}


//
- (NSDictionary *)toolbarItemsForToolbarTypes:(NSArray *)types
{
    NSMutableDictionary *items = [NSMutableDictionary dictionary];
    NSEnumerator	*enumerator;
    NSString		*type;
    
    //Add our toolbar items
    enumerator = [types objectEnumerator];
    while(type = [enumerator nextObject]){
		NSDictionary     *availableItems = [toolbarItems objectForKey:type];
		if(availableItems){
			[items addEntriesFromDictionary:availableItems];
		}
    }
	
    return(items);
}

@end
