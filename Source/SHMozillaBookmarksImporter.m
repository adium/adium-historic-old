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
#import <AIUtilities/AIFileManagerAdditions.h>

#define MOZILLA_BOOKMARKS_PATH  @"~/Library/Mozilla/Profiles/default"
#define MOZILLA_BOOKMARKS_FILE_NAME @"bookmarks.html"

@class SHMozillaCommonParser;

@implementation SHMozillaBookmarksImporter

+ (NSString *)bookmarksPath
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

+ (NSString *)browserName
{
	return @"Mozilla";
}
+ (NSString *)browserSignature
{
	return @"MOZZ";
}
+ (NSString *)browserBundleIdentifier
{
	return @"org.mozilla.mozilla";
}

#pragma mark -

+ (void)load
{
	AIBOOKMARKSIMPORTER_REGISTERWITHCONTROLLER();
}

- (NSArray *)availableBookmarks
{
	NSString		*bookmarksPath = [[self class] bookmarksPath];
    NSString		*bookmarkString = [NSString stringWithContentsOfFile:bookmarksPath];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarksPath
																		 traverseLink:YES];
    [lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
    
    return [SHMozillaCommonParser parseBookmarksfromString:bookmarkString];
}

@end
