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

#import "AIAccountListPreferencesPlugin.h"
#import "AIAccountListWindowController.h"

@implementation AIAccountListPreferencesPlugin

#define ACCOUNT_MENU_TITLE		@"Accounts..."
#define ACCOUNT_EDIT_MENU_TITLE	@"Edit Accounts..."

//Register our preference pane
- (void)installPlugin
{
	NSMenuItem	*menuItem;
	
	//Install our menu items.
	//We actually have two menu items for accessing the account preferences.  A lot of users will instinctively check
	//the "Adium" menu for accounts.  Others will be looking in "Adium" for preferences (assuming our accounts are
	//in preferences), and find the accounts menu item in the process.  Adding an "Edit accounts" in the status menu
	//keeps consistency with the "Edit status" menu item, in addition to providing a nearby way to edit the account
	//list visible in that menu.

    //Adium menu item
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ACCOUNT_MENU_TITLE
																	 target:self
																	 action:@selector(showAccountWindow:)
															  keyEquivalent:@"a"] autorelease];
	[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSShiftKeyMask];
    [[adium menuController] addMenuItem:menuItem toLocation:LOC_Adium_Preferences];

	//Status menu item
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ACCOUNT_EDIT_MENU_TITLE
																	target:self
																	action:@selector(showAccountWindow:)
															 keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem toLocation:LOC_Status_Additions];
}

- (IBAction)showAccountWindow:(id)sender
{
	[[AIAccountListWindowController accountListWindowController] showWindow:nil];
}

@end
