//
//  SHCaminoBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Thu May 20 2004.

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHCaminoBookmarksImporter : NSObject <SHBookmarkImporter> {
    id       owner;
    NSMenu  *bookmarksMenu;
    NSMenu  *bookmarksSupermenu;
    NSDate  *lastModDate;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject;
-(NSString *)menuTitle;
-(BOOL)bookmarksExist;

@end
