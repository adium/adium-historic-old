//
//  SHCaminoBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Thu May 20 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHCaminoBookmarksImporter : NSObject <SHBookmarkImporter> {
    id       owner;
    NSDate  *lastModDate;
}
@end
