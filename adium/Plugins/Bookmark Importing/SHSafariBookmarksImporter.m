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
- (NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems;
- (NSDictionary *)hyperlinkForSafariBookmark:(NSDictionary *)inDict;
- (NSArray *)drillPropertyList:(id)inObject;
@end

@implementation SHSafariBookmarksImporter

+ (id)newInstanceOfImporter
{
    return([[[self alloc] init] autorelease]);
}

- (id)init
{
	[super init];
	lastModDate = nil;
	return(self);
}

- (void)dealloc
{
	[lastModDate release];
	[super dealloc];
}

//Returns YES if the bookmarks have changed
- (BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}

//Return an array of the available bookmarks
- (NSArray *)availableBookmarks
{
	NSString	*bookmarkPath = [SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath];
	
	//Open the bookmarks
	NSDictionary *bookmarkDict = [NSDictionary dictionaryWithContentsOfFile:bookmarkPath];
	
	//Remember when they were last modified
	NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarkPath traverseLink:YES];
	[lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
	
	//Process them
	return([self drillPropertyList:[bookmarkDict objectForKey:SAFARI_DICT_CHILD]]);
}

//Parse the safari bookmark file
- (NSArray *)drillPropertyList:(id)inObject
{
	NSMutableArray	*array = [NSMutableArray array];

	if([inObject isKindOfClass:[NSArray class]]){
        NSEnumerator *enumerator = [(NSArray *)inObject objectEnumerator];
        NSDictionary *linkDict;
		
        while(linkDict = [enumerator nextObject]){
            if([[linkDict objectForKey:SAFARI_DICT_TYPE_KEY] isEqualToString:SAFARI_DICT_TYPE_LEAF]){
                //We found a link
				[array addObject:[self hyperlinkForSafariBookmark:linkDict]];
				
			}else if([[linkDict objectForKey:SAFARI_DICT_TYPE_KEY] isEqualToString:SAFARI_DICT_TYPE_LIST]){
				//We found an array of links
				[array addObject:[self menuDictWithTitle:[linkDict objectForKey:SAFARI_DICT_TITLE]
											   menuItems:[self drillPropertyList:[linkDict objectForKey:SAFARI_DICT_CHILD]]]];
            }
        }
	}
	
	return(array);
}

//Menu
- (NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems
{
	return([NSDictionary dictionaryWithObjectsAndKeys:inTitle, @"Title", inMenuItems, @"Content", nil]);
}

//Menu Item
- (NSDictionary *)hyperlinkForSafariBookmark:(NSDictionary *)inDict
{
	NSString	*title = [[inDict objectForKey:SAFARI_DICT_URIDICT] objectForKey:SAFARI_DICT_URI_TITLE];
    return([[[SHMarkedHyperlink alloc] initWithString:[inDict objectForKey:SAFARI_DICT_URLSTRING]
								 withValidationStatus:SH_URL_VALID
										 parentString:title
											 andRange:NSMakeRange(0,[title length])] autorelease]);
}

@end
