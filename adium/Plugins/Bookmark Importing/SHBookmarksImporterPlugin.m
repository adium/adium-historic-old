//
//  SHBookmarksImporterPlugin.m
//  Adium
//
//  Created by Stephen Holt on Wed May 19 2004.

#import "SHBookmarksImporterPlugin.h"

#define ROOT_MENU_TITLE     AILocalizedString(@"Bookmarks",nil)

@interface SHBookmarksImporterPlugin(PRIVATE)
- (void)installImporterClass:(Class)inClass;
- (void)_forkBookmarkThread:(id)sender;
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
    NSURL   *appURL = nil; // file URL to the web browser application path
    importerArray = [[[NSMutableArray alloc] init] autorelease];
    
    // We ask Launch services to tell us the default handler for the text/html MIME type.
    // That'd better be the default web brower on the system - if it's not, the user has bigger problems
    // This should also get us the most likely set of relevant bookmarks, while sparing us from generating
    // a menu from each existing bookmark.
    // If that's not the case, then we really have to ask why the user doesn't keep bookmarks in their default browser.
    if(noErr == LSCopyApplicationForMIMEType((CFStringRef)@"text/html",kLSRolesViewer,(CFURLRef *)&appURL)){
        // test that the substring exists somewhere in the path then use that importer
        // Ideally, these should be ordered with the most statistically likely on top. (no sense in doing more work)
        // This is my best guess for that order.
        if(NSNotFound != [[appURL path] rangeOfString:@"Safari"].location){
            [self installImporterClass:[SHSafariBookmarksImporter class]];
        }else if(NSNotFound != [[appURL path] rangeOfString:@"Camino"].location){
            [self installImporterClass:[SHCaminoBookmarksImporter class]];
        }else if(NSNotFound != [[appURL path] rangeOfString:@"Firefox"].location){
            [self installImporterClass:[SHFireFoxBookmarksImporter class]];
        }else if(NSNotFound != [[appURL path] rangeOfString:@"Mozilla"].location){
            [self installImporterClass:[SHMozillaBookmarksImporter class]];
        }else if(NSNotFound != [[appURL path] rangeOfString:@"Internet Explorer"].location){
            [self installImporterClass:[SHMSIEBookmarksImporter class]];
        }else if(NSNotFound != [[appURL path] rangeOfString:@"OmniWeb"].location){
            [self installImporterClass:[SHOmniWebBookmarksImporter class]];
        }
        CFRelease(appURL);
    }
    
    // observe for the Adium_PluginsDidFinishLoading notification
    // this lets us delay the thread until after our controllers have fully init'd.
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(_forkBookmarkThread:)
                                       name:Adium_PluginsDidFinishLoading
                                     object:nil];

    // We delay the thread build, but attach our menus on plugin init.
    // So we need to have something to attach -- or else we'll have problems
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
    
    // init our lock, to make sure the configureMenus: method/thread isn't entered twice
    bookmarksLock = [[NSLock alloc] init];
    
    // pop those menus in the menu.
    [[adium menuController] addMenuItem:bookmarkRootMenuItem toLocation:LOC_Edit_Additions];
    [[adium menuController] addContextualMenuItem:bookmarkRootContextualMenuItem toLocation:Context_TextView_LinkAction];
}

- (void)uninstallPlugin
{
    // remove our observer for Adium_PluginsDidFinishLoading
    [[adium notificationCenter] removeObserver:self
                                          name:Adium_PluginsDidFinishLoading
                                        object:nil];
}

- (IBAction)dummyTarget:(id)sender
{
    //nothing to see here...
}

// wraper method to give the notification selector so we can nicely detach our thread.
- (void)_forkBookmarkThread:(NSNotification *)notification
{
    if([[notification name] isEqualToString:Adium_PluginsDidFinishLoading]){
        [NSThread detachNewThreadSelector:@selector(configureMenus:)
                                 toTarget:self
                               withObject:nil];
    }
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
    
    // are we building for 1 or more (or none) importers?
    if(1 == activeCount){
        // a singular menu - just attach directly to the root.
        singularMenu = YES;
        firstMenuItem = bookmarkRootMenuItem;
    }else if(activeCount > 1){
        // many menus - attach to items in a submenu
        singularMenu = NO;
    }else{
        // no menus.  disable our items, then return
        [bookmarkRootMenuItem setEnabled:NO];
        [bookmarkRootContextualMenuItem setEnabled:NO];
        return;
    }
    
    enumerator = [activeImporters objectEnumerator];
    // iterate through each importer, and build a menu if it's bookmark file exists
    while(importer = [enumerator nextObject]){
        if(!singularMenu){
            // make a new menu item for the browser list submenu, and attach it.
            firstMenuItem = [[[NSMenuItem alloc] initWithTitle:[importer menuTitle]
                                                        target:self
                                                        action:nil
                                                 keyEquivalent:@""] autorelease];
            [bookmarkSets addItem:firstMenuItem];
        }
        // set up the menu.
        [firstMenuItem setRepresentedObject:importer];
        
        firstSubmenu = [self buildBookmarkMenuFor:firstMenuItem]; // build bookmarks menu.
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

- (NSMenu *)buildBookmarkMenuFor:(NSMenuItem *)menuItem
{
    // fetch the importer class from the menu item and call its parsing method
    NSObject <SHBookmarkImporter> *importer = [menuItem representedObject];
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
            NSAttributedString  *tmpString = [[[NSAttributedString alloc] initWithString:@" "
                                                                              attributes:typingAttributes] autorelease];
            if([[topView string] characterAtIndex:(selRange.location + [markedLink range].length + 1)] != ' '){
                // if we insert a link and the next char isn't a space, insert one.
                [[topView textStorage] insertAttributedString:tmpString
                                                      atIndex:(selRange.location + [markedLink range].length)];
            }
            if(selRange.location > 0 && [[topView string] characterAtIndex:(selRange.location - 1)] != ' '){
                // if we insert a link and the previous char isn't a space (or the beginning of the text storage),
                // insert one.
                [[topView textStorage] insertAttributedString:tmpString
                                                      atIndex:selRange.location];
            }
        }
    }
}

@end
