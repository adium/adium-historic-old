//
//  SHMozillaBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Tue May 25 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHMozillaBookmarksImporter : NSObject <SHBookmarkImporter> {
    id       owner;
    NSDate  *lastModDate;
}

@end
