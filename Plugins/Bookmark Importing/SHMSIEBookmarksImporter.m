//
//  SHMSIEBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.


#import "SHMSIEBookmarksImporter.h"
#import "SHMozillaCommonParser.h"

#define MSIE_BOOKMARKS_PATH  @"~/Library/Preferences/Explorer/Favorites.html"

#define MSIE_ROOT_MENU_TITLE NSLocalizedString(@"Internet Explorer",nil)

@class SHMozillaCommonParser;

@implementation SHMSIEBookmarksImporter

#pragma mark protocol methods
+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

- (NSArray *)availableBookmarks
{
    NSString    *bookmarkPath = [MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath];
    NSString    *bookmarkString = [NSString stringWithContentsOfFile:bookmarkPath];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarkPath traverseLink:YES];
    [lastModDate autorelease]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    return [SHMozillaCommonParser parseBookmarksfromString:bookmarkString];
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath]];
}

-(BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}

@end
