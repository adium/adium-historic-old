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

// $Id: AIToolbarController.m,v 1.13 2004/05/24 06:04:20 evands Exp $

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
    //Register Defaults
/*    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:TOOLBAR_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_TOOLBARS];
    
    NSEnumerator	*enumerator;
    NSString		*key;
    NSDictionary	*toolbarDict;

    //Load the toolbars and register them
    toolbarDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_TOOLBARS];
    enumerator = [[toolbarDict allKeys] objectEnumerator];
    while((key = [enumerator nextObject])){
        if([key hasPrefix:TOOLBAR_ITEMS_PREFIX]){
            NSString	*identifier = [key substringFromIndex:[(NSString *)TOOLBAR_ITEMS_PREFIX length]];
            NSArray	*items = [toolbarDict objectForKey:key];

            [[AIMiniToolbarCenter defaultCenter] setItems:items forToolbar:identifier];        
        }
    }*/

    //
    toolbarItems = [[NSMutableDictionary alloc] init];
    
    //Observe
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toolbarItemsChanged:) name:AIMiniToolbar_ItemsChanged object:nil];
    
}

//close
- (void)closeController
{
    //Make sure the toolbar customization palette is closed
/*    if([[AIMiniToolbarCenter defaultCenter] customizing:nil]){
        [[AIMiniToolbarCenter defaultCenter] endCustomization:nil];
    }*/
    
    //Toolbar configurations are saved as changes are made, no need to save them here.
}

//dealloc
- (void)dealloc
{
    [super dealloc];
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

//Private --------------------------------------------------------
//Called when the configuration of a toolbar changes
/*- (void)toolbarItemsChanged:(NSNotification *)notification
{
    NSString	*identifier = [notification object];
    NSArray	*toolbarItems = [[AIMiniToolbarCenter defaultCenter] itemsForToolbar:identifier];

    //Save the changes
    [[owner preferenceController] setPreference:toolbarItems forKey:[NSString stringWithFormat:@"ToolbarItems_%@",identifier] group:PREF_GROUP_TOOLBARS];
}*/

@end
