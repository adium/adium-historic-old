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
#import <AIHyperlinks/SHMarkedHyperlink.h>

#define SAFARI_BOOKMARKS_PATH   @"~/Library/Safari/Bookmarks.plist"
#define SAFARI_HISTORY_PATH     @"~/Library/Safari/History.plist"
#define SAFARI_DICT_CHILD       @"Children"
#define SAFARI_DICT_URIDICT     @"URIDictionary"
#define SAFARI_DICT_URLSTRING   @"URLString"
#define SAFARI_DICT_TYPE_KEY    @"WebBookmarkType"
#define SAFARI_DICT_TYPE_LIST   @"WebBookmarkTypeList"
#define SAFARI_DICT_TYPE_LEAF   @"WebBookmarkTypeLeaf"
#define SAFARI_DICT_TITLE       @"Title"
#define SAFARI_DICT_URI_TITLE   @"title"

@interface SHSafariBookmarksImporter(PRIVATE)
- (NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems;
- (SHMarkedHyperlink *)hyperlinkForSafariBookmark:(NSDictionary *)inDict;
- (NSArray *)drillPropertyList:(id)inObject;
@end

@implementation SHSafariBookmarksImporter

DeclareString(safariDictTypeKey)
DeclareString(safariDictTypeLeaf)
DeclareString(safariDictTypeList)
DeclareString(safariDictTitle)
DeclareString(safariDictChild)
DeclareString(safariDictURIDict)
DeclareString(safariDictURITitle)
DeclareString(safariURLString)
DeclareString(bookmarkDictTitle)
DeclareString(bookmarkDictContent)

+ (id)newInstanceOfImporter
{
    return([[[self alloc] init] autorelease]);
}

- (id)init
{
    InitString(safariDictTypeKey,SAFARI_DICT_TYPE_KEY)
    InitString(safariDictTypeLeaf,SAFARI_DICT_TYPE_LEAF)
    InitString(safariDictTypeList,SAFARI_DICT_TYPE_LIST)
    InitString(safariDictTitle,SAFARI_DICT_TITLE)
    InitString(safariDictChild,SAFARI_DICT_CHILD)
    InitString(safariDictURIDict,SAFARI_DICT_URIDICT)
    InitString(safariDictURITitle,SAFARI_DICT_URI_TITLE)
    InitString(safariURLString,SAFARI_DICT_URLSTRING)
        
    InitString(bookmarkDictTitle,SH_BOOKMARK_DICT_TITLE)
    InitString(bookmarkDictContent,SH_BOOKMARK_DICT_CONTENT)
    
    [super init];
    lastModDate = nil;
    return(self);
}

- (void)dealloc
{
	[lastModDate release];
	[super dealloc];
}

//Returns YES if the bookmarks have changed
- (BOOL)bookmarksUpdated
{
    NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:[SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath] traverseLink:YES];
    NSDate *modDate = [fileProps objectForKey:NSFileModificationDate];
    
    return ![modDate isEqualToDate:lastModDate];
}

//Return an array of the available bookmarks
- (NSArray *)availableBookmarks
{
	NSString	*bookmarkPath = [SAFARI_BOOKMARKS_PATH stringByExpandingTildeInPath];
	
	//Open the bookmarks
	NSDictionary *bookmarkDict = [NSDictionary dictionaryWithContentsOfFile:bookmarkPath];
	
	//Remember when they were last modified
	NSDictionary *fileProps = [[NSFileManager defaultManager] fileAttributesAtPath:bookmarkPath traverseLink:YES];
	[lastModDate release]; lastModDate = [[fileProps objectForKey:NSFileModificationDate] retain];
	
	//Process them
	return([self drillPropertyList:[bookmarkDict objectForKey:safariDictChild]]);
}

//Parse the safari bookmark file
- (NSArray *)drillPropertyList:(id)inObject
{
	NSMutableArray	*array = [NSMutableArray array];

	if([inObject isKindOfClass:[NSArray class]]){
        NSEnumerator *enumerator = [(NSArray *)inObject objectEnumerator];
        NSDictionary *linkDict;
		
        while(linkDict = [enumerator nextObject]){
            if([[linkDict objectForKey:safariDictTypeKey] isEqualToString:safariDictTypeLeaf]){
                //We found a link
				SHMarkedHyperlink	*menuLink = [self hyperlinkForSafariBookmark:linkDict];
				if(menuLink) [array addObject:menuLink];
				
			}else if([[linkDict objectForKey:safariDictTypeKey] isEqualToString:safariDictTypeList]){
				//We found an array of links
				NSDictionary	*menuDict = [self menuDictWithTitle:[linkDict objectForKey:safariDictTitle]
														  menuItems:[self drillPropertyList:[linkDict objectForKey:safariDictChild]]];
				if(menuDict) [array addObject:menuDict];
            }
        }
	}
	
	return(array);
}

//Menu
- (NSDictionary *)menuDictWithTitle:(NSString *)inTitle menuItems:(NSArray *)inMenuItems
{
	if(!inTitle || !inMenuItems) return(nil);
	return([NSDictionary dictionaryWithObjectsAndKeys:inTitle, bookmarkDictTitle, inMenuItems, bookmarkDictContent, nil]);
}

//Menu Item
- (SHMarkedHyperlink *)hyperlinkForSafariBookmark:(NSDictionary *)inDict
{
	NSString	*title = [[inDict objectForKey:safariDictURIDict] objectForKey:safariDictURITitle];
	NSString	*url = [inDict objectForKey:safariURLString];
	
	if(!title || !url) return(nil);
	return([[[SHMarkedHyperlink alloc] initWithString:url
								 withValidationStatus:SH_URL_VALID
										 parentString:title
											 andRange:NSMakeRange(0,[title length])] autorelease]);
}

@end
