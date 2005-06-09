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

#import "AIBookmarksImporterPlugin.h"
#import <AIBookmarksImport/AIBookmarksImport.h>

#import "AIMenuController.h"
#import "AIToolbarController.h"

#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>

#define MENU_TITLE					AILocalizedString(@"Show/Hide Bookmarks", nil)

#define TOOLBAR_ITEM_IDENTIFIER		@"InsertBookmarks"

@interface AIBookmarksImporterPlugin (PRIVATE)
- (void)registerToolbarItem;
@end

/*!
 * @class AIBookmarksImporterPlugin
 * @brief Component to support reading and inserting of web browser bookmarks
 *
 * Provides Adium's user interface for accessing the Bookmarks panel in the AIBookmarksImport framework.
 */
@implementation AIBookmarksImporterPlugin

/*!
 * @brief Initialization
 */
- (void)installPlugin
{
	AIMenuController *menuController = [adium menuController];
	AIBookmarksImporterController *bookmarksImporterController = [AIBookmarksImporterController sharedController];

	NSString *menuTitle = MENU_TITLE;
	NSString *tooltip = AILocalizedString(@"Toggle display of the Bookmarks panel", /*comment*/ nil);

	//Main bookmark menu item
	bookmarksMainMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:menuTitle
																				  target:bookmarksImporterController
																				  action:@selector(toggleBookmarksPanel:)
																		   keyEquivalent:@""] autorelease];
	[bookmarksMainMenuItem setToolTip:tooltip];
	[menuController addMenuItem:bookmarksMainMenuItem toLocation:LOC_Edit_Additions];

	//Contextual bookmark menu item
	bookmarksContextualMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:menuTitle
																						target:bookmarksImporterController
																						action:@selector(toggleBookmarksPanel:)
																				 keyEquivalent:@""] autorelease];
	[bookmarksContextualMenuItem setToolTip:tooltip];
	[menuController addContextualMenuItem:bookmarksContextualMenuItem toLocation:Context_TextView_Edit];

	[self registerToolbarItem];
}

- (void)uninstallPlugin
{
	[[adium notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[toolbarItem release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Toolbar Item

/*!
 * @brief Register toolbar item
 */
- (void)registerToolbarItem
{
	AIToolbarController *toolbarController = [adium toolbarController];
	AIBookmarksImporterController *bookmarksImporterController = [AIBookmarksImporterController sharedController];

	//Unregister the existing toolbar item first
	if (toolbarItem) {
		[toolbarController unregisterToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
		[toolbarItem release]; toolbarItem = nil;
	}

	//Register our toolbar item
	toolbarItem = [[AIToolbarUtilities toolbarItemWithIdentifier:TOOLBAR_ITEM_IDENTIFIER
														   label:AILocalizedString(@"Bookmarks",nil)
													paletteLabel:AILocalizedString(@"Show/Hide Bookmarks",nil)
														 toolTip:AILocalizedString(@"Tooltip for show/hide bookmarks command",nil)
														  target:bookmarksImporterController
												 settingSelector:@selector(setView:)
													 itemContent:nil
														  action:@selector(toggleBookmarksPanel:)
															menu:nil] retain];
	NSImage *icon = [bookmarksImporterController bookmarksImporterIcon];
	[icon setScalesWhenResized:YES];
	[toolbarItem setImage:icon];
	[toolbarController registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}

@end
