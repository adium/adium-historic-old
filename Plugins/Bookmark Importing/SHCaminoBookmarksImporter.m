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
DeclareString(bookmarkDictTitle)
DeclareString(bookmarkDictContent)

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
    
    InitString(bookmarkDictTitle,SH_BOOKMARK_DICT_TITLE)
    InitString(bookmarkDictContent,SH_BOOKMARK_DICT_CONTENT)
    
    [super init];
    emptyArray = [[NSArray alloc] init];
    lastModDate = nil;
    return self;
}

- (void)dealloc
{
	[lastModDate release];
	[super dealloc];
}

- (NSArray *)availableBookmarks
{
    NSString        *bookmarkPath = [CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath];
    NSDictionary    *bookmarkDict = [NSDictionary dictionaryWithContentsOfFile:bookmarkPath];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarkPath traverseLink:YES];
    [lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    return [self drillPropertyList:[bookmarkDict objectForKey:CaminoDictChildKey]];
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
				SHMarkedHyperlink	*menuLink = [self hyperlinkForBookmark:linkDict];
                if(menuLink) [caminoArray addObject:menuLink];
				
            }else{
                NSArray 		*outArray = [linkDict objectForKey:CaminoDictChildKey];
				NSDictionary	*menuDict = [self menuDictWithTitle:[linkDict objectForKey:caminoDictTitleKey]
														  menuItems:[self drillPropertyList:outArray? outArray : emptyArray]];
                if(menuDict) [caminoArray addObject:menuDict];
            }
        }
    }
    return caminoArray;
}

- (NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems
{
	if(!inTitle || !inMenuItems) return(nil);
    return [NSDictionary dictionaryWithObjectsAndKeys:inTitle, bookmarkDictTitle, inMenuItems, bookmarkDictContent, nil];
}

- (SHMarkedHyperlink *)hyperlinkForBookmark:(NSDictionary *)inDict
{
    NSString    *title = [inDict objectForKey:caminoDictTitleKey];
	NSString	*url = [inDict objectForKey:caminoDictURLKey];
	
	if(!title || !url) return(nil);
    return  [[[SHMarkedHyperlink alloc] initWithString:url
                                  withValidationStatus:SH_URL_VALID
                                          parentString:title
                                              andRange:NSMakeRange(0,[title length])] autorelease];
}

@end
