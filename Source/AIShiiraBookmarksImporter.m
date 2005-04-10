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
#import <AIHyperlinks/SHMarkedHyperlink.h>
#import <AIUtilities/AIFileManagerAdditions.h>

#define SHIIRA_BOOKMARKS_PATH	@"~/Library/Shiira/Bookmarks.plist"
#define SHIIRA_HISTORY_PATH		@"~/Library/Shiira/History.plist"
#define SHIIRA_DICT_CHILD		@"Children"
#define SHIIRA_DICT_URLSTRING	@"URLString"
#define SHIIRA_DICT_TITLE		@"Title"

@interface AIShiiraBookmarksImporter (PRIVATE)
- (SHMarkedHyperlink *)hyperlinkForShiiraBookmark:(NSDictionary *)inDict;
@end

@implementation AIShiiraBookmarksImporter

+ (NSString *)bookmarksPath
{
	return [[NSFileManager defaultManager] pathIfNotDirectory:[SHIIRA_BOOKMARKS_PATH stringByExpandingTildeInPath]];
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

+ (void)load
{
	AIBOOKMARKSIMPORTER_REGISTERWITHCONTROLLER();
}

//Parse the Shiira bookmarks file
- (NSArray *)drillPropertyList:(id)inObject
{
	NSMutableArray	*array = nil;

	if([inObject isKindOfClass:[NSArray class]]) {
		array = [NSMutableArray arrayWithCapacity:[inObject count]];
		NSEnumerator *enumerator = [(NSArray *)inObject objectEnumerator];
		NSDictionary *linkDict;
		
		while(linkDict = [enumerator nextObject]) {
			NSArray *children = [linkDict objectForKey:SHIIRA_DICT_CHILD];
			if(!children) {
				//We found a link
				SHMarkedHyperlink	*menuLink = [self hyperlinkForShiiraBookmark:linkDict];
				if(menuLink) [array addObject:menuLink];
			} else {
				//We found an array of links
				NSDictionary	*menuDict = [[self class] menuDictWithTitle:[linkDict objectForKey:SHIIRA_DICT_TITLE]
																  menuItems:[self drillPropertyList:[linkDict objectForKey:SHIIRA_DICT_CHILD]]];
				if(menuDict) [array addObject:menuDict];
			}
		}
	} else {
		//provide an empty array
		array = [NSArray array];
	}
	
	return array;
}

//Menu Item
- (SHMarkedHyperlink *)hyperlinkForShiiraBookmark:(NSDictionary *)inDict
{
	NSString	*title = [inDict objectForKey:SHIIRA_DICT_TITLE];
	NSString	*url   = [inDict objectForKey:SHIIRA_DICT_URLSTRING];
	return [[self class] hyperlinkForTitle:title URL:url];
}

@end
