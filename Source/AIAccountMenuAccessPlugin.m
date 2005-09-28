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

#import "AIAccountController.h"
#import "AIAccountMenuAccessPlugin.h"
#import "AIMenuController.h"
#import "AIAccountMenu.h"

/*!
 * @class AIAccountMenuAccessPlugin
 * @brief Provide menu access to account connection/disconnect
 */
@implementation AIAccountMenuAccessPlugin

/*!
 * @brief Install the plugin
 */
- (void)installPlugin
{
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self submenuType:AIAccountOptionsSubmenu showTitleVerbs:YES] retain];
}

/*!
 * @brief Uninstall Plugin
 */
- (void)uninstallPlugin
{
	[accountMenu release];
}

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
    while((menuItem = [enumerator nextObject])){    
		[[adium menuController] removeMenuItem:menuItem];
    }
	
	//Add the new menu items
	enumerator = [menuItems objectEnumerator];
    while ((menuItem = [enumerator nextObject])) {
		[[adium menuController] addMenuItem:menuItem toLocation:LOC_File_Additions];
    }
	
	//Remember the installed items so we can remove them later
	[installedMenuItems release]; 
	installedMenuItems = [menuItems retain];
}
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didSelectAccount:(AIAccount *)inAccount {
	[[adium accountController] toggleConnectionOfAccount:inAccount];
}

@end
