//
//  SHBookmarksImporterPlugin.m
//  Adium
//
//  Created by Stephen Holt on Wed May 19 2004.

#import "SHBookmarksImporterPlugin.h"

#define ROOT_MENU_TITLE     AILocalizedString(@"Bookmarks",nil)

@interface SHBookmarksImporterPlugin(PRIVATE)
- (void)installImporterClass:(Class)inClass;
- (void)configureMenus:(id)sender;
- (NSMenu *)buildBookmarkMenuFor:(id <NSMenuItem>)menuItem;
- (void)_rebuildMenus:(NSMenuItem *)menuItem isFromMainMenu:(BOOL)fromMain;
@end

@class SHSafariBookmarksImporter, SHCaminoBookmarksImporter, SHMozillaBookmarksImporter,
       SHFireFoxBookmarksImporter, SHMSIEBookmarksImporter, SHOmniWebBookmarksImporter;

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
    [self installImporterClass:[SHMozillaBookmarksImporter class]];
    [self installImporterClass:[SHFireFoxBookmarksImporter class]];
    [self installImporterClass:[SHMSIEBookmarksImporter class]];
    [self installImporterClass:[SHOmniWebBookmarksImporter class]];

    bookmarkRootMenuItem = [[[NSMenuItem alloc] initWithTitle:ROOT_MENU_TITLE
                                                       target:self
                                                       action:@selector(dummyTarget:)
                                                keyEquivalent:@""] autorelease];
    [bookmarkRootMenuItem setRepresentedObject:self];
                                               
    bookmarkRootContextualMenuItem = [[[NSMenuItem alloc] initWithTitle:ROOT_MENU_TITLE
                                                                 target:self
                                                                 action:@selector(dummyTarget:)
                                                          keyEquivalent:@""] autorelease];
    [bookmarkRootContextualMenuItem setRepresentedObject:self];
    
    bookmarksLock = [[NSLock alloc] init];
    // initial menu configuration
    [NSThread detachNewThreadSelector:@selector(configureMenus:)
                             toTarget:self
                           withObject:nil];
    
    [[adium menuController] addMenuItem:bookmarkRootMenuItem toLocation:LOC_Edit_Additions];
    [[adium menuController] addContextualMenuItem:bookmarkRootContextualMenuItem toLocation:Context_TextView_LinkAction];
}

- (void)uninstallPlugin
{
    //blank for now
}

- (IBAction)dummyTarget:(id)sender
{
    //nothing to see here...
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

- (void)configureMenus:(id)sender
{
    NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
    [bookmarksLock lock];
    
    NSEnumerator *enumerator = [importerArray objectEnumerator];
    NSObject <SHBookmarkImporter> *importer;
    
    // create a new menu
    bookmarkSets = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    
    NSMutableArray *activeImporters = [NSMutableArray array];
    while(importer = [enumerator nextObject]){
        if([importer bookmarksExist]){
            [activeImporters addObject:importer];
        }
    }
    
    unsigned int activeCount = [activeImporters count];
    
    if(1 == activeCount){
        singularMenu = YES;
        firstMenuItem = bookmarkRootMenuItem;
    }else if(activeCount > 1){
        singularMenu = NO;
    }else{
        [bookmarkRootMenuItem setEnabled:NO];
        [bookmarkRootContextualMenuItem setEnabled:NO];
        return;
    }
    
    enumerator = [activeImporters objectEnumerator];
    // iterate through each importer, and build a menu if it's bookmark file exists
    while(importer = [enumerator nextObject]){
        if(!singularMenu){
            firstMenuItem = [[[NSMenuItem alloc] initWithTitle:[importer menuTitle]
                                                        target:self
                                                        action:nil
                                                 keyEquivalent:@""] autorelease];
            [bookmarkSets addItem:firstMenuItem];
        }
        [firstMenuItem setRepresentedObject:importer];
        
        firstSubmenu = [self buildBookmarkMenuFor:firstMenuItem];
        [firstMenuItem setSubmenu:firstSubmenu];
    }
    
    // install the subMenus to their menuItems
    if(activeCount > 1){
        [bookmarkRootMenuItem setSubmenu:bookmarkSets];
        [bookmarkRootContextualMenuItem setSubmenu:[[bookmarkSets copy] autorelease]];
    }else{
        [bookmarkRootContextualMenuItem setSubmenu:[[[bookmarkRootMenuItem submenu] copy] autorelease]];
    }
    [bookmarksLock unlock];
    [pool release];
}

- (NSMenu *)buildBookmarkMenuFor:(id <NSMenuItem>)menuItem
{
    // fetch the importer class from the menu item and call its parsing method
    id <SHBookmarkImporter> importer = [menuItem representedObject];
    return [[importer parseBookmarksForOwner:self] retain];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    if([[(NSMenuItem *)menuItem representedObject] isKindOfClass:[SHMarkedHyperlink class]])
        return YES;
    // here's how the basic menu update process works:
    //      1. the menuItem being validated must be the main "Bookmarks" menu item, else stop.
    //      2. we get the item array for the menu and enumerate it.
    //      3. for each menu item:
    //          1. check to see that the menu item's represented item impliments the SHBookmarkImporter protocol, else stop.
    //          2. check to see that the relevant bookmarks file has been updated, else go to the next enumerator object.
    //          3. remove the menu item's submenu's items and call the importer to give us a rebuilt menu of bookmarks
    //          4. copy the new menu into the contextual "Bookmarks" menu item submenu.
    //
    // The actual implementation is the same as above, but if the item isn't the main menu's "Bookmarks" item
    // we check to see if it's the analogous contextual menu item, and repeat, adjusting the menu copying portion appropriately.
    
    // The insane control flow here is a quick attempt at reducing the number of compares, or at lest their overall complexity
 
    NSMenuItem              *subMenuItem;
    id<SHBookmarkImporter>   importer;
    BOOL                     toBeReplaced = NO,replaced = NO,fromMain = NO;
       
    if([(NSMenuItem *)menuItem isEqualTo:bookmarkRootMenuItem]){
        fromMain = YES;
        toBeReplaced = YES;
    }else if([[menuItem title] isEqualToString:[bookmarkRootContextualMenuItem title]]){
        fromMain = NO;
        toBeReplaced = YES;
    }
    
    if(toBeReplaced){
        if([[menuItem representedObject] isNotEqualTo:self]){
            importer = [menuItem representedObject];
            if([importer bookmarksUpdated]){
                [[menuItem submenu] removeAllItems];
                [menuItem setSubmenu:[self buildBookmarkMenuFor:menuItem]];
                replaced = YES;
            }
        }else{
            NSEnumerator    *enumerator = [[[menuItem submenu] itemArray] objectEnumerator];
            while(subMenuItem = [enumerator nextObject]){
                if([[subMenuItem representedObject] conformsToProtocol:@protocol(SHBookmarkImporter)]){
                    importer = [subMenuItem representedObject];
                    if([importer bookmarksUpdated]){
                        [[subMenuItem submenu] removeAllItems];
                        [subMenuItem setSubmenu:[self buildBookmarkMenuFor:subMenuItem]];
                        replaced = YES;
                    }
                }
            }
        }
    }
    if(replaced){
        if(fromMain){
            [bookmarkRootContextualMenuItem setSubmenu:[[[bookmarkRootMenuItem submenu] copy] autorelease]];
        }else{
            [bookmarkRootMenuItem setSubmenu:[[[bookmarkRootContextualMenuItem submenu] copy] autorelease]];
        }
    }

    // Enable or disable the menu based upon the existance of an editable NSTextView in the first responder.
    NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
    if(responder && [responder isKindOfClass:[NSTextView class]]){
        return [(NSTextView *)responder isEditable];
    }else{
        return NO; //Disable the menu item if a text field is not key
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
