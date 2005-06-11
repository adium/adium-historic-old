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

#import "SHCaminoBookmarksImporter.h"

#define CAMINO_BOOKMARKS_PATH   @"~/Library/Application Support/Camino/bookmarks.plist"
#define CAMINO_DICT_CHILD_KEY   @"Children"
#define CAMINO_DICT_FOLDER_KEY  @"FolderType"
#define CAMINO_DICT_TITLE_KEY   @"Title"
#define CAMINO_DICT_URL_KEY     @"URL"

@interface SHCaminoBookmarksImporter(PRIVATE)
- (NSArray *)drillPropertyList:(id)inObject;
@end

@implementation SHCaminoBookmarksImporter

+ (NSString *)bookmarksPath
{
	NSString	*bookmarksPath = [CAMINO_BOOKMARKS_PATH stringByExpandingTildeInPath];
	BOOL		isDir =	NO;
	BOOL		exists = ([[NSFileManager defaultManager] fileExistsAtPath:bookmarksPath isDirectory:&isDir] && !isDir);
	
	if (!exists) bookmarksPath = nil;
	
	return bookmarksPath;
}

+ (NSString *)browserName
{
	return @"Camino";
}
+ (NSString *)browserSignature
{
	return @"CHIM";
}
+ (NSString *)browserBundleIdentifier
{
	return @"org.mozilla.navigator";
}

#pragma mark -

- (NSArray *)availableBookmarks
{
	NSString        *bookmarksPath = [[self class] bookmarksPath];
	NSDictionary    *bookmarksDict = [NSDictionary dictionaryWithContentsOfFile:bookmarksPath];

	NSDictionary    *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarksPath traverseLink:YES];
	[lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];

	return [self drillPropertyList:[bookmarksDict objectForKey:CAMINO_DICT_CHILD_KEY]];
}

- (BOOL)bookmarksHaveChanged
{
	NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[[self class] bookmarksPath] traverseLink:YES];
	NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];

	return ![modDate isEqualToDate:lastModDate];
}

- (NSArray *)drillPropertyList:(id)inObject
{
	NSMutableArray  *array = [NSMutableArray array];

	if([inObject isKindOfClass:[NSArray class]]){
		NSEnumerator    *enumerator = [(NSArray *)inObject objectEnumerator];
		NSDictionary    *linkDict;

		while((linkDict = [enumerator nextObject])){
			NSDictionary *dict = nil;

			NSString *title = [linkDict objectForKey:CAMINO_DICT_TITLE_KEY];

			if([linkDict objectForKey:CAMINO_DICT_FOLDER_KEY] == nil) {
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
					title, ADIUM_BOOKMARK_DICT_TITLE,
					[NSURL URLWithString:[linkDict objectForKey:CAMINO_DICT_URL_KEY]], ADIUM_BOOKMARK_DICT_CONTENT,
					nil];
			} else {
				NSArray 		*children = [linkDict objectForKey:CAMINO_DICT_CHILD_KEY];
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
					title, ADIUM_BOOKMARK_DICT_TITLE,
					[self drillPropertyList:(children ? children : [NSArray array])], ADIUM_BOOKMARK_DICT_CONTENT,
					nil];
            }

			if(dict) [array addObject:dict];
        }
    }

    return array;
}

@end
