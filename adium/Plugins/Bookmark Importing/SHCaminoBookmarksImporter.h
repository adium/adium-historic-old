//
//  SHCaminoBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Thu May 20 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SHCaminoBookmarksImporter : NSObject <SHBookmarkImporter> {
    id       owner;
    NSMenu  *bookmarksMenu;
    NSMenu  *bookmarksSupermenu;
}

-(NSMenu *)parseBookmarksForOwner:(id)inObject;
-(NSString *)menuTitle;
-(BOOL)bookmarksExist;

@end
