//
//  SHCaminoBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Thu May 20 2004.

#import "SHCaminoBookmarksImporter.h"

#define CAMINO_BOOKMARKS_PATH   @"~/Library/Application Support/Camino/bookmarks.plist"
#define CAMINO_DICT_CHILD_KEY   @"Children"
#define CAMINO_DICT_FOLDER_KEY  @"FolderType"
#define CAMINO_DICT_TITLE_KEY   @"Title"
#define CAMINO_DICT_URL_KEY     @"URL"

#define CAMINO_ROOT_MENU_TITLE  AILocalizedString(@"Camino",nil)

@interface SHCaminoBookmarksImporter(PRIVATE)
-(void)drillPropertyList:(id)inObject;
-(void)menuItemFromDict:(NSDictionary *)inDict;
@end

@implementation SHCaminoBookmarksImporter

static NSMenu   *caminoBookmarksMenu;
static NSMenu   *caminoBookmarksSupermenu;
static NSMenu   *caminoTopMenu;

+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

- (id)init
{
    [super init];
    
    return self;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject
{
    owner = inObject;
    NSDictionary    *bookmarkDict = [NSDictionary dictionaryWithContentsOfFile:[CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath]];
    
    // remove our root menu, if it exists
    if(caminoBookmarksMenu){
        [caminoBookmarksMenu removeAllItems];
        [caminoBookmarksMenu release];
    }
    
    // store the modification date for future reference
    if (lastModDate) [lastModDate release];
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    caminoBookmarksMenu = [[[NSMenu alloc] initWithTitle:CAMINO_ROOT_MENU_TITLE] autorelease];
    caminoBookmarksSupermenu = caminoBookmarksMenu;
    caminoTopMenu = caminoBookmarksMenu;
    [self drillPropertyList:bookmarkDict];
    
    return caminoBookmarksMenu;
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath]];
}

-(NSString *)menuTitle
{
    return CAMINO_ROOT_MENU_TITLE;
}

-(BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
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
                caminoBookmarksSupermenu = caminoBookmarksMenu;
                caminoBookmarksMenu = [[[NSMenu alloc] initWithTitle:[(NSDictionary *)outObject objectForKey:CAMINO_DICT_TITLE_KEY]] autorelease];
                
                NSMenuItem *caminoSubmenuItem = [[[NSMenuItem alloc] initWithTitle:[caminoBookmarksMenu title]
                                                                            target:owner
                                                                            action:nil
                                                                     keyEquivalent:@""] autorelease];
                [caminoBookmarksSupermenu addItem:[caminoSubmenuItem retain]];
                [caminoBookmarksSupermenu setSubmenu:[caminoBookmarksMenu retain] forItem:caminoSubmenuItem];
                [self drillPropertyList:outObject];
            }
        }
        
        if([caminoBookmarksMenu isNotEqualTo:caminoTopMenu]){
            //so long as the supermenu exists, pop it up.
            caminoBookmarksMenu = caminoBookmarksSupermenu;
            caminoBookmarksSupermenu = [caminoBookmarksSupermenu supermenu];
        }
    }
}

-(void)menuItemFromDict:(NSDictionary *)inDict
{
    SHMarkedHyperlink *markedLink = [[[SHMarkedHyperlink alloc] initWithString:[[inDict objectForKey:CAMINO_DICT_URL_KEY] retain]
                                                          withValidationStatus:SH_URL_VALID
                                                                  parentString:[inDict objectForKey:CAMINO_DICT_TITLE_KEY]
                                                                      andRange:NSMakeRange(0,[(NSString *)[inDict objectForKey:CAMINO_DICT_TITLE_KEY] length])] autorelease];
    
    [caminoBookmarksMenu addItemWithTitle:[inDict objectForKey:CAMINO_DICT_TITLE_KEY]
                                  target:owner
                                  action:@selector(injectBookmarkFrom:)
                           keyEquivalent:@""
                       representedObject:[markedLink retain]];
}

@end
