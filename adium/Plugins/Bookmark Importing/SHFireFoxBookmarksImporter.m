//
//  SHFireFoxBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Sun May 30 2004.

#import "SHFireFoxBookmarksImporter.h"
#import "SHMozillaCommonParser.h"

#define FIREFOX_BOOKMARKS_PATH  @"~/Library/Phoenix/Profiles/default"
#define FIREFOX_9_BOOKMARKS_PATH @"~/Library/Application Support/Firefox/Profiles"
#define FIREFOX_BOOKMARKS_FILE_NAME @"bookmarks.html"

#define FIREFOX_ROOT_MENU_TITLE AILocalizedString(@"FireFox",nil)

@class SHMozillaCommonParser;

@interface SHFireFoxBookmarksImporter(PRIVATE)
- (NSString *)bookmarkPath;
- (NSString *)fox9BookmarkPath;
@end

@implementation SHFireFoxBookmarksImporter

#pragma mark protocol methods
+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

- (id)init
{
	[super init];
	
	bookmarkPath = nil;
	fox9BookmarkPath = nil;
	lastModDate = nil;
    fox9 = [[NSFileManager defaultManager] fileExistsAtPath:[self fox9BookmarkPath]];
	
    return self;
}

- (void)dealloc
{
	[bookmarkPath release];
	[fox9BookmarkPath release];
	[lastModDate release]; lastModDate = nil;
	
	[super dealloc];
}
- (NSArray *)availableBookmarks
{
	NSString		*path = (fox9 ? [self fox9BookmarkPath] : [self bookmarkPath]);
    NSString		*bookmarkString = [NSString stringWithContentsOfFile:path];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:path
																		 traverseLink:YES];
	
    [lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    return [SHMozillaCommonParser parseBookmarksfromString:bookmarkString];
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:(fox9 ? [self fox9BookmarkPath] : [self bookmarkPath])];
}

-(NSString *)menuTitle
{
    return FIREFOX_ROOT_MENU_TITLE;
}

-(BOOL)bookmarksUpdated
{
    NSDictionary	*fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:(fox9 ? [self fox9BookmarkPath] : [self bookmarkPath])
																		 traverseLink:YES];
    NSDate			*modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return (modDate && ![modDate isEqualToDate:lastModDate]);
}

#pragma mark private methods
- (NSString *)bookmarkPath
{
	if (!bookmarkPath){
		NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:[FIREFOX_BOOKMARKS_PATH stringByExpandingTildeInPath]] objectEnumerator];
		NSString    *directory;
		
		while(directory = [enumerator nextObject]){
			NSRange found = [directory rangeOfString:@".slt"];
			if(found.location != NSNotFound){
				bookmarkPath = [[NSString stringWithFormat:@"%@/%@/%@",[FIREFOX_BOOKMARKS_PATH stringByExpandingTildeInPath], directory, FIREFOX_BOOKMARKS_FILE_NAME] retain];
				break;
			}
		}
		
		if (!bookmarkPath) bookmarkPath = [FIREFOX_BOOKMARKS_PATH retain];
	}
	
	return bookmarkPath;
}

- (NSString *)fox9BookmarkPath
{
	if (!fox9BookmarkPath){
		NSArray     *dirContents = [[NSFileManager defaultManager] directoryContentsAtPath:[FIREFOX_9_BOOKMARKS_PATH stringByExpandingTildeInPath]];
		
		if(nil != dirContents){
			NSEnumerator *enumerator = [dirContents objectEnumerator];
			NSString    *directory;
			
			while(directory = [enumerator nextObject]){
				NSRange found = [directory rangeOfString:@"default."];
				if(found.location != NSNotFound){
					fox9BookmarkPath = [[NSString stringWithFormat:@"%@/%@/%@",[FIREFOX_9_BOOKMARKS_PATH stringByExpandingTildeInPath], directory, FIREFOX_BOOKMARKS_FILE_NAME] retain];
					break;
				}
			}
		}
	}
	
    return fox9BookmarkPath;
}

@end