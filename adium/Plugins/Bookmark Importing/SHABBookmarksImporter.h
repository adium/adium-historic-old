//
//  SHABBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Mon May 31 2004.

#import <AddressBook/AddressBook.h>
#import "SHBookmarksImporterPlugin.h"

@protocol SHBookmarksImporter;

@interface SHABBookmarksImporter : NSObject <SHBookmarksImporter>{
    id               owner;
    NSDate          *lastModDate;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject;
-(NSString *)menuTitle;
-(BOOL)bookmarksExist;
-(BOOL)bookmarksUpdated;

@end
