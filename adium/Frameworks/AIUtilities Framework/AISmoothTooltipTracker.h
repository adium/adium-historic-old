//
//  AISmoothTooltipTracker.h
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AISmoothTooltipTracker : NSObject {
	NSView				*view;		//View we are tracking tooltips for
	id					delegate;	//Our delegate

	NSPoint				lastMouseLocation;				//Last known location of the mouse, used for movement tracking
	NSTimer				*tooltipMouseLocationTimer;		//Checks for mouse movement
	NSPoint				tooltipLocation;				//Last tooltip location we told our delegate about
    NSTrackingRectTag	tooltipTrackingTag;				//Tag for our tracking rect
    int 				tooltipCount;					//Used to determine how long before a tooltip appears
}

- (void)installCursorRect;
- (void)removeCursorRect;
- (void)resetCursorTracking;

@end

//Delegate handles displaying the tooltips, we handle all the tracking
@interface NSObject (AISmoothTooltipTrackerDelegate)
- (void)showTooltipAtPoint:(NSPoint)screenPoint;
- (void)hideTooltip;
@end