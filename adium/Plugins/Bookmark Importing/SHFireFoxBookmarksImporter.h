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
}

@end
