//
//  SHFireFoxBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Sun May 30 2004.

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHFireFoxBookmarksImporter : NSObject <SHBookmarkImporter>{
    id       owner;
    NSDate  *lastModDate;
    BOOL     fox9;
	
	NSString	*fox8OrLessBookmarkPath;
	NSString	*fox9BookmarkPath;
}

@end
