//
//  SHBookmarksImporterPlugin.h
//  Adium
//
//  Created by Stephen Holt on Wed May 19 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#define SH_BOOKMARK_DICT_TITLE      @"Title"
#define SH_BOOKMARK_DICT_CONTENT    @"Content"

@protocol SHBookmarkImporter <NSObject>
+ (id)newInstanceOfImporter;
- (NSArray *)availableBookmarks;	//All available bookmarks
- (BOOL)bookmarksUpdated; 			//YES if bookmarks have changed since last call to availableBookmarks
@end

@interface SHBookmarksImporterPlugin : AIPlugin {	
	NSMenuItem              *bookmarkRootMenuItem;
	NSMenuItem              *bookmarkRootContextualMenuItem;
        
	NSToolbarItem			*toolbarItem;
	NSMutableArray			*toolbarItemArray;
	
	id <SHBookmarkImporter>  importer;
	BOOL                     updatingMenu;
}

@end
