//
//  SHBookmarksImporterPlugin.h
//  Adium
//
//  Created by Stephen Holt on Wed May 19 2004.

#define KEY_LINK_URL        @"URL"
#define KEY_LINK_TITLE      @"Title"

@protocol SHBookmarkImporter
-(NSMenu *)parseBookmarksForOwner:(id)owner;
-(NSString *)menuTitle;
-(BOOL)bookmarksExist;
@end

@interface SHBookmarksImporterPlugin : AIPlugin {
    NSMutableArray  *importerArray;
    NSMenuItem      *bookmarkRootMenuItem;
    NSMenuItem      *bookmarkRootContextualMenuItem;
}

@end
