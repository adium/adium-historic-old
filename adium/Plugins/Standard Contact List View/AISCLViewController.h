//
//  AISCLViewController.h
//  Adium
//
//  Created by Adam Iser on Sat Apr 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium, AIListGroup, AISCLOutlineView;

@interface AISCLViewController : NSObject {
    AIAdium		*owner;
    
    AIListGroup		*contactList;
    AISCLOutlineView	*contactListView;

    NSTrackingRectTag	tooltipTrackingTag;
    BOOL		trackingMouseMovedEvents;
}

+ (AISCLViewController *)contactListViewControllerWithOwner:(id)inOwner;
- (IBAction)performDefaultActionOnSelectedContact:(id)sender;
- (NSView *)contactListView;
- (void)view:(NSView *)inView didMoveToSuperview:(NSView *)inSuperview;
- (void)closeView;

@end
