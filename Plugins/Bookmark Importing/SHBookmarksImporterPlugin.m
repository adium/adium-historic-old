//
//  SHBookmarksImporterPlugin.m
//  Adium
//
//  Created by Stephen Holt on Wed May 19 2004.

#import "SHBookmarksImporterPlugin.h"

#define ROOT_MENU_TITLE     		AILocalizedString(@"Bookmarks",nil)
#define BOOKMARK_MENU_TITLE     	AILocalizedString(@"Bookmark",nil)

@interface SHBookmarksImporterPlugin(PRIVATE)
- (Class)importerClassForDefaultBrowser;
- (void)buildBookmarkMenuThread;
- (void)insertBookmarks:(NSDictionary *)bookmarkArray;
- (void)insertBookmark:(SHMarkedHyperlink *)bookmark;
- (void)insertBookmarks:(NSDictionary *)bookmarks intoMenu:(NSMenu *)inMenu;
- (void)insertMenuItemForBookmark:(SHMarkedHyperlink *)object intoMenu:(NSMenu *)inMenu;
- (void)registerToolbarItem;
- (void)updateAllToolbarItemMenus;
- (void)updateMenuForToolbarItem:(NSToolbarItem *)item;
@end

@class SHSafariBookmarksImporter, SHCaminoBookmarksImporter, SHMozillaBookmarksImporter,
       SHFireFoxBookmarksImporter, SHMSIEBookmarksImporter, SHOmniWebBookmarksImporter;

@implementation SHBookmarksImporterPlugin

//Install
- (void)installPlugin
{
	//Prepare the importer for our default browser
	importer = [[[self importerClassForDefaultBrowser] newInstanceOfImporter] retain];

	updatingMenu = NO;
    toolbarItemArray = nil;
	
	//If we can't find an importer for the user's browser, we don't need to install the menu item or do anything else
	if(importer){
		//Main bookmark menu item
		bookmarkRootMenuItem = [[[NSMenuItem alloc] initWithTitle:ROOT_MENU_TITLE
														   target:self
														   action:@selector(dummyTarget:)
													keyEquivalent:@""] autorelease];
		[bookmarkRootMenuItem setRepresentedObject:self];
		[[adium menuController] addMenuItem:bookmarkRootMenuItem toLocation:LOC_Edit_Additions];
		
		//Contextual bookmark menu item
		bookmarkRootContextualMenuItem = [[[NSMenuItem alloc] initWithTitle:ROOT_MENU_TITLE
																	 target:self
																	 action:@selector(dummyTarget:)
															  keyEquivalent:@""] autorelease];
		[bookmarkRootContextualMenuItem setRepresentedObject:self];
		[[adium menuController] addContextualMenuItem:bookmarkRootContextualMenuItem toLocation:Context_TextView_Edit];
		
		//Wait for Adium to finish launching before we build the content of our menus
		[[adium notificationCenter] addObserver:self
									   selector:@selector(adiumFinishedLaunching:)
										   name:Adium_CompletedApplicationLoad
										 object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(toolbarWillAddItem:)
													 name:NSToolbarWillAddItemNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(toolbarDidRemoveItem:)
													 name:NSToolbarDidRemoveItemNotification
												   object:nil];
					
		[self registerToolbarItem];
	}
}

//Uninstall
- (void)uninstallPlugin
{
    [[adium notificationCenter] removeObserver:self];
	[importer release]; importer = nil;
}

//Once Adium has finished launching, detach our bookmark thread and start building the menu
- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	if (!updatingMenu){
		[NSThread detachNewThreadSelector:@selector(buildBookmarkMenuThread)
								 toTarget:self
							   withObject:nil];
	}
}

//Returns the importer we'll need to use for the user's default web browser
- (Class)importerClassForDefaultBrowser
{
	Class		importerClass = nil;
	ICInstance	ICInst;
	ICAppSpec	Spec;
	ICAttr		Junk;
	OSErr		Err;
	long		TheSize;

	//Start Internet Config, passing it Adium's creator code
	Err = ICStart(&ICInst, 'AdiM');
	
	TheSize = sizeof(Spec);
	
	// Get the current http helper app, to fill the Spec and TheSize variables and determine the default browser
	Err = ICGetPref(ICInst, "\pHelper¥http", &Junk, &Spec, &TheSize);
	
	
	switch(Spec.fCreator){
		case 'sfri': /* Safari */
			importerClass = [SHSafariBookmarksImporter class];
			break;
		case 'CHIM': /* Camino */
			importerClass = [SHCaminoBookmarksImporter class];
			break;
		case 'MOZB': /* FireFox */
			importerClass = [SHFireFoxBookmarksImporter class];
			break;
		case 'MOZZ': /* Mozilla */
			importerClass = [SHMozillaBookmarksImporter class];
			break;
		case 'OWEB': /* OmniWeb (4.x and 5.x) */
			importerClass = [SHOmniWebBookmarksImporter class];
			break;
		case 'MSIE': /* Internet Explorer */
			importerClass = [SHMSIEBookmarksImporter class];
			break;			
		default:
			importerClass = nil;
			break;
	}

	//We're done with Internet Config, so stop it
	Err = ICStop(ICInst);

	return(importerClass);
}

//Insert a link into the textView
- (void)injectBookmarkFrom:(id)sender
{
	SHMarkedHyperlink	*markedLink = [sender representedObject];
	
	if(markedLink && [markedLink isKindOfClass:[SHMarkedHyperlink class]]){
        NSResponder         *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		
        //if the first responder is a text view...
        if(responder && [responder isKindOfClass:[NSTextView class]]){
            NSTextView      *topView = (NSTextView *)responder;
            NSDictionary    *typingAttributes = [topView typingAttributes];
            
            //new mutable string to build the link with
            NSMutableAttributedString	*linkString = [[[NSMutableAttributedString alloc] initWithString:[markedLink parentString]
                                                                                              attributes:typingAttributes] autorelease];
            [linkString addAttribute:NSLinkAttributeName value:[markedLink URL] range:[markedLink range]];
            
            //insert the link to the text view..
            NSRange selRange = [topView selectedRange];
            [[topView textStorage] replaceCharactersInRange:selRange withAttributedString:linkString];
            
            //special cases for insertion:
            NSAttributedString  *tmpString = [[[NSAttributedString alloc] initWithString:@" "
                                                                              attributes:typingAttributes] autorelease];
            if([[topView string] characterAtIndex:(selRange.location + [markedLink range].length + 1)] != ' '){
                //if we insert a link and the next char isn't a space, insert one.
                [[topView textStorage] insertAttributedString:tmpString
                                                      atIndex:(selRange.location + [markedLink range].length)];
            }
            if(selRange.location > 0 && [[topView string] characterAtIndex:(selRange.location - 1)] != ' '){
                //if we insert a link and the previous char isn't a space (or the beginning of the text storage),
                //insert one.
                [[topView textStorage] insertAttributedString:tmpString
                                                      atIndex:selRange.location];
            }
        }
	}
}


//Building -------------------------------------------------------------------------------------------------------------
#pragma mark Building
//Builds the bookmark menu (Detatch as a thread)
//We're not allowed to create our touch any menu items from within a thread, so this thread will gather a list of 
//bookmarks and then pass them over to another method on the main thread for menu building/inserting.
- (void)buildBookmarkMenuThread
{
	updatingMenu = YES;
	
	NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
	NSEnumerator		*enumerator = [[importer availableBookmarks] objectEnumerator];
	id					object;
	Class				NSDictionaryClass = [NSDictionary class];
	Class				SHMarkedHyperlinkClass = [SHMarkedHyperlink class];
	
	NSMenu				*menuItemSubmenu = [[NSMenu alloc] initWithTitle:BOOKMARK_MENU_TITLE];
	NSMenu				*contextualMenuItemSubmenu = [[NSMenu alloc] initWithTitle:BOOKMARK_MENU_TITLE];
	[menuItemSubmenu setMenuChangedMessagesEnabled:NO];
	[contextualMenuItemSubmenu setMenuChangedMessagesEnabled:NO];
	
	while(object = [enumerator nextObject]){
		if([object isKindOfClass:NSDictionaryClass]){
			[self insertBookmarks:object intoMenu:menuItemSubmenu];
			[self insertBookmarks:object intoMenu:contextualMenuItemSubmenu];
			
		}else if([object isKindOfClass:SHMarkedHyperlinkClass]){
			[self insertMenuItemForBookmark:object intoMenu:menuItemSubmenu];
			[self insertMenuItemForBookmark:object intoMenu:contextualMenuItemSubmenu];
			
		}	
	}
	
	[self mainPerformSelector:@selector(gotMenuItemSubmenu:contextualMenuItemSubmenu:)
				   withObject:menuItemSubmenu
				   withObject:contextualMenuItemSubmenu];
	
	[menuItemSubmenu release];
	[contextualMenuItemSubmenu release];
	
	[pool release];
}

//Called by the thread when the submenu NSMenu items have been generated
- (void)gotMenuItemSubmenu:(NSMenu *)menuItemSubmenu contextualMenuItemSubmenu:(NSMenu *)contextualMenuItemSubmenu
{
	//Apply on the next run loop to avoid threadlocking
	[self performSelector:@selector(doSetOfMenuItemSubmenu:contextualMenuItemSubmenu:)
			   withObject:menuItemSubmenu
			   withObject:contextualMenuItemSubmenu
			   afterDelay:0.0001];
}

//Called after a delay by the main thread to actually perform our setting
- (void)doSetOfMenuItemSubmenu:(NSMenu *)menuItemSubmenu contextualMenuItemSubmenu:(NSMenu *)contextualMenuItemSubmenu
{
	[bookmarkRootMenuItem setSubmenu:menuItemSubmenu];
	[bookmarkRootContextualMenuItem setSubmenu:contextualMenuItemSubmenu];
	
	[menuItemSubmenu setMenuChangedMessagesEnabled:YES];
	[contextualMenuItemSubmenu setMenuChangedMessagesEnabled:YES];

	//Update the menus of existing toolbar items
	[self updateAllToolbarItemMenus];

	updatingMenu = NO;
}

//Insert a bookmark (or an array of bookmarks) into the menu
- (void)insertBookmarks:(NSDictionary *)bookmarks intoMenu:(NSMenu *)inMenu
{	
	//Recursively add the contents of the group to the parent menu
	NSMenu			*menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSEnumerator	*enumerator = [[bookmarks objectForKey:SH_BOOKMARK_DICT_CONTENT] objectEnumerator];
	id				object;
	
	while(object = [enumerator nextObject]){		
		if([object isKindOfClass:[SHMarkedHyperlink class]]){
			//Add a menu item for this link
			if(nil != (SHMarkedHyperlink *)[object URL])
				[self insertMenuItemForBookmark:object intoMenu:menu];
			
		}else if([object isKindOfClass:[NSDictionary class]]){
			//Add another submenu
			[self insertBookmarks:object intoMenu:menu];
			
		}
	}
	
	//Insert the submenu we built into the menu
	NSMenuItem		*item = [[[NSMenuItem alloc] initWithTitle:[bookmarks objectForKey:SH_BOOKMARK_DICT_TITLE] action:nil
												 keyEquivalent:@""] autorelease];
	[item setSubmenu:menu];
	[menu setAutoenablesItems:YES];
	[inMenu addItem:item];
}

//Insert a single bookmark into the menu
- (void)insertMenuItemForBookmark:(SHMarkedHyperlink *)object intoMenu:(NSMenu *)inMenu
{
	[inMenu addItemWithTitle:[object parentString]
					  target:self
					  action:@selector(injectBookmarkFrom:)
			   keyEquivalent:@""
		   representedObject:object];
}


//Validation / Updating ------------------------------------------------------------------------------------------------
#pragma mark Validation / Updating
//Validate our bookmark menu item
- (BOOL)validateMenuItem:(id <NSMenuItem>)sender
{
	if(sender == bookmarkRootMenuItem || sender == bookmarkRootContextualMenuItem){
		//Does the bookmark menu need an update?
		if(([importer bookmarksUpdated]) &&
		   (!updatingMenu)){
			[bookmarkRootMenuItem setSubmenu:nil];
			[bookmarkRootContextualMenuItem setSubmenu:nil];
			
			[NSThread detachNewThreadSelector:@selector(buildBookmarkMenuThread)
									 toTarget:self
								   withObject:nil];
		}
		
		//We only care to disable the main menu item (The rest are hidden within it, and do not matter)
		NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		return(responder && [responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]);
		
	}else{
		return(YES);
	}
}

//Dummy menu item target so we can enable/disable our main menu item
- (IBAction)dummyTarget:(id)sender{
}

#pragma mark Toolbar Item

- (void)registerToolbarItem
{
	MVMenuButton *button;
	
	//Unregister the existing toolbar item first
	if(toolbarItem){
		[[adium toolbarController] unregisterToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
		[toolbarItem release]; toolbarItem = nil;
	}
	
	//Register our toolbar item
	button = [[[MVMenuButton alloc] initWithFrame:NSMakeRect(0,0,32,32)] autorelease];
	[button setImage:[NSImage imageNamed:@"bookmarkToolbar" forClass:[self class]]];
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
    [[adium toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}

//When a toolbar item is added (it will be effectively a copy of the one we originally registered)
//we want to set its menu initially, then track it for later menu changes
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if([[item itemIdentifier] isEqualToString:@"InsertBookmark"]){
		[self updateMenuForToolbarItem:item];
		
		if (!toolbarItemArray) toolbarItemArray = [[NSMutableArray alloc] init];
		[toolbarItemArray addObject:item];
	}
}

//The toolbar item was removed; we should now stop tracking (and retaining) it
- (void)toolbarDidRemoveItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if([[item itemIdentifier] isEqualToString:@"InsertBookmark"]){
		[toolbarItemArray removeObject:item];
	}
}

//Update the menus on every toolbar item we are tracking
- (void)updateAllToolbarItemMenus
{
	NSEnumerator	*enumerator;
	NSToolbarItem	*aToolbarItem;

	enumerator = [toolbarItemArray objectEnumerator];
	while (aToolbarItem = [enumerator nextObject]){
		[self updateMenuForToolbarItem:aToolbarItem];
	}
	
}

- (void)updateMenuForToolbarItem:(NSToolbarItem *)item
{
	NSMenu		*menu = [[[bookmarkRootMenuItem submenu] copy] autorelease];
	NSString	*menuTitle = [menu title];
	
	//Add menu to view
	[[item view] setMenu:menu];
	
	//Add menu to toolbar item (for text mode)
	NSMenuItem	*mItem = [[[NSMenuItem alloc] init] autorelease];
	[mItem setSubmenu:menu];
	[mItem setTitle:(menuTitle ? menuTitle : @"")];
	[item setMenuFormRepresentation:mItem];	
}


@end
