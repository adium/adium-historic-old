//
//  SHBookmarksImporterPlugin.m
//  Adium
//
//  Created by Stephen Holt on Wed May 19 2004.

#import "SHBookmarksImporterPlugin.h"

#define ROOT_MENU_TITLE     AILocalizedString(@"Bookmarks",nil)

@interface SHBookmarksImporterPlugin(PRIVATE)
- (void)installImporterClass:(Class)inClass;
- (void)configureMenus;
- (NSMenu *)buildBookmarkMenuFor:(id <NSMenuItem>)menuItem;
@end

@class SHSafariBookmarksImporter, SHCaminoBookmarksImporter;

@implementation SHBookmarksImporterPlugin

static NSMenuItem   *bookmarkRootMenuItem;
static NSMenuItem   *bookmarkRootContextualMenuItem;
static NSMenuItem   *firstMenuItem;
static NSMenu       *firstSubmenu;
static NSMenu       *bookmarkSets;
- (void)installPlugin
{
    importerArray = [[[NSMutableArray alloc] init] autorelease];
    
    // install new importer classes here - very similar to AIPluginController
    [self installImporterClass:[SHSafariBookmarksImporter class]];
    [self installImporterClass:[SHCaminoBookmarksImporter class]];
                                                         
    // install our menuItems
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
    
    // initial menu configuration
    [self configureMenus];
    
    [[adium menuController] addMenuItem:bookmarkRootMenuItem toLocation:LOC_Edit_Additions];
    [[adium menuController] addContextualMenuItem:bookmarkRootContextualMenuItem toLocation:Context_TextView_LinkAction];
}

- (void)uninstallPlugin
{
    //blank for now
}

// method to nicely install new importers
- (void)installImporterClass:(Class)inClass
{
    id object = [inClass newInstanceOfImporter];
    
    if(object){
        [importerArray addObject:object];
    }else{
        NSString *failureNotice = [NSString stringWithFormat:@"Failed to load bookmark importer %@",NSStringFromClass(inClass)];
        NSAssert(object,failureNotice);
    }
}

- (void)configureMenus
{
    NSEnumerator *enumerator = [importerArray objectEnumerator];
    id <SHBookmarkImporter> importer;
    
    // clear out any subMenus before adding new ones.
    if([bookmarkRootMenuItem submenu]) [[bookmarkRootMenuItem submenu] removeAllItems];
    if([bookmarkRootContextualMenuItem submenu]) [[bookmarkRootContextualMenuItem submenu] removeAllItems];
    
    // create a new menu
    bookmarkSets = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    
    // iterate through each importer, and build a menu if it's bookmark file exists
    while(importer = [enumerator nextObject]){
        if([importer bookmarksExist]){
            firstMenuItem = [[[NSMenuItem alloc] initWithTitle:[importer menuTitle]
                                                              target:self
                                                              action:nil
                                                       keyEquivalent:@""] autorelease];
            [firstMenuItem setRepresentedObject:importer];
            [bookmarkSets addItem:firstMenuItem];

            firstSubmenu = [self buildBookmarkMenuFor:firstMenuItem];
            [firstMenuItem setSubmenu:firstSubmenu];
        }
    }
    
    // install the subMenus to their menuItems
    if([bookmarkSets numberOfItems]){
        [bookmarkRootMenuItem setSubmenu:bookmarkSets];
        [bookmarkRootContextualMenuItem setSubmenu:[[bookmarkSets copy] autorelease]];
    }
}

- (NSMenu *)buildBookmarkMenuFor:(id <NSMenuItem>)menuItem
{
    // fetch the importer class from the menu item and call its parsing method
    id <SHBookmarkImporter> importer = [menuItem representedObject];
    return [[importer parseBookmarksForOwner:self] retain];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];

        // if for each active importer (actually in the menu) update it's items if it's changed sice the last time
//        if([[[bookmarkRootMenuItem submenu] itemArray] count]){
//            NSEnumerator *enumerator = [[[bookmarkRootMenuItem submenu] itemArray] objectEnumerator];
//            NSMenuItem *object;
//            NSMenu  *newMenu = nil;
//            while(object = [enumerator nextObject]){
//                if([[object representedObject] conformsToProtocol:@protocol(SHBookmarkImporter)]){
//                    if([[object representedObject] bookmarksUpdated]){
//                        // the menu needs to be changed (bookmarks file mod. date changed)
//                        // so remove the items, rebuild the menu, then reinstall it
//                        [[object submenu] removeAllItems];
//                        newMenu = [self buildBookmarkMenuFor:object];
//                        [object setSubmenu:newMenu];
//                        [bookmarkRootContextualMenuItem setSubmenu:[[[bookmarkRootMenuItem submenu] copy] autorelease]];
//                    }
//                }
//            }
//        }else{
//            return NO; // disable if no sets are active (which would only happen if no browsers were installed... hey, it could happen!
//        }
        
        if(responder && [responder isKindOfClass:[NSTextView class]]){
		return(YES);
	}else{
		return(NO); //Disable the menu item if a text field is not key
	}
}

// insert the link into the textView
- (void)injectBookmarkFrom:(id)sender
{
    // if the sender has a hyperlink attached to it...
    if([[(NSMenuItem *)sender representedObject] isKindOfClass:[SHMarkedHyperlink class]]){
        SHMarkedHyperlink   *markedLink = [(NSMenuItem *)sender representedObject];
        NSResponder         *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	
        // if the first responder is a text view...
        if(responder && [responder isKindOfClass:[NSTextView class]]){
            NSTextView      *topView = (NSTextView *)responder;
            NSDictionary    *typingAttributes = [topView typingAttributes];
            
            // new mutable string to build the link with
            NSMutableAttributedString	*linkString = [[[NSMutableAttributedString alloc] initWithString:[markedLink parentString]
                                                                                              attributes:typingAttributes] autorelease];
            [linkString addAttribute:NSLinkAttributeName value:[markedLink URL] range:[markedLink range]];
            
            // insert the link to the text view..
            NSRange selRange = [topView selectedRange];
            [[topView textStorage] replaceCharactersInRange:selRange withAttributedString:linkString];
            
            // special cases for insertion:
            if([[topView string] characterAtIndex:(selRange.location + [markedLink range].length + 1)] != ' '){
                // if we insert a link and the next char isn't a space, insert one.
                NSAttributedString  *tmpString = [[[NSAttributedString alloc] initWithString:@" "
                                                                                  attributes:typingAttributes] autorelease];
                [[topView textStorage] insertAttributedString:tmpString
                                                      atIndex:(selRange.location + [markedLink range].length)];
            }
        }
    }
}

@end
