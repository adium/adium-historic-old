//
//  AILogViewerWindowController.h
//  Adium
//
//  Created by Adam Iser on Sat Apr 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium, AIAlternatingRowOutlineView;

@interface AILogViewerWindowController : NSWindowController {
    IBOutlet	AIAlternatingRowOutlineView	*outlineView_contacts;
    IBOutlet	NSTableView			*tableView_results;
    IBOutlet	NSTextView			*textView_content;

    AIAdium		*owner;

    NSMutableArray	*availableLogArray;
    NSMutableArray	*selectedLogArray;
}

+ (id)logViewerWindowControllerWithOwner:(id)inOwner;
- (IBAction)closeWindow:(id)sender;

@end
