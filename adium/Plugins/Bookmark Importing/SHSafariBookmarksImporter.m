//
//  SHSafariBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Sun May 16 2004.

#import "SHSafariBookmarksImporter.h"

#define SAFARI_BOOKMARKS_PATH   @"~/Library/Safari/Bookmarks.plist"
#define SAFARI_HISTORY_PATH     @"~/Library/Safari/History.plist"
#define SAFARI_DICT_CHILD       @"Children"
#define SAFARI_DICT_URIDICT     @"URIDictionary"
#define SAFARI_DICT_URLSTRING   @"URLString"
#define SAFARI_DICT_TYPE_KEY    @"WebBookmarkType"
#define SAFARI_DICT_TYPE_LIST   @"WebBookmarkTypeList"
#define SAFARI_DICT_TYPE_LEAF   @"WebBookmarkTypeLeaf"
#define SAFARI_DICT_TITLE       @"Title"
#define SAFARI_DICT_URI_TITLE   @"title"

#define SAFARI_ROOT_MENU_TITLE  AILocalizedString(@"Safari",nil)

@interface SHSafariBookmarksImporter(PRIVATE)
-(void)drillPropertyList:(id)inObject;
-(void)menuItemFromDict:(NSDictionary *)inDict;
@end

@implementation SHSafariBookmarksImporter

static NSMenu   *safariBookmarksMenu;
static NSMenu   *safariBookmarksSupermenu;
static NSMenu   *safariTopMenu;

static NSArray *emptyArray;
+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

- (id)init
{
    [super init];
    emptyArray = [[NSArray alloc] init];
    
    return self;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject
{
    owner = inObject;
    NSDictionary    *bookmarkDict = [NSDictionary dictionaryWithContentsOfFile:[SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath]];
    
    if(safariBookmarksMenu){
        [safariBookmarksMenu removeAllItems];
        [safariBookmarksMenu release];
    }
    
    if (lastModDate) [lastModDate release];
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    safariBookmarksMenu = [[[NSMenu alloc] initWithTitle:SAFARI_ROOT_MENU_TITLE] autorelease];
    safariBookmarksSupermenu = safariBookmarksMenu;
    safariTopMenu = safariBookmarksMenu;
    [self drillPropertyList:bookmarkDict];
        
    return safariBookmarksMenu;
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath]];
}

-(NSString *)menuTitle
{
    return SAFARI_ROOT_MENU_TITLE;
}

-(BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}


-(void)drillPropertyList:(id)inObject
{
    if([inObject isKindOfClass:[NSDictionary class]]){
        // for the list type, recurrsively call the "Children" NSArray
        NSArray *childrenArray = [(NSDictionary *)inObject objectForKey:SAFARI_DICT_CHILD];
        [self drillPropertyList:childrenArray? childrenArray : emptyArray];
    }else if([inObject isKindOfClass:[NSArray class]]){
        // if we're passed a NSArray object, it can contain both list and leaf dict types,
        // so, we grab an enumerator from the array, and handle each case
        NSEnumerator *enumerator = [(NSArray *)inObject objectEnumerator];
        id outObject;
        
        while(outObject = [enumerator nextObject]){
            if([[(NSDictionary *)outObject objectForKey:SAFARI_DICT_TYPE_KEY] isEqualToString:SAFARI_DICT_TYPE_LEAF]){
                // if outObject is of type leaf, get it's menuItem, then add it to the local menu.
                [self menuItemFromDict:outObject];
            }else if([[(NSDictionary *)outObject objectForKey:SAFARI_DICT_TYPE_KEY] isEqualToString:SAFARI_DICT_TYPE_LIST]){
                // if outObject is a list, then get the array it contains, then push the menu down.
                safariBookmarksSupermenu = safariBookmarksMenu;
                safariBookmarksMenu = [[[NSMenu alloc] initWithTitle:[(NSDictionary *)outObject objectForKey:SAFARI_DICT_TITLE]] autorelease];
                
                NSMenuItem *safariSubMenuItem = [[[NSMenuItem alloc] initWithTitle:[safariBookmarksMenu title]
                                                                            target:owner
                                                                            action:nil
                                                                     keyEquivalent:@""] autorelease];
                [safariBookmarksSupermenu addItem:[safariSubMenuItem retain]];
                [safariBookmarksSupermenu setSubmenu:[safariBookmarksMenu retain] forItem:safariSubMenuItem];
                [self drillPropertyList:outObject];
            }
        }
        
        if([safariBookmarksMenu isNotEqualTo:safariTopMenu]){
            //so long as the supermenu exists, pop it up.
            safariBookmarksMenu = safariBookmarksSupermenu;
            safariBookmarksSupermenu = [safariBookmarksSupermenu supermenu];
        }
    }
}

-(void)menuItemFromDict:(NSDictionary *)inDict
{
    // for convienence, refer to the URIDictionary by it's own variable
    NSDictionary *URIDict = [inDict objectForKey:SAFARI_DICT_URIDICT];

    SHMarkedHyperlink *markedLink = [[[SHMarkedHyperlink alloc] initWithString:[[inDict objectForKey:SAFARI_DICT_URLSTRING] retain]
                                                          withValidationStatus:SH_URL_VALID
                                                                  parentString:[URIDict objectForKey:SAFARI_DICT_URI_TITLE]
                                                                      andRange:NSMakeRange(0,[(NSString *)[URIDict objectForKey:SAFARI_DICT_URI_TITLE] length])] autorelease];
    
    [safariBookmarksMenu addItemWithTitle:[URIDict objectForKey:SAFARI_DICT_URI_TITLE]
                                  target:owner
                                  action:@selector(injectBookmarkFrom:)
                           keyEquivalent:@""
                       representedObject:[markedLink retain]];
}

@end
