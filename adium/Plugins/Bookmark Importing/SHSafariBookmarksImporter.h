//
//  SHSafariBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Sun May 16 2004.

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHSafariBookmarksImporter : NSObject <SHBookmarkImporter> {
    id               owner;
//    NSMenu          *bookmarksMenu;
//    NSMenu          *bookmarksSupermenu;
    NSDate          *lastModDate;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject;
-(NSString *)menuTitle;
-(BOOL)bookmarksExist;
-(BOOL)bookmarksUpdated;

@end
