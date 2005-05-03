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

#import "SHSafariBookmarksImporter.h"
#import <AIUtilities/AIFileManagerAdditions.h>

#define SAFARI_BOOKMARKS_PATH	@"~/Library/Safari/Bookmarks.plist"
#define SAFARI_HISTORY_PATH		@"~/Library/Safari/History.plist"
#define SAFARI_DICT_CHILD		@"Children"
#define SAFARI_DICT_URIDICT		@"URIDictionary"
#define SAFARI_DICT_URLSTRING	@"URLString"
#define SAFARI_DICT_TYPE_KEY	@"WebBookmarkType"
#define SAFARI_DICT_TYPE_LIST	@"WebBookmarkTypeList"
#define SAFARI_DICT_TYPE_LEAF	@"WebBookmarkTypeLeaf"
#define SAFARI_DICT_TITLE		@"Title"
#define SAFARI_DICT_URI_TITLE	@"title"

@interface SHSafariBookmarksImporter (PRIVATE)
- (NSArray *)drillPropertyList:(id)inObject;
@end

@implementation SHSafariBookmarksImporter

+ (NSString *)bookmarksPath
{
	return [[NSFileManager defaultManager] pathIfNotDirectory:[SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath]];
}

+ (NSString *)browserName
{
	return @"Safari";
}
+ (NSString *)browserSignature
{
	return @"sfri";
}
+ (NSString *)browserBundleIdentifier
{
	return @"com.apple.Safari";
}

#pragma mark -

//Return an array of the available bookmarks
- (NSArray *)availableBookmarks
{
	NSString	*bookmarksPath = [[self class] bookmarksPath];

	//Open the bookmarks
	NSDictionary *bookmarksDict = [NSDictionary dictionaryWithContentsOfFile:bookmarksPath];
	if(!bookmarksDict) return nil;

	//Remember when they were last modified
	NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarksPath traverseLink:YES];
	[lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];

	//Process them
	return [self drillPropertyList:[bookmarksDict objectForKey:SAFARI_DICT_CHILD]];
}

//Parse the Safari bookmarks file
- (NSArray *)drillPropertyList:(id)inObject
{
	NSMutableArray	*array = nil;

	if(inObject && [inObject isKindOfClass:[NSArray class]]) {
		array = [NSMutableArray arrayWithCapacity:[inObject count]];
		NSEnumerator *enumerator = [(NSArray *)inObject objectEnumerator];
		NSDictionary *linkDict;
		
		while((linkDict = [enumerator nextObject])){
			NSString *type = [linkDict objectForKey:SAFARI_DICT_TYPE_KEY];
			NSDictionary *dict = nil;

			if([type isEqualToString:SAFARI_DICT_TYPE_LEAF]) {
				//We found a link
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
					[[linkDict objectForKey:SAFARI_DICT_URIDICT] objectForKey:SAFARI_DICT_URI_TITLE], ADIUM_BOOKMARK_DICT_TITLE,
					[NSURL URLWithString:[linkDict objectForKey:SAFARI_DICT_URLSTRING]], ADIUM_BOOKMARK_DICT_CONTENT,
					nil];
			} else if([type isEqualToString:SAFARI_DICT_TYPE_LIST]) {
				//We found a group
				dict = [NSDictionary dictionaryWithObjectsAndKeys:
					[linkDict objectForKey:SAFARI_DICT_TITLE], ADIUM_BOOKMARK_DICT_TITLE,
					[self drillPropertyList:[linkDict objectForKey:SAFARI_DICT_CHILD]], ADIUM_BOOKMARK_DICT_CONTENT,
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
