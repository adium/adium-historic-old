//
//  AIRolloverButton.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 12/2/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AIRolloverButton : NSButton {
	id					delegate;
	NSTrackingRectTag	trackingTag;	
}

//Configuration
- (void)setDelegate:(id)inDelegate;
- (id)delegate;
@end

@interface NSObject (AIRolloverButtonDelegate)
- (void)rolloverButton:(AIRolloverButton *)button mouseChangedToInsideButton:(BOOL)isInside;
@end