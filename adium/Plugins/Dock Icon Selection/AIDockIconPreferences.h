//
//  AIDockIconPreferences.h
//  Adium
//
//  Created by Adam Iser on Sat May 24 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AIDockIconPreferences : NSObject {
    AIAdium				*owner;

    IBOutlet	NSView			*view_prefView;
    IBOutlet	NSTableView		*tableView_icons;
//    IBOutlet	NSImageView		*imageView_preview;
    IBOutlet	NSTextField		*textField_title;
//    IBOutlet	NSTextField		*textField_description;
    IBOutlet	NSTextField		*textField_creator;
//    IBOutlet	NSTextField		*textField_link;

    IBOutlet	NSMatrix		*matrix_iconPreview;

    NSTimer			*animationTimer;
    int 			cycle;
    
    
    NSMutableArray		*iconArray;
    NSDictionary		*selectedIcon;

    NSMutableArray		*previewStateArray;
}

+ (AIDockIconPreferences *)dockIconPreferencesWithOwner:(id)inOwner;

@end
