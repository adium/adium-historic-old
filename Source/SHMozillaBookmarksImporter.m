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

#import "SHMozillaBookmarksImporter.h"
#import "SHMozillaCommonParser.h"

#define MOZILLA_BOOKMARKS_PATH  @"~/Library/Mozilla/Profiles/default"
#define MOZILLA_BOOKMARKS_FILE_NAME @"bookmarks.html"

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

- (id)init
{
	[super init];
	
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
    NSString		*bookmarkString = [NSString stringWithContentsOfFile:[self bookmarkPath]];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[self bookmarkPath]
																		 traverseLink:YES];
    [lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
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
