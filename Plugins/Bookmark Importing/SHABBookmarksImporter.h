//
//  SHABBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHABBookmarksImporter : NSObject <SHBookmarksImporter>{
    id               owner;
    NSDate          *lastModDate;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject;
-(BOOL)bookmarksExist;
-(BOOL)bookmarksUpdated;

@end
