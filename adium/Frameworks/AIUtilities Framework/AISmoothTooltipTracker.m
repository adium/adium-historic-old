//
//  AISmoothTooltipTracker.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AISmoothTooltipTracker.h"

#define TOOL_TIP_CHECK_INTERVAL				45.0	//Check for mouse X times a second
#define TOOL_TIP_DELAY						35.0	//Number of check intervals of no movement before a tip is displayed

@interface AISmoothTooltipTracker (PRIVATE)
- (AISmoothTooltipTracker *)initForView:(NSView *)inView withDelegate:(id)inDelegate;
- (void)_startTrackingMouse;
- (void)_stopTrackingMouse;
@end

@implementation AISmoothTooltipTracker

+ (AISmoothTooltipTracker *)smoothTooltipTrackerForView:(NSView *)inView withDelegate:(id)inDelegate
{
	return([[[self alloc] initForView:inView withDelegate:inDelegate] autorelease]);
}

- (AISmoothTooltipTracker *)initForView:(NSView *)inView withDelegate:(id)inDelegate
{
	[super init];
	
	view = inView;
	delegate = inDelegate;

	
	
	//Reset cursor tracking when the view's frame changes
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetCursorTracking)
												 name:NSViewFrameDidChangeNotification
											   object:view];
	
	
	
	return(self);
}

- (void)dealloc
{
	
	[super dealloc];
}




//Cursor Rects ---------------------------------------------------------------------------------------------------------
#pragma mark Cursor Rects
//Install the cursor rect for our enclosing scrollview
- (void)installCursorRect
{
	if(tooltipTrackingTag == -1){
		NSRect	 		trackingRect;
		BOOL			mouseInside;
		
		//Add a new tracking rect
		trackingRect = [view frame];
		mouseInside = NSPointInRect([[view window] convertScreenToBase:[NSEvent mouseLocation]], trackingRect);
		tooltipTrackingTag = [view addTrackingRect:trackingRect owner:self userData:nil assumeInside:mouseInside];
		
		//If the mouse is already inside, begin tracking the mouse immediately
		if(mouseInside) [self _startTrackingMouse];
	}
}

//Remove the cursor rect
- (void)removeCursorRect
{
	if(tooltipTrackingTag != -1){
		[view removeTrackingRect:tooltipTrackingTag];
		tooltipTrackingTag = -1;
		[self _stopTrackingMouse];
	}
}

//Reset cursor tracking
- (void)resetCursorTracking
{
	[self removeCursorRect];
	[self installCursorRect];
}


//Tooltips (Cursor movement) -------------------------------------------------------------------------------------------
//We use a timer to poll the location of the mouse.  Why do this instead of using mouseMoved: events?
// - Webkit eats mouseMoved: events, even when those events occur elsewhere on the screen
// - mouseMoved: events do not work when Adium is in the background
#pragma mark Tooltips (Cursor movement)
//Mouse entered our list, begin tracking it's movement
- (void)mouseEntered:(NSEvent *)theEvent
{
	[self _startTrackingMouse];
}

//Mouse left our list, cease tracking
- (void)mouseExited:(NSEvent *)theEvent
{
	[self _stopTrackingMouse];
}

//Start tracking mouse movement
- (void)_startTrackingMouse
{
	if(!tooltipMouseLocationTimer){
		tooltipCount = 0;
		tooltipMouseLocationTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/TOOL_TIP_CHECK_INTERVAL)
																	  target:self
																	selector:@selector(mouseMovementTimer:)
																	userInfo:nil
																	 repeats:YES] retain];
	}
}

//Stop tracking mouse movement
- (void)_stopTrackingMouse
{
	//Hide tooltip
	[delegate hideTooltip];

	//Invalidate tracking
	[tooltipMouseLocationTimer invalidate];
	[tooltipMouseLocationTimer release];
	tooltipMouseLocationTimer = nil;
	tooltipCount = 0;
	lastMouseLocation = NSMakePoint(0,0);
}

//Time to poll mouse location
- (void)mouseMovementTimer:(NSTimer *)inTimer
{
	NSPoint mouseLocation = [NSEvent mouseLocation];

	if(NSPointInRect(mouseLocation, [view frame])){
		//tooltipCount is used for delaying the appearence of tooltips.  We reset it to 0 when the mouse moves.  When
		//the mouse is left still tooltipCount will eventually grow greater than TOOL_TIP_DELAY, and we will begin
		//displaying the tooltips
		if(tooltipCount > TOOL_TIP_DELAY){
			if(!NSEqualPoints(tooltipLocation, mouseLocation)){
				[delegate showTooltipAtPoint:mouseLocation];
				tooltipLocation = mouseLocation;
			}
			
		}else{
			if(!NSEqualPoints(mouseLocation,lastMouseLocation)){
				lastMouseLocation = mouseLocation;
				tooltipCount = 0; //reset tooltipCount to 0 since the mouse has moved
			} else {
				tooltipCount++;
			}
		}
	}else{
		//Failsafe for if the mouse is outside the window yet the timer is still firing
		[self _stopTrackingMouse];
	}
}


@end






//Tooltips (Cursor rects) ----------------------------------------------------------------------------------------------
//We install a cursor rect for our enclosing scrollview.  When the cursor is within this rect, we track it's
//movement.  If our scrollview changes, or the size of our scrollview changes, we must re-install our rect.
//Our enclosing scrollview is going to be changed, stop all cursor tracking
//- (void)view:(NSView *)inView willMoveToSuperview:(NSView *)newSuperview
//{	
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
//	[self _removeCursorRect];
//}
//
////We've been moved to a new scrollview, resume cursor tracking
////View is being added to a new superview
//- (void)view:(NSView *)inView didMoveToSuperview:(NSView *)newSuperview
//{	
//    if(newSuperview && [newSuperview superview]){
//        [[NSNotificationCenter defaultCenter] addObserver:self
//												 selector:@selector(frameDidChange:)
//													 name:NSViewFrameDidChangeNotification 
//												   object:[newSuperview superview]];
//	}
//	
//	[self performSelector:@selector(_installCursorRect) withObject:nil afterDelay:0.0001];
//}
//
//- (void)view:(NSView *)inView didMoveToWindow:(NSWindow *)window
//{
//	[self _configureTransparencyAndShadows];
//	
//	windowHidesOnDeactivate = [window hidesOnDeactivate];
//}
	
//- (void)window:(NSWindow *)inWindow didBecomeMain:(NSNotification *)notification
//{	
//	[self _startTrackingMouse];
//}
//
//- (void)window:(NSWindow *)inWindow didResignMain:(NSNotification *)notification
//{	
//	[self _stopTrackingMouse];
//}

