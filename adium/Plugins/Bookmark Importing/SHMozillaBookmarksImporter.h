//
//  SHMozillaBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Tue May 25 2004.

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHMozillaBookmarksImporter : NSObject <SHBookmarkImporter> {
    id       owner;
    NSDate  *lastModDate;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject;
-(NSString *)menuTitle;
-(BOOL)bookmarksExist;
-(BOOL)bookmarksUpdated;

@end
