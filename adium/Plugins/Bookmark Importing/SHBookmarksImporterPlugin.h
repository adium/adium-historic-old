//
//  SHBookmarksImporterPlugin.h
//  Adium
//
//  Created by Stephen Holt on Wed May 19 2004.

@protocol SHBookmarkImporter <NSObject>
+ (id)newInstanceOfImporter;
- (NSArray *)availableBookmarks;	//All available bookmarks
- (BOOL)bookmarksUpdated; 			//YES if bookmarks have changed since last call to availableBookmarks
@end

@interface SHBookmarksImporterPlugin : AIPlugin {	
	NSMenuItem              *bookmarkRootMenuItem;
	NSMenuItem              *bookmarkRootContextualMenuItem;	

	id <SHBookmarkImporter>  importer;
	BOOL                     updatingMenu;
}

@end
