//
//  SHSafariBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Sun May 16 2004.

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHSafariBookmarksImporter : NSObject <SHBookmarkImporter> {
    id               owner;
    NSDate          *lastModDate;
}

@end
