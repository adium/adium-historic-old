//
//  SHSafariBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Sun May 16 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHSafariBookmarksImporter : NSObject <SHBookmarkImporter> {
    id               owner;
    NSDate          *lastModDate;
}

@end
