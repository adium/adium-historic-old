//
//  AILinkTracking.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 20 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIFlexibleLink;

@interface AILinkTrackingController : NSObject {
    NSView			*controlView;			//The view we're tracking links in
    NSMutableArray		*linkArray;			//Array of active flexible links

    AIFlexibleLink		*hoveredLink;			//The link currently being hovered
    NSString			*hoveredString;	
    BOOL			mouseOverLink;			//Yes if the cursor is over one of our links
//    id				oldFirstResponder;

    //The text system of the view we're tracking links for
    NSTextStorage 		*textStorage;
    NSLayoutManager 		*layoutManager;
    NSTextContainer 		*textContainer;
}

+ (id)linkTrackingControllerForView:(NSView *)inControlView withTextStorage:(NSTextStorage *)inTextStorage layoutManager:(NSLayoutManager *)inLayoutManager textContainer:(NSTextContainer *)inTextContainer;
+ (id)linkTrackingControllerForTextView:(NSTextView *)inTextView;
- (void)trackLinksInRect:(NSRect)visibleRect withOffset:(NSSize)offset;
- (BOOL)handleMouseDown:(NSEvent *)theEvent withOffset:(NSSize)offset;

@end
