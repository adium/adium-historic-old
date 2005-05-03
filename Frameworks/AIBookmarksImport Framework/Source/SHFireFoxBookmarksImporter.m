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
#import <AIUtilities/AIFileManagerAdditions.h>

#define FIREFOX_8_OR_LESS_BOOKMARKS_PATH  @"~/Library/Phoenix/Profiles/default"
#define FIREFOX_9_BOOKMARKS_PATH @"~/Library/Application Support/Firefox/Profiles"
#define FIREFOX_BOOKMARKS_FILE_NAME @"bookmarks.html"

@interface SHFireFoxBookmarksImporter(PRIVATE)
+ (NSString *)fox8OrLessBookmarksPath;
+ (NSString *)fox9BookmarksPath;
@end

@implementation SHFireFoxBookmarksImporter

+ (NSString *)browserName
{
	return @"Firefox";
}
+ (NSString *)browserSignature
{
	return @"MOZB";
}
+ (NSString *)browserBundleIdentifier
{
	return @"org.mozilla.firefox";
}

+ (NSString *)bookmarksPath
{
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *path = [mgr pathIfNotDirectory:[self fox9BookmarksPath]];
	if(!path) path = [mgr pathIfNotDirectory:[self fox8OrLessBookmarksPath]];
	return path;
}

#pragma mark -

- (NSArray *)availableBookmarks
{
	NSString		*path = [[self class] bookmarksPath];
#warning this uses the ephemeral C string encoding. it should use an explicit encoding.
    NSString		*bookmarkString = [NSString stringWithContentsOfFile:path];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:path
																		 traverseLink:YES];
	
    [lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];

    return [SHMozillaCommonParser parseBookmarksfromString:bookmarkString];
}

#pragma mark Private methods

+ (NSString *)fox8OrLessBookmarksPath
{
	NSString *fox8OrLessBookmarksPath = FIREFOX_8_OR_LESS_BOOKMARKS_PATH;

	NSEnumerator *enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:[FIREFOX_8_OR_LESS_BOOKMARKS_PATH stringByExpandingTildeInPath]] objectEnumerator];
	NSString    *directory;

	while((directory = [enumerator nextObject])){
		NSRange found = [directory rangeOfString:@".slt"];
		if(found.location != NSNotFound){
			fox8OrLessBookmarksPath = [NSString stringWithFormat:@"%@/%@/%@",[FIREFOX_8_OR_LESS_BOOKMARKS_PATH stringByExpandingTildeInPath], directory, FIREFOX_BOOKMARKS_FILE_NAME];
			break;
		}
	}

	return fox8OrLessBookmarksPath;
}

+ (NSString *)fox9BookmarksPath
{
	NSString *fox9BookmarksPath = nil;

	NSArray     *dirContents = [[NSFileManager defaultManager] directoryContentsAtPath:[FIREFOX_9_BOOKMARKS_PATH stringByExpandingTildeInPath]];

	if(dirContents) {
		NSEnumerator *enumerator = [dirContents objectEnumerator];
		NSString    *directory;

		while((directory = [enumerator nextObject])){
			BOOL found = (([directory rangeOfString:@"default."].location != NSNotFound) || /* Fox 0.9 up to but not including 1.0 */
						  ([directory rangeOfString:@".default"].location != NSNotFound));
			if(found) {
				fox9BookmarksPath = [NSString stringWithFormat:@"%@/%@/%@",[FIREFOX_9_BOOKMARKS_PATH stringByExpandingTildeInPath], directory, FIREFOX_BOOKMARKS_FILE_NAME];
				break;
			}
		}
	}

	return fox9BookmarksPath;
}

@end
