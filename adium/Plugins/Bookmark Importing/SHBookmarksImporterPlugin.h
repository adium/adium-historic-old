//
//  SHBookmarksImporterPlugin.h
//  Adium
//
//  Created by Stephen Holt on Wed May 19 2004.


// protocol bookmark importer classes must impliment
@protocol SHBookmarkImporter
-(NSMenu *)parseBookmarksForOwner:(id)owner;    // returns a NSMenu with the full hierarchy
-(NSString *)menuTitle;                         // title for the menu item
-(BOOL)bookmarksExist;                          // if the bookmarks file exists
-(BOOL)bookmarksUpdated;                        // if the bookmarks file has been updated
@end                                            //   since the last time parseBookmarksForOwner: has been called

@interface SHBookmarksImporterPlugin : AIPlugin {
    NSMutableArray  *importerArray;
}

@end
