//
//  SHOmniWebBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHOmniWebBookmarksImporter : NSObject <SHBookmarksImporter> {
    id       owner;
    NSDate  *lastModDate;
    BOOL     useOW5;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject;
-(NSString *)menuTitle;
-(BOOL)bookmarksExist;
-(BOOL)bookmarksUpdated;
@end