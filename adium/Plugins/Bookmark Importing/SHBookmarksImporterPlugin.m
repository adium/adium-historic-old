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
    
    [self installImporterClass:[SHSafariBookmarksImporter class]];
    //[self installImporterClass:[SHCaminoBookmarksImporter class]];
                                                         
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
    [[adium menuController] addContextualMenuItem:bookmarkRootContextualMenuItem toLocation:Context_TextView_LinkAction];
}

- (void)uninstallPlugin
{
}

- (void)installImporterClass:(Class)inClass
{
    id object = [[[inClass alloc] init] autorelease];
    
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
    
    if([bookmarkRootMenuItem submenu]) [[bookmarkRootMenuItem submenu] removeAllItems];
    if([bookmarkRootContextualMenuItem submenu]) [[bookmarkRootContextualMenuItem submenu] removeAllItems];
    
    bookmarkSets = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    
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
    if([bookmarkSets numberOfItems]){
        [bookmarkRootMenuItem setSubmenu:bookmarkSets];
        [bookmarkRootContextualMenuItem setSubmenu:[[bookmarkSets copy] autorelease]];
    }
}

- (NSMenu *)buildBookmarkMenuFor:(id <NSMenuItem>)menuItem
{
    id <SHBookmarkImporter> importer = [menuItem representedObject];
    return [[importer parseBookmarksForOwner:self] retain];
    //[menuItem setSubmenu:importerMenu];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
//	if([[menuItem representedObject] conformsToProtocol:@protocol(SHBookmarkImporter)]){
//            if([[menuItem representedObject] bookmarksUpdated]){
//                [self buildBookmarkMenuFor:menuItem];
//            }
//        }

        if([[[bookmarkRootMenuItem submenu] itemArray] count]){
            NSEnumerator *enumerator = [[[bookmarkRootMenuItem submenu] itemArray] objectEnumerator];
            NSMenuItem *object;
            NSMenu  *newMenu = nil;
            while(object = [enumerator nextObject]){
                if([[object representedObject] conformsToProtocol:@protocol(SHBookmarkImporter)]){
                    if([[object representedObject] bookmarksUpdated]){
                        NSLog(@"building new menu");
                        [[object submenu] removeAllItems];
                        newMenu = [self buildBookmarkMenuFor:object];
                        [object setSubmenu:newMenu];
                        [[[(NSMenuItem *)bookmarkRootContextualMenuItem submenu] itemAtIndex:[[(NSMenuItem *)bookmarkRootMenuItem submenu] indexOfItem:object]]
                                                                                setSubmenu:[[newMenu copy] autorelease]];
                        NSLog(@"built new menu");
                    }
                }
            }
//            if(newMenu){
//                [[bookmarkRootMenuItem submenu] removeAllItems];
//                [[bookmarkRootContextualMenuItem submenu] removeAllItems]; 
//                
//                [bookmarkRootMenuItem setSubmenu:newMenu];
//                [bookmarkRootContextualMenuItem setSubmenu:[[newMenu copy] autorelease]];
//            }
        }else{
            return NO;
        }
        
        if(responder && [responder isKindOfClass:[NSTextView class]]){
		return(YES);
	}else{
		return(NO); //Disable the menu item if a text field is not key
	}
}

- (void)injectBookmarkFrom:(id)sender
{
    if([[(NSMenuItem *)sender representedObject] isKindOfClass:[SHMarkedHyperlink class]]){
        SHMarkedHyperlink   *markedLink = [(NSMenuItem *)sender representedObject];
        NSResponder         *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	
        if(responder && [responder isKindOfClass:[NSTextView class]]){
            NSTextView      *topView = (NSTextView *)responder;
            NSDictionary    *typingAttributes = [topView typingAttributes];
            
            NSMutableAttributedString	*linkString = [[[NSMutableAttributedString alloc] initWithString:[markedLink parentString]
                                                                                              attributes:typingAttributes] autorelease];
            [linkString addAttribute:NSLinkAttributeName value:[markedLink URL] range:[markedLink range]];
            
            NSRange selRange = [topView selectedRange];
            [[topView textStorage] replaceCharactersInRange:selRange withAttributedString:linkString];
            
            if([[topView string] length] == selRange.location + selRange.length){
                NSRange newSelRange = NSMakeRange(selRange.location + selRange.length, 0);
                [topView setSelectedRange:newSelRange];
                [topView setSelectedTextAttributes:typingAttributes];
            }else if([[topView string] characterAtIndex:(selRange.location + [markedLink range].length + 1)] != ' '){
                NSAttributedString  *tmpString = [[[NSAttributedString alloc] initWithString:@" "
                                                                                  attributes:typingAttributes] autorelease];
                [[topView textStorage] insertAttributedString:tmpString
                                                      atIndex:(selRange.location + [markedLink range].length)];
            }
        }
    }
}

@end
