//
//  SHBookmarksImporterPlugin.m
//  Adium
//
//  Created by Stephen Holt on Wed May 19 2004.

#import "SHBookmarksImporterPlugin.h"

#define ROOT_MENU_TITLE     AILocalizedString(@"Bookmarks",nil)

@interface SHBookmarksImporterPlugin(PRIVATE)
- (void)configureMenus;
- (void)buildBookmarkMenuFor:(id <NSMenuItem>)menuItem;
@end

@implementation SHBookmarksImporterPlugin

- (void)installPlugin
{
    importerArray = [[NSArray arrayWithObjects:[[SHSafariBookmarkImporter alloc] init],
                                                nil] autorelease];
                                                         
    bookmarkRootMenuItem = [[[NSMenuItem alloc] initWithTitle:ROOT_MENU_TITLE
                                                       target:self
                                                       action:nil
                                                keyEquivalent:@""] autorelease];
    [bookmarkRootMenuItem setRepresentedObject:self];
                                               
    bookmarkRootContextualMenuItem = [[[NSMenuItem alloc] initWithTitle:ROOT_MENU_TITLE
                                                                 target:self
                                                                 action:nil
                                                          keyEquivalent:@""] autorelease];
    [bookmarkRootContextualMenuItem setRepresentedObject:self];
    
    [self configureMenus];
    
    [[adium menuController] addMenuItem:bookmarkRootMenuItem toLocation:LOC_Edit_Additions];
    [[adium menuController] addMenuItem:bookmarkRootContextualMenuItem toLocation:Context_TextView_LinkAction];
}

- (void)uninstallPlugin
{
}

- (void)configureMenus
{
    NSEnumerator *enumerator = [importerArray objectEnumerator];
    id <SHBookmarkImporter> importer;
    
    NSMenu  *bookmarkSets = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    
    while(importer = [enumerator nextObject]){
        if([importer bookmarksExist]){
            NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:[importer menuTitle]
                                                              target:self
                                                              action:nil
                                                       keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:importer];
            [bookmarkSets addItem:menuItem];
            [menuItem release];
            NSMenu *subMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
            NSMenuItem *importerMenuItem = [[[NSMenuItem alloc] initWithTitle:@"placeholder"
                                                   target:self
                                                   action:nil
                                            keyEquivalent:@""] autorelease];
            [subMenu addItem:importerMenuItem];
            [menuItem setSubmenu:subMenu];
        }
    }
    if([bookmarkSets numberOfItems]){
        [bookmarkRootMenuItem setSubmenu:bookmarkSets];
        [bookmarkRootContextualMenuItem setSubmenu:[[bookmarkSets copy] autorelease]];
    }
}

- (void)buildBookmarkMenuFor:(id <NSMenuItem>)menuItem
{
    id <SHBookmarkImporter> importer = [menuItem representedObject];
    [menuItem setSubmenu:[importer parseBookmarksForOwner:self]];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	if(responder && [responder isKindOfClass:[NSTextView class]] && nil != [bookmarkRootMenuItem submenu]){
                if([[menuItem representedObject] respondsToSelector:@selector(parseBookmarksForOwner:)]){
                    [self buildBookmarkMenuFor:menuItem];
                }
		return(YES);
	}else{
		return(NO); //Disable the menu item if a text field is not key
	}
}

@end
