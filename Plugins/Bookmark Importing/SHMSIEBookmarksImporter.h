//
//  SHMSIEBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHMSIEBookmarksImporter : NSObject <SHBookmarksImporter> {
    id       owner;
    NSDate  *lastModDate;
}

@end
