//
//  SHSafariBookmarksImporter.h
//  Adium
//
//  Created by Stephen Holt on Sun May 16 2004.

#import "SHLinkEditorWindowController.h"

@interface SHSafariBookmarksImporter : NSObject {
    id               owner;
    NSMenu          *safariBookmarksMenu;
    NSMenu          *safariBookmarksSupermenu;
}

-(NSMenu *)parseSafariBookmarksForOwner:(id)inObject;

@end
