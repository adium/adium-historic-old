//
//  SHCaminoBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Thu May 20 2004.

#import "SHBookmarksImporterPlugin.h"
#import "SHCaminoBookmarksImporter.h"

#define CAMINO_BOOKMARKS_PATH   @"~/Library/Application Support/Camino/bookmarks.plist"
#define CAMINO_DICT_CHILD_KEY   @"Children"
#define CAMINO_DICT_FOLDER_KEY  @"FolderType"
#define CAMINO_DICT_TITLE_KEY   @"Title"
#define CAMINO_DICT_URL_KEY     @"URL"

#define CAMINO_ROOT_MENU_TITLE  AILocalizedString(@"Camino",nil)

@interface SHSafariBookmarksImporter(PRIVATE)
-(void)drillPropertyList:(id)inObject;
-(void)menuItemFromDict:(NSDictionary *)inDict;
@end

@implementation SHCaminoBookmarksImporter

-(NSMenu *)parseBookmarksForOwner:(id)inObject
{
    owner = inObject;
    NSDictionary    *bookmarkDict = [NSDictionary dictionaryWithContentsOfFile:[CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath]];
    
    safariBookmarksMenu = [[[NSMenu alloc] initWithTitle:CAMINO_ROOT_MENU_TITLE] autorelease];
    safariBookmarksSupermenu = safariBookmarksMenu;
    [self drillPropertyList:bookmarkDict];
    
    return safariBookmarksMenu;
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath]];
}

-(NSString *)menuTitle
{
    return [bookmarksMenu title];
}


-(void)drillPropertyList:(id)inObject
{
    if([inObject isKindOfClass:[NSDictionary class]]){
        // for the list type, recurrsively call the "Children" NSArray
        [self drillPropertyList:[(NSDictionary *)inObject objectForKey:CAMINO_DICT_CHILD_KEY]];
    }else if([inObject isKindOfClass:[NSArray class]]){
        // if we're passed a NSArray object, it can contain both list and leaf dict types,
        // so, we grab an enumerator from the array, and handle each case
        NSEnumerator *enumerator = [(NSArray *)inObject objectEnumerator];
        id outObject;
        
        while(outObject = [enumerator nextObject]){
            if(nil == [(NSDictionary *)outObject objectForKey:CAMINO_DICT_FOLDER_KEY]){
                // if outObject is of type leaf, get it's menuItem, then add it to the local menu.
                [self menuItemFromDict:outObject];
            }else{
                // if outObject is a list, then get the array it contains, then push the menu down.
                bookmarksSupermenu = bookmarksMenu;
                bookmarksMenu = [[[NSMenu alloc] initWithTitle:[(NSDictionary *)outObject objectForKey:SAFARI_DICT_TITLE]] autorelease];
                
                NSMenuItem *subMenuItem = [[[NSMenuItem alloc] initWithTitle:[bookmarksMenu title]
                                                                            target:owner
                                                                            action:nil
                                                                     keyEquivalent:@""] autorelease];
                [bookmarksSupermenu addItem:[subMenuItem retain]];
                [bookmarksSupermenu setSubmenu:[bookmarksMenu retain] forItem:subMenuItem];
                [self drillPropertyList:outObject];
            }
        }
        
        if(nil != [bookmarksMenu supermenu]){
            //so long as the supermenu exists, pop it up.
            bookmarksMenu = bookmarksSupermenu;
            bookmarksSupermenu = [bookmarksSupermenu supermenu];
        }
    }
}

-(void)menuItemFromDict:(NSDictionary *)inDict
{
    // for convienence, refer to the URIDictionary by it's own variable
    //NSDictionary *URIDict = [inDict objectForKey:SAFARI_DICT_URIDICT];
            
    NSDictionary *linkDict = [[NSDictionary dictionaryWithObjectsAndKeys:
        [[inDict objectForKey:CAMINO_DICT_TITLE_KEY] retain], KEY_LINK_TITLE,
        [[inDict objectForKey:CAMINO_DICT_URL_KEY] retain], KEY_LINK_URL,
        nil] autorelease];
    
    [bookmarksMenu addItemWithTitle:[inDict objectForKey:CAMINO_DICT_TITLE_KEY]
                                  target:owner
                                  action:@selector(selectFavoriteURL:)
                           keyEquivalent:@""
                       representedObject:[linkDict retain]];
}

@end
