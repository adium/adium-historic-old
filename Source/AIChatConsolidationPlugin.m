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

#import "AIChatConsolidationPlugin.h"
#import "AIInterfaceController.h"
#import "AIMenuController.h"
#import <AIUtilities/AIMenuAdditions.h>

#define CONSOLIDATE_CHATS_MENU_TITLE			AILocalizedString(@"Consolidate Chats",nil)

/*
 * @class AIChatConsolidationPlugin
 * @brief Component which provides the Conslidate Chats menu item
 *
 * Consolidating chats moves all open chats into a single, tabbed window
 */
@implementation AIChatConsolidationPlugin

/*
 * @brief Install
 */
- (void)installPlugin
{
	consolidateMenuItem = [[NSMenuItem alloc] initWithTitle:CONSOLIDATE_CHATS_MENU_TITLE
													 target:self 
													 action:@selector(consolidateChats:)
											  keyEquivalent:@"O"];
	[[adium menuController] addMenuItem:consolidateMenuItem toLocation:LOC_Window_Commands];
}

- (void)dealloc
{
	[consolidateMenuItem release];
	
	[super dealloc];
}

/*
 * @brief Consolidate chats
 *
 *	The interface controller does all the work for us :)
 */
- (void)consolidateChats:(id)sender
{
	[[adium interfaceController] consolidateChats];	
}

/*
 * @brief Validate menu items
 *
 * Only enable the menu if more than one chat is open
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	return([[[adium interfaceController] openChats] count] > 1);
}

@end
