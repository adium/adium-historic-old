//
//  SHOmniWebBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHOmniWebBookmarksImporter : NSObject <SHBookmarksImporter> {
    id       owner;
    NSDate  *lastModDate;
    BOOL     useOW5;
}

@end