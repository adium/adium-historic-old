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
-(NSArray *)drillPropertyList:(id)inObject;
- (NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems;
- (SHMarkedHyperlink *)hyperlinkForBookmark:(NSDictionary *)inDict;
@end

@implementation SHCaminoBookmarksImporter

DeclareString(CaminoDictChildKey)
DeclareString(caminoDictFolderKey)
DeclareString(caminoDictTitleKey)
DeclareString(caminoDictURLKey)

static NSArray *emptyArray;

+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

- (id)init
{
    InitString(CaminoDictChildKey,CAMINO_DICT_CHILD_KEY)
    InitString(caminoDictFolderKey,CAMINO_DICT_FOLDER_KEY)
    InitString(caminoDictTitleKey,CAMINO_DICT_TITLE_KEY)
    InitString(caminoDictURLKey,CAMINO_DICT_URL_KEY)
    
    [super init];
    emptyArray = [[NSArray alloc] init];
    
    return self;
}

- (NSArray *)availableBookmarks
{
    NSString        *bookmarkPath = [CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath];
    NSDictionary    *bookmarkDict = [NSDictionary dictionaryWithContentsOfFile:bookmarkPath];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarkPath traverseLink:YES];
    [lastModDate autorelease]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    return [self drillPropertyList:[bookmarkDict objectForKey:CaminoDictChildKey]];
   //return [self drillPropertyList:bookmarkDict];
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath]];
}

-(BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}

-(NSArray *)drillPropertyList:(id)inObject
{
    NSMutableArray  *caminoArray = [NSMutableArray array];
    
    if([inObject isKindOfClass:[NSArray class]]){
        NSEnumerator    *enumerator = [(NSArray *)inObject objectEnumerator];
        NSDictionary    *linkDict;
        
        while(linkDict = [enumerator nextObject]){
            if(nil == [linkDict objectForKey:caminoDictFolderKey]){
                [caminoArray addObject:[self hyperlinkForBookmark:linkDict]];
            }else{
                NSArray *outArray = [linkDict objectForKey:CaminoDictChildKey];
                [caminoArray addObject:[self menuDictWithTitle:[linkDict objectForKey:caminoDictTitleKey]
                             menuItems:[self drillPropertyList:outArray? outArray : emptyArray]]];
            }
        }
    }
    return caminoArray;
}

- (NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems
{
    return [NSDictionary dictionaryWithObjectsAndKeys:inTitle, @"Title", inMenuItems, @"Content", nil];
}

- (SHMarkedHyperlink *)hyperlinkForBookmark:(NSDictionary *)inDict
{
    NSString    *title = [inDict objectForKey:caminoDictTitleKey];
    return  [[[SHMarkedHyperlink alloc] initWithString:[inDict objectForKey:caminoDictURLKey]
                                  withValidationStatus:SH_URL_VALID
                                          parentString:title
                                              andRange:NSMakeRange(0,[title length])] autorelease];
}

@end
