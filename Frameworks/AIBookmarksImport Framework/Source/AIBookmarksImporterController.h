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

@class AIBookmarksImporter;

@interface AIBookmarksImporterController: NSObject
{

	IBOutlet NSPanel		*bookmarksPanel;
	IBOutlet NSPopUpButton	*popUpButton;
	IBOutlet NSTabView		*tabView;
	IBOutlet NSOutlineView	*outlineView;
	IBOutlet NSButton		*insertButton;

	NSArray					*bookmarks;

	NSMutableArray			*importers;
	unsigned				 selectedImporterIndex;
}

+ (AIBookmarksImporterController *)sharedController;
- (void)addImporter:(AIBookmarksImporter *)importerToAdd;
- (void)removeImporter:(AIBookmarksImporter *)importerToRemove;

#pragma mark -

- (IBAction)orderFrontBookmarksPanel:(id)sender;
- (IBAction)toggleBookmarksPanel:(id)sender;

#pragma mark -

//this method takes a bookmark dictionary, creates a link from it, and inserts it into the current text view (if any). no work is done if you pass nil or if there is no active text view.
- (void)insertLink:(NSDictionary *)bookmark;

#pragma mark -

//returns YES if the bookmarks panel is on the screen; NO if it is not.
- (BOOL)bookmarksPanelVisible;

//returns a string suitable for, say, a menu item.
- (NSString *)bookmarksInterfaceItemTitle;

#pragma mark -

//this can be used on, say, a toolbar item.
- (NSImage *)bookmarksImporterIcon;

#pragma mark -

//for bookmarks importers only (e.g. the Address Book importer's 'All' group).
- (NSAttributedString *)attributedStringByItalicizingString:(NSString *)str;

@end
