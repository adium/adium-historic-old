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

#import "AIBookmarksImporterController.h"
#import "AIBookmarksImporter.h"

#import <ApplicationServices/ApplicationServices.h>

#define TOOLBAR_ITEM_IDENTIFIER		@"com.adiumx.bookmarksimporter"

@interface AIBookmarksImporterController (PRIVATE)

#ifdef PROVIDE_TOOLBAR_ITEM
- (void)registerToolbarItem;
#endif

- (NSMutableArray *)loadBuiltInImporters;
- (void)loadBookmarks;

- (void)setSelectedImporterIndex:(unsigned)newIndex;
- (IBAction)takeBrowserSelectionFrom:(id)sender;

- (NSMenuItem *)browserMenuItemWithName:(NSString *)name icon:(NSImage *)icon;

- (void)getDefaultBrowserBundleIdentifier:(out NSString **)outBundleID signature:(out NSString **)outSignature;

@end

#import "SHABBookmarksImporter.h"
#import "SHSafariBookmarksImporter.h"
#import "SHOmniWebBookmarksImporter.h"
#import "AIShiiraBookmarksImporter.h"
#import "SHMozillaBookmarksImporter.h"
#import "SHFireFoxBookmarksImporter.h"
#import "SHCaminoBookmarksImporter.h"
#import "SHMSIEBookmarksImporter.h"

static AIBookmarksImporterController *myself = nil;

/*!
 * @class AIBookmarksImporterController
 * @brief Component to support reading and inserting of web browser bookmarks
 *
 * Bookmarks are available to the user from the Bookmarks panel.
 *
 * Bookmarks are imported from all major Mac browsers via subclasses of AIBookmarksImporter, which must
 * register with the controller.
 */
@implementation AIBookmarksImporterController

- (id)init
{
	if(myself) {
		[self release];
		return myself;
	}

	if((self = [super init])) {
		myself = [self retain];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationDidBecomeActive:)
													 name:NSApplicationDidBecomeActiveNotification
												   object:NSApp];

		importers = [[self loadBuiltInImporters] retain];

		//XXX - post a notification here calling for importers to register.

		[[NSBundle bundleForClass:[AIBookmarksImporterController class]] loadNibFile:@"BookmarksPanel.nib" externalNameTable:nil withZone:[self zone]];

		[outlineView setDoubleAction:@selector(_insertBookmarkFromOutlineViewSelection:)];
		[outlineView setTarget:self];

		[bookmarksPanel setBecomesKeyOnlyIfNeeded:YES];
	}

	return self;
}

- (NSMutableArray *)loadBuiltInImporters
{
	return [NSMutableArray arrayWithObjects:
		[SHABBookmarksImporter      importer],
		[SHSafariBookmarksImporter  importer],
		[SHOmniWebBookmarksImporter importer],
		[AIShiiraBookmarksImporter  importer],
		[SHMozillaBookmarksImporter importer],
		[SHFireFoxBookmarksImporter importer],
		[SHCaminoBookmarksImporter  importer],
		[SHMSIEBookmarksImporter    importer],
		nil];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[bookmarksPanel release];
	[importers release];
	[bookmarks release];
	
	[super dealloc];
}

+ (AIBookmarksImporterController *)sharedController
{
	return myself;
}

#pragma mark -
#pragma mark Mutating the importer list

- (void)addImporter:(AIBookmarksImporter *)importerToAdd
{
	Class classOfNewImporter = [importerToAdd class];
	NSString *nameOfNewImporter = [classOfNewImporter browserName];

	//Insert the importer into our importer array, respecting alphabetical order for display purposes
	BOOL ranOut = YES;
	unsigned count = [importers count], i = count;
	while(i) {
		AIBookmarksImporter *importer = [importers objectAtIndex:--i];
		if(importer == importerToAdd) return;

		NSComparisonResult comparison = [nameOfNewImporter caseInsensitiveCompare:[[importer class] browserName]];
		if(comparison == NSOrderedSame) {
			[importers replaceObjectAtIndex:i withObject:importerToAdd];
			goto end;
		} else if(comparison == NSOrderedAscending) {
			//insert here
			ranOut = NO;
			break;
		}
	}
	if(ranOut) {
		//add to the end of the menu
		i = count;
	}

	[importers insertObject:importerToAdd atIndex:i];
	NSMenuItem *item = [self browserMenuItemWithName:nameOfNewImporter icon:[classOfNewImporter browserIcon]];
	[[popUpButton menu] insertItem:item atIndex:i];

end:
	;
}

- (void)removeImporter:(AIBookmarksImporter *)importerToRemove
{
	BOOL needReload = NO;

	NSString *browserNameToRemove = [[importerToRemove class] browserName];
	int count = [popUpButton numberOfItems];
	for(int i = 0; i < count; ++i) {
		if([browserNameToRemove isEqualToString:[popUpButton itemTitleAtIndex:i]]) {
			[popUpButton removeItemAtIndex:i];
			needReload = (selectedImporterIndex == (unsigned)i);
			break;
		}
	}

	/*we can't use removeObjectAtIndex: here because importers is a list of *all* registered importers, whereas
	 *	the pop-up button contains only available importers (+browserIsAvailable = YES).
	 */
	[importers removeObjectIdenticalTo:importerToRemove];

	if((int)selectedImporterIndex >= count) {
		selectedImporterIndex -= ((selectedImporterIndex - count) + 1);
	}
	[popUpButton selectItemAtIndex:selectedImporterIndex];

	if(needReload) [self loadBookmarks];
}

#pragma mark -
#pragma mark Getting importers and using them

- (void)fillOutPopUpButton
{
	[popUpButton removeAllItems];

	//get info about the default browser.
	NSString *bundleID = nil, *signature = nil;
	[self getDefaultBrowserBundleIdentifier:&bundleID signature:&signature];

	NSMenu *menu = [popUpButton menu];

	int selectedIndex = 0, currentIndex = -1;

	NSEnumerator *importersEnum = [importers objectEnumerator];
	AIBookmarksImporter *importer;
	while((importer = [importersEnum nextObject])) {
		Class importerClass = [importer class];
		if([importerClass browserIsAvailable]) {
			NSMenuItem *item = [self browserMenuItemWithName:[importerClass browserName]
														icon:[importerClass browserIcon]];
			[item setTag:++currentIndex];
			[menu addItem:item];

			NSString *importerBundleID = [importerClass browserBundleIdentifier], *importerSignature = [importerClass browserSignature];
			if((importerBundleID && bundleID && [importerBundleID isEqualToString:bundleID])
			|| (importerSignature && signature && [importerSignature isEqualToString:signature]))
			{
				selectedIndex = currentIndex;
			}
		}
	}

	/*select the default browser.
	 *if we didn't find any browsers, currentIndex is -1 because there are no items in the pop-up button, so we
	 *	shouldn't select any item (use -1).
	 */
	if(currentIndex == -1) selectedIndex = -1;
	[self setSelectedImporterIndex:selectedIndex];
}
- (void)loadBookmarks
{
	NSArray *oldBookmarks = bookmarks;
	NSArray *newBookmarks = [[importers objectAtIndex:selectedImporterIndex] availableBookmarks];

	BOOL lengthsDontMatch = ([oldBookmarks count] != [newBookmarks count]);
	if(lengthsDontMatch || ![oldBookmarks isEqualToArray:newBookmarks]) {
		[bookmarks release];
		bookmarks = [newBookmarks retain];

		int selection = lengthsDontMatch ? -1 : [outlineView selectedRow];
		[outlineView reloadData];
		[outlineView selectRow:selection byExtendingSelection:NO];
	}
}

#pragma mark -
#pragma mark When to refresh the imported bookmarks

- (IBAction)orderFrontBookmarksPanel:(id)sender
{
	[self fillOutPopUpButton];
	[bookmarksPanel orderFront:sender];

	[self performSelector:@selector(loadBookmarks)
			   withObject:nil
			   afterDelay:0.0];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	if([bookmarksPanel isVisible]) {
		[self performSelector:@selector(loadBookmarks)
				   withObject:nil
				   afterDelay:0.0];
	}
}

- (void)setSelectedImporterIndex:(unsigned)newIndex
{
	unsigned numImporters = [importers count];
	if(((signed)newIndex) != -1) {
		NSAssert2(newIndex < numImporters, @"Could not select importer with index %u; there are only %u importers", newIndex, numImporters);
	}

	selectedImporterIndex = newIndex;
	[popUpButton selectItemWithTag:selectedImporterIndex];
	//update the enabled-state of the Insert button
	[self outlineViewSelectionDidChange:nil];

	[self loadBookmarks];
}

#pragma mark -
#pragma mark Actions

- (IBAction)toggleBookmarksPanel:(id)sender
{
	if([bookmarksPanel isVisible]) {
		[bookmarksPanel orderOut:sender];
	} else {
		//be sure to use ours, since we do extra stuff here.
		[self orderFrontBookmarksPanel:sender];
	}
}

- (IBAction)takeBrowserSelectionFrom:(id)sender
{
	[self setSelectedImporterIndex:[sender tag]];
}

- (IBAction)_insertBookmarkFromOutlineViewSelection:(id)sender
{
	NSDictionary *bookmark = [outlineView itemAtRow:[outlineView selectedRow]];
	NSURL *URL = [bookmark objectForKey:ADIUM_BOOKMARK_DICT_CONTENT];

	if(URL && [URL isKindOfClass:[NSURL class]]) {
		NSResponder         *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		
		//if the first responder is a text view...
		if(responder && [responder isKindOfClass:[NSTextView class]]) {
			NSTextView      *textView = (NSTextView *)responder;
			NSTextStorage	*textStorage = [textView textStorage];
			NSDictionary    *typingAttributes = [textView typingAttributes];
			NSString		*URLString = [URL absoluteString];
			unsigned		 linkStringLength, changeInLength;

			NSString		*linkTitle = [bookmark objectForKey:ADIUM_BOOKMARK_DICT_TITLE];
			if(!linkTitle)   linkTitle = URLString;
			NSRange			 linkRange = { 0, [linkTitle length] };

			//new mutable string to build the link with
			NSMutableAttributedString	*linkString = [[[NSMutableAttributedString alloc] initWithString:linkTitle
			                                                                                  attributes:typingAttributes] autorelease];
			[linkString addAttribute:NSLinkAttributeName value:URL range:linkRange];
			
			//Insert the link into the text view
			NSRange selRange = [textView selectedRange];
			[textStorage replaceCharactersInRange:selRange withAttributedString:linkString];
			
			//Determine the change in length
			linkStringLength = [linkString length];
			changeInLength = linkStringLength - selRange.length;
			
			//Special cases for insertion:
			NSAttributedString  *space = [[[NSAttributedString alloc] initWithString:@" "
																		  attributes:typingAttributes] autorelease];
			NSString *str = [textView string];
			
			unsigned afterIndex = selRange.location + linkRange.length;
			if(([str length] > afterIndex) && ([str characterAtIndex:afterIndex] != ' ')) {
				/* If we insert a link, we're not at the end of the string, and the next char isn't a space,
				 * insert a space.
				 */
				[textStorage insertAttributedString:space
											atIndex:afterIndex];
				changeInLength++;
            }
			if(selRange.location > 0 && [str characterAtIndex:(selRange.location - 1)] != ' ') {
				/* If we insert a link, we're not at the start of the string, and the previous char isn't a space,
				 * insert a space.
				 */
				[textStorage insertAttributedString:space
											atIndex:selRange.location];
				changeInLength++;
            }
			
			//Notify that a change occurred since NSTextStorage won't do it for us
			[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification
																object:textView
															  userInfo:nil];
		}
	}
}

#pragma mark -
#pragma mark Utilities

- (void)getDefaultBrowserBundleIdentifier:(out NSString **)outBundleID signature:(out NSString **)outSignature
{
	NSString *bundleID = nil, *signature = nil;
	NSURL *browserURL = nil;
	OSStatus err = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http://www.adiumx.com/"],
										  kLSRolesViewer,
										  /*outAppRef*/ NULL,
										  (CFURLRef *)&browserURL);
	if(err != noErr) {
		NSLog(@"Bookmarks Importer Controller: Could not ascertain default browser (LSGetApplicationForURL returned %li).", (long)err);
	} else {
		NSBundle *bundle = [NSBundle bundleWithPath:[browserURL path]];
		bundleID = [bundle bundleIdentifier];

		//get type and creator (so we can return the latter)
		struct LSItemInfoRecord rec;
		err = LSCopyItemInfoForURL((CFURLRef)browserURL,
								   kLSRequestTypeCreator,
								   /*outItemInfo*/ &rec);
		if(err == noErr) signature = [(NSString *)UTCreateStringForOSType(rec.creator) autorelease];
	}

	if(outBundleID)  *outBundleID  = bundleID;
	if(outSignature) *outSignature = signature;
}

- (NSMenuItem *)browserMenuItemWithName:(NSString *)name icon:(NSImage *)icon
{
	NSMenuItem *item = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:name
														action:@selector(takeBrowserSelectionFrom:)
												 keyEquivalent:@""];
	[item setTarget:self];

	icon = [icon copy];
	[icon setSize:NSMakeSize(16.0, 16.0)];
	[item setImage:icon];
	[icon release];

	return [item autorelease];
}

#pragma mark -
#pragma mark Accessors

- (BOOL)bookmarksPanelVisible {
	return [bookmarksPanel isVisible];
}

//XXX needed: a bindings accessor for a localized menu item name (e.g. Show Bookmarks) --boredzo


- (NSImage *)bookmarksImporterIcon
{
	return [[[NSImage alloc] initByReferencingFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"BookmarksImporterIcon"] autorelease];
}

#pragma mark -
#pragma mark NSOutlineView data source conformance

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
#pragma unused(outlineView)
	if(!item) {
		return [bookmarks count];
	} else if(![item respondsToSelector:@selector(objectForKey:)]) {
		return 0;
	} else {
		id sub = [item objectForKey:ADIUM_BOOKMARK_DICT_CONTENT];
		return [sub respondsToSelector:@selector(count)] ? (int)[sub count] : 0;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)idx ofItem:(id)item
{
#pragma unused(outlineView)
	id obj = nil;
	if(!item) {
		obj = [bookmarks objectAtIndex:idx];
	} else {
		id sub = [item objectForKey:ADIUM_BOOKMARK_DICT_CONTENT];
		obj = ([sub respondsToSelector:@selector(objectAtIndex:)] ? [sub objectAtIndex:(unsigned)idx] : nil);
	}
	return obj;
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)col byItem:(id)item
{
#pragma unused(outlineView)
	id result = nil;

	NSString *identifier = [col identifier];
	if([identifier isEqualToString:@"icon"]) {
		result = [item objectForKey:ADIUM_BOOKMARK_DICT_FAVICON];
	} else if([identifier isEqualToString:@"name"]) {
		result = [item objectForKey:ADIUM_BOOKMARK_DICT_TITLE];
		if(!result) {
			NSFont *font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
			font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSItalicFontMask];
			NSDictionary *attrs = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
			result = [[[NSAttributedString alloc] initWithString:@"untitled" attributes:attrs] autorelease];
		}
	} else if([identifier isEqualToString:@"uri"]) {
		NSURL *content = [item objectForKey:ADIUM_BOOKMARK_DICT_CONTENT];
		if([content respondsToSelector:@selector(absoluteString)]) {
			result = [content absoluteString];
		}
	}

	return result;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
#pragma unused(outlineView)
	id sub = [item objectForKey:ADIUM_BOOKMARK_DICT_CONTENT];
	return [sub respondsToSelector:@selector(count)];
}

#pragma mark -
#pragma mark NSOutlineView delegate conformance

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
#pragma unused(notification)

	NSURL *URL = [[outlineView itemAtRow:[outlineView selectedRow]] objectForKey:ADIUM_BOOKMARK_DICT_CONTENT];
	[insertButton setEnabled:(URL && [URL isKindOfClass:[NSURL class]])];
}

#ifdef PROVIDE_TOOLBAR_ITEM

#pragma mark -
#pragma mark Toolbar Item

/*!
 * @brief Register toolbar item
 */
- (void)registerToolbarItem
{
	AIToolbarController *toolbarController = [adium toolbarController];
	MVMenuButton *button;

	//Unregister the existing toolbar item first
	if(toolbarItem) {
		[toolbarController unregisterToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
		[toolbarItem release]; toolbarItem = nil;
	}

	//Register our toolbar item
	button = [[[MVMenuButton alloc] initWithFrame:NSMakeRect(0,0,32,32)] autorelease];

	NSImage *icon = [NSImage imageNamed:@"bookmarkToolbar" forClass:[self class]];
	if([importers count] == 1U) {
		//only one importer is active, so badge the sprocket icon with the importer's browser icon.
		AIBookmarksImporter *importer = [importers lastObject];
		NSImage *browserIcon = [[importer class] browserIcon];

		NSRect  srcRect = { NSZeroPoint, [browserIcon size] };
		NSSize origIconSize = [icon size];
		NSRect destRect = { NSZeroPoint, origIconSize };

		//draw to the lower right corner of the icon.
		destRect.size.width  *= 0.6;
		destRect.size.height *= 0.6;
		destRect.origin.x     = origIconSize.width - destRect.size.width;

		[icon lockFocus];
		[browserIcon drawInRect:destRect
					   fromRect:srcRect
					  operation:NSCompositeSourceOver
					   fraction:0.9];
		[icon unlockFocus];
	}
	[button setImage:icon];

	toolbarItem = [[AIToolbarUtilities toolbarItemWithIdentifier:TOOLBAR_ITEM_IDENTIFIER
														   label:AILocalizedString(@"Bookmarks",nil)
													paletteLabel:AILocalizedString(@"Insert Bookmark",nil)
														 toolTip:AILocalizedString(@"Insert Bookmark",nil)
														  target:self
												 settingSelector:@selector(setView:)
													 itemContent:button
														  action:@selector(injectBookmarkFrom:)
															menu:nil] retain];
	[toolbarItem setMinSize:NSMakeSize(32,32)];
	[toolbarItem setMaxSize:NSMakeSize(32,32)];
	[button setToolbarItem:toolbarItem];
	[toolbarController registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}

/*!
 * @brief Toolbar item will be added
 * When a toolbar item is added (it will be effectively a copy of the one we originally registered)
 * we want to set its menu initially, then track it for later menu changes
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];

	if([[item itemIdentifier] isEqualToString:TOOLBAR_ITEM_IDENTIFIER]){
		[self performSelector:@selector(obtainMenuLockAndUpdateMenuForToolbarItem:)
				   withObject:item
				   afterDelay:0];

		if (!toolbarItemArray) toolbarItemArray = [[NSMutableArray alloc] init];
		[toolbarItemArray addObject:item];
	}
}

/*!
 * @brief A toolbar item was removed
 *
 * Stop tracking (and retaining) it
 */
- (void)toolbarDidRemoveItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];

	if([[item itemIdentifier] isEqualToString:TOOLBAR_ITEM_IDENTIFIER]){
		[toolbarItemArray removeObject:item];
	}
}

#endif //def PROVIDE_TOOLBAR_ITEM

@end
