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

#import "SHMSIEBookmarksImporter.h"
#import "SHMozillaCommonParser.h"
#import <AIUtilities/AIFileManagerAdditions.h>

#define MSIE_BOOKMARKS_PATH  @"~/Library/Preferences/Explorer/Favorites.html"

@class SHMozillaCommonParser;

@implementation SHMSIEBookmarksImporter

+ (NSString *)bookmarksPath
{
	return [[NSFileManager defaultManager] pathIfNotDirectory:MSIE_BOOKMARKS_PATH];
}

+ (NSString *)browserName
{
	return @"Internet Explorer";
}
+ (NSString *)browserSignature
{
	return @"MSIE";
}
/*
+ (NSString *)browserBundleIdentifier
{
	return nil;
}
*/

#pragma mark -

+ (void)load
{
	AIBOOKMARKSIMPORTER_REGISTERWITHCONTROLLER();
}

- (NSArray *)availableBookmarks
{
    NSString    *bookmarkPath = [MSIE_BOOKMARKS_PATH stringByExpandingTildeInPath];
    NSString    *bookmarkString = [NSString stringWithContentsOfFile:bookmarkPath];
    
    NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarkPath traverseLink:YES];
    [lastModDate autorelease]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];

    return [SHMozillaCommonParser parseBookmarksfromString:bookmarkString];
}

@end
