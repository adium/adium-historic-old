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
#import "AIBookmarksImporter.h"

#import "AIMenuController.h"
#import "AIToolbarController.h"

#import <AIHyperlinks/SHMarkedHyperlink.h>

#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/CBObjectAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <AIUtilities/MVMenuButton.h>

#define ROOT_MENU_TITLE				AILocalizedString(@"Insert Bookmark", nil)
#define BOOKMARK_MENU_TITLE			AILocalizedString(@"Bookmark", nil)

#define DELAY_FOR_MENU_UPDATE		0.4 /*seconds*/

@interface AIBookmarksImporterPlugin (PRIVATE)
- (void)buildBookmarksMenuIfNecessaryThread;

- (void)buildBookmarksMenuIfNecessaryTimer:(NSTimer *)timer;
- (void)armMenuUpdateTimer;
- (void)disarmMenuUpdateTimer;

- (void)registerToolbarItem;
- (void)updateAllToolbarItemMenus;
- (void)updateMenuForToolbarItem:(NSToolbarItem *)item;
@end

/*!
 * @class AIBookmarksImporterPlugin
 * @brief Component to support reading and inserting of web browser bookmarks
 *
 * Bookmarks are available from the Edit menu, the message window toolbar, and from contextual menus.
 * The bookmarks for the user's default browser are used.
 *
 * Bookmarks are imported from all major Mac browsers via subclasses of AIBookmarksImporter, which must
 * register with the controller.
 */
@implementation AIBookmarksImporterPlugin

static AIBookmarksImporterPlugin *myself = nil;

/*
 * @brief Initialization
 */
- (void)installPlugin
{
	myself = self;
	
	importers = [[NSMutableArray alloc] init];
	updatingMenu = NO;
	menuNeedsUpdate = NO;
	toolbarItemArray = nil;

	menuUpdateTimer = nil;

	AIMenuController *menuController = [adium menuController];

	//Main bookmark menu item
	bookmarkRootMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ROOT_MENU_TITLE
																				 target:self
																				 action:@selector(dummyTarget:)
																		  keyEquivalent:@""] autorelease];
	[bookmarkRootMenuItem setRepresentedObject:self];
	[menuController addMenuItem:bookmarkRootMenuItem toLocation:LOC_Edit_Additions];
	NSMenu *menu = [bookmarkRootMenuItem menu];
	if([menu respondsToSelector:@selector(setDelegate:)]) {
		[menu setDelegate:self];
	}

	//Contextual bookmark menu item
	bookmarkRootContextualMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ROOT_MENU_TITLE
																						   target:self
																						   action:@selector(dummyTarget:)
																					keyEquivalent:@""] autorelease];
	[bookmarkRootContextualMenuItem setRepresentedObject:self];
	[menuController addContextualMenuItem:bookmarkRootContextualMenuItem toLocation:Context_TextView_Edit];

	menuLock = [[NSLock alloc] init];

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self
						   selector:@selector(toolbarWillAddItem:)
							   name:NSToolbarWillAddItemNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(toolbarDidRemoveItem:)
							   name:NSToolbarDidRemoveItemNotification
							 object:nil];
	[notificationCenter addObserver:self
						   selector:@selector(applicationDidBecomeActive:)
							   name:NSApplicationDidBecomeActiveNotification
							 object:NSApp];
					
	[self registerToolbarItem];
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];

	[menuLock release];
	[toolbarItem release];
	[toolbarItemArray release];
	[importers release];
	[menuUpdateTimer release];
	
	[super dealloc];
}

+ (AIBookmarksImporterPlugin *)sharedInstance
{
	return myself;
}

#pragma mark -

- (void)addImporter:(AIBookmarksImporter *)importerToAdd {
	NSString *nameOfNewImporter = [[importerToAdd class] browserName];

	//Insert the importer into our importer array, respecting alphabetical order for display purposes
	BOOL ranOut = YES;
	unsigned count = [importers count], i = count;
	while(i) {
		AIBookmarksImporter *importer = [importers objectAtIndex:--i];
		if(importer == importerToAdd) return;

		NSComparisonResult comparison = [nameOfNewImporter compare:[[importer class] browserName]];
		if(comparison == NSOrderedSame) {
			NSLog(@"AIBookmarksImporterController: replaced importer %@ with importer %@", importer, importerToAdd);
			[importers replaceObjectAtIndex:i withObject:importerToAdd];
			goto end;
		} else if(comparison == NSOrderedAscending) {
			//insert here
			ranOut = NO;
			break;
		}
	}
	if(ranOut) {
		//add to the end
		i = count;
	}
	[importers insertObject:importerToAdd atIndex:i];

end:
	/* Update the menus after a delay to allow any other importers which are about to load to also
	 * be added, aggregating the building into a single time instead of multiple times.
	 */
	[self armMenuUpdateTimer];
}

- (void)removeImporter:(AIBookmarksImporter *)importerToRemove {
	[importers removeObjectIdenticalTo:importerToRemove];

	//Aggregate multiple remove requests
	[self armMenuUpdateTimer];
}

#pragma mark -

/*
 * @brief Insert a link into the textView
 *
 * @param sender An NSMenuItem whose representedObject must be an SHMarkedHyperlink instance
 */
- (void)injectBookmarkFrom:(id)sender
{
	SHMarkedHyperlink	*markedLink = [sender representedObject];
	
	if(markedLink && [markedLink isKindOfClass:[SHMarkedHyperlink class]]){
		NSResponder         *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		
		//if the first responder is a text view...
		if(responder && [responder isKindOfClass:[NSTextView class]]){
			NSTextView      *topView = (NSTextView *)responder;
			NSDictionary    *typingAttributes = [topView typingAttributes];
			NSRange			 linkRange = [markedLink range];

			//new mutable string to build the link with
			NSMutableAttributedString	*linkString = [[[NSMutableAttributedString alloc] initWithString:[markedLink parentString]
			                                                                                  attributes:typingAttributes] autorelease];
			[linkString addAttribute:NSLinkAttributeName value:[markedLink URL] range:linkRange];

			//insert the link to the text view..
			NSRange selRange = [topView selectedRange];
			[[topView textStorage] replaceCharactersInRange:selRange withAttributedString:linkString];

			//special cases for insertion:
			NSAttributedString  *space = [[[NSAttributedString alloc] initWithString:@" "
																		  attributes:typingAttributes] autorelease];
			NSString *str = [topView string];
			NSTextStorage *storage = [topView textStorage];
			unsigned afterIndex = selRange.location + linkRange.length;
			if(([str length] > afterIndex) && ([str characterAtIndex:afterIndex] != ' ')) {
				/*if we insert a link, we're not at the end of the string, and the next char isn't a space,
				 *	insert a space.
				 */
				[storage insertAttributedString:space
				                        atIndex:afterIndex];
            }
			if(selRange.location > 0 && [str characterAtIndex:(selRange.location - 1)] != ' ') {
				/*if we insert a link, we're not at the start of the string, and the previous char isn't a space,
				 *insert a space.
				 */
				[storage insertAttributedString:space
				                        atIndex:selRange.location];
            }
		}
	}
}

#pragma mark -
#pragma mark Building

/*
 * @brief Builds the bookmark menu (Detach as a thread)
 *
 * We're not allowed to create or touch any menu items from within a thread, so this thread will gather a list of 
 * bookmarks and then pass them over to another method on the main thread for menu building/inserting.
 */
- (void)buildBookmarksMenu
{
	updatingMenu = YES;

	NSDate *start, *end;

	BOOL menuHasChanged = NO;

	NSMenu				*menuItemSubmenu = nil;
	NSMenu				*contextualMenuItemSubmenu = nil;

	AIBookmarksImporter	*importer = nil;
	AILog(@"AIBookmarksImporterPlugin: Importing %@",importers);

	start = [NSDate date];
	if([importers count] == 1) {
		importer = [importers lastObject];

		if([importer bookmarksHaveChanged]) {
			menuItemSubmenu           = [importer menuWithAvailableBookmarks];
			contextualMenuItemSubmenu = [[menuItemSubmenu copyWithZone:[NSMenu menuZone]] autorelease];
			menuHasChanged = YES;
		}
	} else {
		/* This code rebuilds all importers, not just those which have changed... It should keep
		 * usable, unchanged submenus. */
		menuItemSubmenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:BOOKMARK_MENU_TITLE];
		contextualMenuItemSubmenu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:BOOKMARK_MENU_TITLE];

		NSEnumerator		*importersEnum = [importers objectEnumerator];
		while((importer = [importersEnum nextObject])) {
			Class   importerClass = [importer class];
			NSString *browserName = [importerClass browserName];
			NSImage  *browserIcon = [importerClass browserIcon];
			[browserIcon setSize:NSMakeSize(16.0, 16.0)];

			NSMenu *menu = [importer menuWithAvailableBookmarks]; //creates a new menu object
			NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:browserName
															   action:NULL
														keyEquivalent:@""] autorelease];
			[menuItem setImage:browserIcon];
			[menuItem setSubmenu:menu];
			[menuItemSubmenu addItem:menuItem];
			[contextualMenuItemSubmenu addItem:[[menuItem copyWithZone:[NSMenu menuZone]] autorelease]];

			menuHasChanged = YES;
		}
	}

	if(menuHasChanged) {
		[menuItemSubmenu setMenuChangedMessagesEnabled:NO];
		[menuItemSubmenu setAutoenablesItems:NO];

		[contextualMenuItemSubmenu setMenuChangedMessagesEnabled:NO];
		[contextualMenuItemSubmenu setAutoenablesItems:NO];
	} else {
		updatingMenu = NO;
	}

	end = [NSDate date];
	AILog(@"AIBookmarksImporterPlugin: Imported bookmarks in %g seconds", [end timeIntervalSinceDate:start]);

	[menuLock lock];
	[bookmarksMainSubmenu release];
	 bookmarksMainSubmenu = menuItemSubmenu;
	[bookmarksContextualSubmenu release];
	 bookmarksContextualSubmenu = contextualMenuItemSubmenu;
	[menuLock unlock];
}

- (void) buildBookmarksMenuIfNecessaryThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	//-buildBookmarksMenu does the if-necessary parts itself now.
	[self buildBookmarksMenu];

	[pool release];
}

- (void)buildBookmarksMenuIfNecessaryTimer:(NSTimer *)timer
{
	if(!updatingMenu){
		[NSThread detachNewThreadSelector:@selector(buildBookmarksMenuIfNecessaryThread)
								 toTarget:self
							   withObject:nil];
	}
	[self disarmMenuUpdateTimer];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
	if(!updatingMenu){
		[NSThread detachNewThreadSelector:@selector(buildBookmarksMenuIfNecessaryThread)
								 toTarget:self
							   withObject:nil];
	}
}

#pragma mark -

- (void)armMenuUpdateTimer
{
	if(!menuUpdateTimer) {
		menuUpdateTimer = [[NSTimer timerWithTimeInterval:DELAY_FOR_MENU_UPDATE
												  target:self
												selector:@selector(buildBookmarksMenuIfNecessaryTimer:)
												userInfo:nil
												 repeats:NO] retain];
		[[NSRunLoop currentRunLoop] addTimer:menuUpdateTimer forMode:NSDefaultRunLoopMode];
	}
	//if we already have a timer, then we simply postpone the fire date.
	//otherwise, this sets the fire date for the first time.
	[menuUpdateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:DELAY_FOR_MENU_UPDATE]];
}

- (void)disarmMenuUpdateTimer
{
	[menuUpdateTimer invalidate];
	[menuUpdateTimer release];
	menuUpdateTimer = nil;
}

#pragma mark -

/*
 * @brief Called by the thread when the submenu NSMenu items have been generated
 */
- (void)gotMenuItemSubmenu:(NSMenu *)menuItemSubmenu contextualMenuItemSubmenu:(NSMenu *)contextualMenuItemSubmenu
{
	//Apply on the next run loop to avoid threadlocking
	[self performSelector:@selector(doSetOfMenuItemSubmenu:contextualMenuItemSubmenu:)
			   withObject:menuItemSubmenu
			   withObject:contextualMenuItemSubmenu
			   afterDelay:0.0001];
}

/*
 * @brief Called after a delay by the main thread to actually perform our setting
 */
- (void)doSetOfMenuItemSubmenu:(NSMenu *)menuItemSubmenu contextualMenuItemSubmenu:(NSMenu *)contextualMenuItemSubmenu
{
	BOOL submenuChanged = NO;
	if(menuItemSubmenu && (menuItemSubmenu != [bookmarkRootMenuItem submenu])) {
		[bookmarkRootMenuItem setSubmenu:menuItemSubmenu];
		[menuItemSubmenu setMenuChangedMessagesEnabled:YES];
		submenuChanged = YES;
	}
	if(contextualMenuItemSubmenu && (contextualMenuItemSubmenu != [bookmarkRootContextualMenuItem submenu])) {
		[bookmarkRootContextualMenuItem setSubmenu:contextualMenuItemSubmenu];
		[contextualMenuItemSubmenu setMenuChangedMessagesEnabled:YES];
		submenuChanged = YES;
	}

	if(submenuChanged) {
		//Update the menus of existing toolbar items
		[self updateAllToolbarItemMenus];
	}

	updatingMenu = NO;
}

#pragma mark -
#pragma mark Validation / Updating

/*
 * @brief Validate our bookmark menu item
 */
- (BOOL)validateMenuItem:(id <NSMenuItem>)sender
{
	//We only care to disable the main menu item (The rest are hidden within it, and do not matter)
	NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	BOOL		enable = (responder && 
						  [responder isKindOfClass:[NSTextView class]] &&
						  [(NSTextView *)responder isEditable]);
	return enable;
}

/*
 * @brief Dummy menu item target so we can enable/disable our main menu item
 */
- (IBAction)dummyTarget:(id)sender{
}

#pragma mark -

//we don't want to get -menuNeedsUpdate: called on every keystroke. this method suppresses that.
- (BOOL)menuHasKeyEquivalent:(NSMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action {
	*target = nil;  //use menu's target
	*action = NULL; //use menu's action
	return NO;
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
	[menuLock lock];
	[self doSetOfMenuItemSubmenu:[bookmarksMainSubmenu autorelease]
	   contextualMenuItemSubmenu:[bookmarksContextualSubmenu autorelease]];
	bookmarksMainSubmenu = bookmarksContextualSubmenu = nil;
	[menuLock unlock];
}

#pragma mark -
#pragma mark Toolbar Item

/*
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

	toolbarItem = [[AIToolbarUtilities toolbarItemWithIdentifier:@"InsertBookmark"
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

/*
 * @brief Toolbar item will be added
 * When a toolbar item is added (it will be effectively a copy of the one we originally registered)
 * we want to set its menu initially, then track it for later menu changes
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if([[item itemIdentifier] isEqualToString:@"InsertBookmark"]){
		[self performSelector:@selector(updateMenuForToolbarItem:)
				   withObject:item
				   afterDelay:0];

		if (!toolbarItemArray) toolbarItemArray = [[NSMutableArray alloc] init];
		[toolbarItemArray addObject:item];
	}
}

/*
 * @brief A toolbar item was removed
 *
 * Stop tracking (and retaining) it
 */
- (void)toolbarDidRemoveItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];

	if([[item itemIdentifier] isEqualToString:@"InsertBookmark"]){
		[toolbarItemArray removeObject:item];
	}
}

/*
 * @brief Update the menus on every toolbar item we are tracking
 */
- (void)updateAllToolbarItemMenus
{
	NSEnumerator	*enumerator;
	NSToolbarItem	*aToolbarItem;

	enumerator = [toolbarItemArray objectEnumerator];
	while((aToolbarItem = [enumerator nextObject])){
		[self updateMenuForToolbarItem:aToolbarItem];
	}
}

/*
 * @brief Update the menu for a specific toolbar item
 */
- (void)updateMenuForToolbarItem:(NSToolbarItem *)item
{
	NSMenu		*menu = [[[bookmarkRootMenuItem submenu] copyWithZone:[NSMenu menuZone]] autorelease];
	NSString	*menuTitle = [menu title];

	//Add menu to view
	[[item view] setMenu:menu];

	//Add menu to toolbar item (for text mode)
	NSMenuItem	*mItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] init] autorelease];
	[mItem setSubmenu:menu];
	[mItem setTitle:(menuTitle ? menuTitle : @"")];
	[item setMenuFormRepresentation:mItem];	
}


@end
