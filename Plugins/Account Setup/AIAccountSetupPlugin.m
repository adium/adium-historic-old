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

#import "AIAccountSetupPlugin.h"
#import "AIAccountSetupWindowController.h"

@implementation AIAccountSetupPlugin

#define ACCOUNT_SETUP_MENU_TITLE		@"Accountz..."

//Register our preference pane
- (void)installPlugin
{
	NSMenuItem	*menuItem;
	
    //Add/Edit Link... menu item (edit menu)
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ACCOUNT_SETUP_MENU_TITLE
																	 target:self
																	 action:@selector(showAccountWindow:)
															  keyEquivalent:@"a"] autorelease];
	[menuItem setKeyEquivalentModifierMask:NSCommandKeyMask | NSShiftKeyMask];
    [[adium menuController] addMenuItem:menuItem toLocation:LOC_Adium_Preferences];
}

- (IBAction)showAccountWindow:(id)sender
{
	[[AIAccountSetupWindowController accountSetupWindowController] showWindow:nil];
}

@end
