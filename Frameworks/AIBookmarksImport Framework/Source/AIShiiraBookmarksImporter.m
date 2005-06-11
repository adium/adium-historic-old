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

#import "AIShiiraBookmarksImporter.h"

#define SHIIRA_BOOKMARKS_PATH	@"~/Library/Shiira/Bookmarks.plist"
#define SHIIRA_HISTORY_PATH		@"~/Library/Shiira/History.plist"
#define SHIIRA_DICT_CHILD		@"Children"
#define SHIIRA_DICT_URLSTRING	@"URLString"
#define SHIIRA_DICT_TITLE		@"Title"

@implementation AIShiiraBookmarksImporter

+ (NSString *)bookmarksPath
{
	NSString	*bookmarksPath = [SHIIRA_BOOKMARKS_PATH stringByExpandingTildeInPath];
	BOOL		isDir =	NO;
	BOOL		exists = ([[NSFileManager defaultManager] fileExistsAtPath:bookmarksPath isDirectory:&isDir] && !isDir);

	if (!exists) bookmarksPath = nil;

	return bookmarksPath;
}

+ (NSString *)browserName
{
	return @"Shiira";
}
+ (NSString *)browserSignature
{
	return @"ShiR";
}
+ (NSString *)browserBundleIdentifier
{
	return @"net.hmdt-web.Shiira";
}

#pragma mark -

//Parse the Shiira bookmarks file
- (NSArray *)drillPropertyList:(id)inObject
{
	NSMutableArray	*array = nil;

	if([inObject isKindOfClass:[NSArray class]]) {
		array = [NSMutableArray arrayWithCapacity:[inObject count]];
		NSEnumerator *enumerator = [(NSArray *)inObject objectEnumerator];
		NSDictionary *linkDict;
		
		while((linkDict = [enumerator nextObject])) {
			NSDictionary	*dict = nil;

			NSString *title    = [linkDict objectForKey:SHIIRA_DICT_TITLE];
			NSArray  *children = [linkDict objectForKey:SHIIRA_DICT_CHILD];
			if(!children) {
				//We found a link
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
					title, ADIUM_BOOKMARK_DICT_TITLE,
					[NSURL URLWithString:[linkDict objectForKey:SHIIRA_DICT_URLSTRING]], ADIUM_BOOKMARK_DICT_CONTENT,
					nil];
			} else {
				//We found a group
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
					title, ADIUM_BOOKMARK_DICT_TITLE,
					[self drillPropertyList:[linkDict objectForKey:SHIIRA_DICT_CHILD]], ADIUM_BOOKMARK_DICT_CONTENT,
					nil];
			}

			if(dict) [array addObject:dict];
		}
	} else {
		//provide an empty array
		array = [NSArray array];
	}
	
	return array;
}

@end
