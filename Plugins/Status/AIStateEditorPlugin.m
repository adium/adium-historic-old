/* 
Adium, Copyright 2001-2005, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIStateEditorPlugin.h"
#import "AIPresetStatusWindowController.h"

/*!
 * @class AIStateEditorPlugin
 * @brief Provides a window to add, remove, re-arrange and edit preset states.
 *
 * This is the plugin class for our preset state editor window.
 */
@implementation AIStateEditorPlugin

/*!
 * Install the state editor window menu item
 */
- (void)installPlugin
{
	NSMenuItem *menuItem;
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Edit Status..."
																	target:self
																	action:@selector(showStateEditorWindow:)
															 keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem toLocation:LOC_Status_Additions];
}

/*!
 * Open the state editor window, or bring it to the front if already open.
 */
- (void)showStateEditorWindow:(id)sender
{
	[[AIPresetStatusWindowController presetStatusWindowController] showWindow:nil];
}

@end
