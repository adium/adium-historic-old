/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "SHFireFoxBookmarksImporter.h"
#import "SHMozillaCommonParser.h"

#define FIREFOX_8_OR_LESS_BOOKMARKS_PATH  @"~/Library/Phoenix/Profiles/default"
#define FIREFOX_9_BOOKMARKS_PATH @"~/Library/Application Support/Firefox/Profiles"
#define FIREFOX_BOOKMARKS_FILE_NAME @"bookmarks.html"

@class SHMozillaCommonParser;

@interface SHFireFoxBookmarksImporter(PRIVATE)
- (NSString *)fox8OrLessBookmarkPath;
- (NSString *)fox9BookmarkPath;
- (NSString *)bookmarkPath;
- (BOOL)bookmarksExist;
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
	
	fox8OrLessBookmarkPath = nil;
	fox9BookmarkPath = nil;
	lastModDate = nil;

    fox9 = ([self fox9BookmarkPath] != nil);
	
    return self;
}

- (void)dealloc
{
	[fox8OrLessBookmarkPath release];
	[fox9BookmarkPath release];
	[lastModDate release]; lastModDate = nil;
	
	[super dealloc];
}
- (NSArray *)availableBookmarks
{
	NSString		*path = [self bookmarkPath];
    NSString		*bookmarkString = [NSString stringWithContentsOfFile:path];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:path
																		 traverseLink:YES];
	
    [lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];

    return [SHMozillaCommonParser parseBookmarksfromString:bookmarkString];
}

-(BOOL)bookmarksExist
{
    return [[NSFileManager defaultManager] fileExistsAtPath: [self bookmarkPath]];
}

-(BOOL)bookmarksUpdated
{
    NSDictionary	*fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[self bookmarkPath]
																		 traverseLink:YES];
    NSDate			*modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return (modDate && ![modDate isEqualToDate:lastModDate]);
}

#pragma mark private methods
- (NSString *)fox8OrLessBookmarkPath
{
	if (!fox8OrLessBookmarkPath){
		NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:[FIREFOX_8_OR_LESS_BOOKMARKS_PATH stringByExpandingTildeInPath]] objectEnumerator];
		NSString    *directory;
		
		while(directory = [enumerator nextObject]){
			NSRange found = [directory rangeOfString:@".slt"];
			if(found.location != NSNotFound){
				fox8OrLessBookmarkPath = [[NSString stringWithFormat:@"%@/%@/%@",[FIREFOX_8_OR_LESS_BOOKMARKS_PATH stringByExpandingTildeInPath], directory, FIREFOX_BOOKMARKS_FILE_NAME] retain];
				break;
			}
		}
		
		if (!fox8OrLessBookmarkPath) fox8OrLessBookmarkPath = [FIREFOX_8_OR_LESS_BOOKMARKS_PATH retain];
	}
	
	return fox8OrLessBookmarkPath;
}

- (NSString *)fox9BookmarkPath
{
	if (!fox9BookmarkPath){
		NSArray     *dirContents = [[NSFileManager defaultManager] directoryContentsAtPath:[FIREFOX_9_BOOKMARKS_PATH stringByExpandingTildeInPath]];
		
		if(nil != dirContents){
			NSEnumerator *enumerator = [dirContents objectEnumerator];
			NSString    *directory;
			
			while(directory = [enumerator nextObject]){
				BOOL found = (([directory rangeOfString:@"default."].location != NSNotFound) || /* Fox 0.9 up to but not including 1.0 */
							  ([directory rangeOfString:@".default"].location != NSNotFound));
				if(found){
					fox9BookmarkPath = [[NSString stringWithFormat:@"%@/%@/%@",[FIREFOX_9_BOOKMARKS_PATH stringByExpandingTildeInPath], directory, FIREFOX_BOOKMARKS_FILE_NAME] retain];
					break;
				}
			}
		}
	}
	
    return fox9BookmarkPath;
}

- (NSString *)bookmarkPath
{
	return(fox9 ? [self fox9BookmarkPath] : [self fox8OrLessBookmarkPath]);
}

@end