/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIAccountMenuAccessPlugin.h"

/*
 * @class AIAccountMenuAccessPlugin
 * @brief Provide menu access to account connection/disconnect
 */
@implementation AIAccountMenuAccessPlugin

/*
 * @brief Install the plugin
 */
- (void)installPlugin
{
	[[adium accountController] registerAccountMenuPlugin:self];
}

/*
 * @brief Identifier as an account menu plugin
 *
 * Implemented as required by the AccountMenuPlugin protocol
 */
- (NSString *)identifier
{
	return(@"AccountMenuAccess");
}

/*
 * @brief Add account menu items to our location
 *
 * Implemented as required by the AccountMenuPlugin protocol.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be added to the menu
 */
- (void)addAccountMenuItems:(NSArray *)menuItemArray
{
	NSEnumerator	*enumerator = [menuItemArray objectEnumerator];
	NSMenuItem		*menuItem;
	
    while((menuItem = [enumerator nextObject])){    
		[[adium menuController] addMenuItem:menuItem toLocation:LOC_Status_Accounts];
    }
}

/*
 * @brief Remove account menu items from our location
 *
 * Implemented as required by the AccountMenuPlugin protocol.
 *
 * @param menuItemArray An <tt>NSArray</tt> of <tt>NSMenuItem</tt> objects to be removed from the menu
 */
- (void)removeAccountMenuItems:(NSArray *)menuItemArray
{
	NSEnumerator	*enumerator = [menuItemArray objectEnumerator];
	NSMenuItem		*menuItem;

    while((menuItem = [enumerator nextObject])){    
        [[adium menuController] removeMenuItem:menuItem];
    }
}

/*
 * @brief Uninstall Plugin
 */
- (void)uninstallPlugin
{
    //Stop observing/receiving notifications
	[[adium accountController] unregisterAccountMenuPlugin:self];
}

@end
