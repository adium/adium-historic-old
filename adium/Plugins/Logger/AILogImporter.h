//
//  AILogImporter.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium;

@interface AILogImporter : NSWindowController {
    AIAdium		*owner;

    IBOutlet	NSTextField		*textField_Goal;
    IBOutlet	NSTextField		*textField_Progress;
    IBOutlet	NSProgressIndicator	*progress_working;

    //Adium 1.6 import
    NSMutableArray	*sourcePathArray;
    NSMutableArray	*destPathArray;
    NSEnumerator	*sourcePathEnumerator;
    NSEnumerator	*destPathEnumerator;
}

+ (id)logImporterWithOwner:(id)inOwner;
- (IBAction)closeWindow:(id)sender;

- (void)importAdium1xLogs;

@end
