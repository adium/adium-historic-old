//
//  SHMozillaBookmarksImporter.m
//  Adium
//
//  Created by Stephen Holt on Tue May 25 2004.

#import "SHMozillaBookmarksImporter.h"
#import "SHMozillaCommonParser.h"

#define MOZILLA_BOOKMARKS_PATH  @"~/Library/Mozilla/Profiles/default"
#define MOZILLA_BOOKMARKS_FILE_NAME @"bookmarks.html"

#define MOZILLA_ROOT_MENU_TITLE AILocalizedString(@"Mozilla",nil)

@class SHMozillaCommonParser;

@interface SHMozillaBookmarksImporter(PRIVATE)
- (NSString *)bookmarkPath;
@end

@implementation SHMozillaBookmarksImporter

#pragma mark protocol methods
+ (id)newInstanceOfImporter
{
    return [[[self alloc] init] autorelease];
}

- (NSArray *)availableBookmarks
{
    NSString    *bookmarkString = [NSString stringWithContentsOfFile:[self bookmarkPath]];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[self bookmarkPath] traverseLink:YES];
    [lastModDate autorelease]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    return [SHMozillaCommonParser parseBookmarksfromString:bookmarkString];
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self bookmarkPath]];
}

-(BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[self bookmarkPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}

#pragma mark private methods
- (NSString *)bookmarkPath
{
    NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:[MOZILLA_BOOKMARKS_PATH stringByExpandingTildeInPath]] objectEnumerator];
    NSString    *directory;
    
    while(directory = [enumerator nextObject]){
        NSRange found = [directory rangeOfString:@".slt"];
        if(found.location != NSNotFound)
            return [NSString stringWithFormat:@"%@/%@/%@",[MOZILLA_BOOKMARKS_PATH stringByExpandingTildeInPath], directory, MOZILLA_BOOKMARKS_FILE_NAME];
    }
    return MOZILLA_BOOKMARKS_PATH;
}

@end
