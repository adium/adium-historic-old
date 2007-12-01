//
//  AISmoothTooltipTracker.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//

//Note: You must setDelegate:nil before deallocing the delegate; NSTimers retain their targets, so
//the AISmoothTooltipTracker instance may remain around even after being released.

#import "AISmoothTooltipTracker.h"
#import "AIDockingWindow.h"

#include <Carbon/Carbon.h>

#define TOOL_TIP_DELAY			35.0 * (1.0 / 45.0)	//Interval of no movement before a tip is displayed

#define MOUSE_LOCATION_KEY		@"MouseLocation"

#define	LOG_TRACKING_INFO		1

@interface AISmoothTooltipTracker (PRIVATE)
- (AISmoothTooltipTracker *)initForView:(NSView *)inView withDelegate:(id)inDelegate;

- (void)installCursorRect;
- (void)removeCursorRect;
- (void)resetCursorTracking;

- (void)_hideTooltip;

- (void)mouseEntered:(NSEvent *)event;
- (void)mouseMoved:(NSEvent *)event;
- (void)mouseExited:(NSEvent *)event;

@end

@implementation AISmoothTooltipTracker

+ (AISmoothTooltipTracker *)smoothTooltipTrackerForView:(NSView *)inView withDelegate:(id <AISmoothTooltipTrackerDelegate>)inDelegate
{
	return [[[self alloc] initForView:inView withDelegate:inDelegate] autorelease];
}

- (AISmoothTooltipTracker *)initForView:(NSView *)inView withDelegate:(id)inDelegate
{
	if ((self = [super init])) {
		view = [inView retain];
		delegate = inDelegate;
		tooltipLocation = NSZeroPoint;

		//Reset cursor tracking when the view's frame changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetCursorTracking)
													 name:NSViewFrameDidChangeNotification
												   object:view];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(resetCursorTracking)
													 name:AIWindowToolbarDidToggleVisibility
												   object:[view window]];

		[self installCursorRect];
	}

	return self;
}

- (void)dealloc
{
#if LOG_TRACKING_INFO
	NSLog(@"[%@ dealloc]",self);
#endif

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[self removeCursorRect];

	[view release]; view = nil;

	[super dealloc];
}

- (void)setDelegate:(id <AISmoothTooltipTrackerDelegate>)inDelegate
{
	if (delegate != inDelegate) {
		delegate = inDelegate;
	}
}

- (NSView *)view
{
	return view;
}

/*
 * @brief This should be called when the view for which we are tracking will be removed from its window without the window closing
 *
 * This allows us to remove our cursor rects (there isn't a notification by which we can do it automatically)
 */
- (void)viewWillBeRemovedFromWindow
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:AIWindowToolbarDidToggleVisibility
												  object:[view window]];

	[self removeCursorRect];
}

/*
 * @brief After calling viewWillBeRemovedFromWindow, call viewWasAddedToWindow to reinitiate tracking
 */
- (void)viewWasAddedToWindow
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetCursorTracking)
												 name:AIWindowToolbarDidToggleVisibility
											   object:[view window]];

	[self installCursorRect];
}

//Cursor Rects ---------------------------------------------------------------------------------------------------------
#pragma mark Cursor Rects
//Install the cursor rect for our enclosing scrollview
- (void)installCursorRect
{
	if (!trackingArea) {
		NSRect	 		trackingRect;
		NSPoint			mouseLocation = [[view window] mouseLocationOutsideOfEventStream];
		BOOL			mouseInside;

		//Add a new tracking rect
		trackingRect = [view frame];
		trackingRect.origin = NSMakePoint(0,0);

		mouseInside = NSPointInRect([view convertPoint:mouseLocation fromView:[[view window] contentView]],
									trackingRect);

		trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect
													options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved) | NSTrackingActiveAlways | NSTrackingInVisibleRect
													  owner:self
												   userInfo:nil];
		[view addTrackingArea:trackingArea];

#if LOG_TRACKING_INFO
		NSLog(@"%s: mouse location: %@; trackingRect: %@; mouseInside: %@", __PRETTY_FUNCTION__, NSStringFromPoint([view convertPoint:[[view window] mouseLocationOutsideOfEventStream] fromView:[[view window] contentView]]), NSStringFromRect(trackingRect), mouseInside ? @"YES" : @"NO");
#endif

		//If the mouse is already inside, NSTrackingArea won't send us a mouse-entered event, so we need to forge one.
		if ([[view window] isVisible] && mouseInside) {
			struct UnsignedWide microsecondsSinceStartup;
			Microseconds(&microsecondsSinceStartup);
			
			NSEvent *event = [NSEvent mouseEventWithType:NSMouseEntered
												location:mouseLocation
										   modifierFlags:0
											   timestamp:UnsignedWideToUInt64(microsecondsSinceStartup)
											windowNumber:[[view window] windowNumber]
												 context:[NSGraphicsContext currentContext]
											 eventNumber:0
											  clickCount:0
												pressure:0.0f];
			[self mouseEntered:event];
		}
	}
}

//Remove the cursor rect
- (void)removeCursorRect
{
#if LOG_TRACKING_INFO
	if (trackingArea) {
		NSLog(@"[%@ removeCursorRect] Remove rect from %@ in %@ : tracking area = %i",self,view,[view window], trackingArea);
	} else {
		NSLog(@"[%@ removeCursorRect] No rect to remove",self);
	}
#endif

	if (trackingArea) {
		[view removeTrackingArea:trackingArea];
		trackingArea = nil;
	}
}

//Reset cursor tracking
- (void)resetCursorTracking
{
#if LOG_TRACKING_INFO
	NSLog(@"[%@ resetCursorTracking]",self);
#endif

	[self removeCursorRect];
	[self installCursorRect];
}


//Tooltips (Cursor movement) -------------------------------------------------------------------------------------------
//We use a timer to poll the location of the mouse.  Why do this instead of using mouseMoved: events?
// - Webkit eats mouseMoved: events, even when those events occur elsewhere on the screen
// - mouseMoved: events do not work when Adium is in the background
#pragma mark Tooltips (Cursor movement)

//Mouse entered our list. Start the delay timer that will show the tooltip.
- (void)mouseEntered:(NSEvent *)theEvent
{
#if LOG_TRACKING_INFO
	NSLog(@"+++ [%@: mouseEntered]", self);
#endif

	NSValue *initialMouseLocation = [NSValue valueWithPoint:[NSEvent mouseLocation]];
	tooltipDelayTimer = [[NSTimer scheduledTimerWithTimeInterval:TOOL_TIP_DELAY
														  target:self
														selector:@selector(delayedShowTooltip:)
														userInfo:[NSMutableDictionary dictionaryWithObject:initialMouseLocation forKey:MOUSE_LOCATION_KEY]
														 repeats:NO] retain];
#if LOG_TRACKING_INFO
	NSLog(@"%s: Scheduled timer %@ for %f seconds from now", __PRETTY_FUNCTION__, tooltipDelayTimer, TOOL_TIP_DELAY);
#endif
}

- (void)mouseMoved:(NSEvent *)event
{
	NSPoint mouseLocation = [event locationInWindow];
	NSWindow *theWindow = [event window];

#warning Assumes that (a) view is the content view of this window and (b) content-relative co-ordinates are the same as frame-relative co-ordinates.
	if ([theWindow isVisible] &&
		NSPointInRect(mouseLocation, [view frame])
	) {
		//Convert our mouse location from window-relative (for comparison) to screen-relative (for real use).
		mouseLocation = [theWindow convertBaseToScreen:mouseLocation];

		//If the tooltip is not yet on screen, and the mouse has moved, then reset the delay.
		if (tooltipDelayTimer) {
			if (!NSEqualPoints(mouseLocation,lastMouseLocation)) {
				lastMouseLocation = mouseLocation;
				[[tooltipDelayTimer userInfo] setObject:[NSValue valueWithPoint:mouseLocation] forKey:MOUSE_LOCATION_KEY];
#if LOG_TRACKING_INFO
				NSLog(@"%s: Postponing timer until %@", __PRETTY_FUNCTION__, [NSDate dateWithTimeIntervalSinceNow:TOOL_TIP_DELAY]);
#endif
				[tooltipDelayTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:TOOL_TIP_DELAY]];
			}

		//If the tooltip is on screen already, and the mouse has moved, then move the tooltip.
		} else {
			if (!NSEqualPoints(tooltipLocation, mouseLocation)) {
#if LOG_TRACKING_INFO
				NSLog(@"%s: Re-showing tooltip at %@", __PRETTY_FUNCTION__, NSStringFromPoint(mouseLocation));
#endif
				//Move the tooltip.
				//XXX This should be a separate method that doesn't re-order-front the tooltip.
				[delegate showTooltipAtPoint:mouseLocation];
				tooltipLocation = mouseLocation;
			}
		}
	} else {
		//If the cursor has left our frame or the window is no longer visible, manually hide the tooltip.
		//This protects us in the cases where we do not receive a mouse exited message; we don't stop tracking
		//because we could reenter the tracking area without receiving a mouseEntered: message.
#if LOG_TRACKING_INFO
		NSLog(@"%@: Mouse moved out; hiding the tooltip.", self);
#endif
		[self _hideTooltip];
	}
}

//Mouse left our list. Hide the tooltip.
- (void)mouseExited:(NSEvent *)theEvent
{
#if LOG_TRACKING_INFO
	NSLog(@"--- [%@: mouseExited]", self);
#endif

	[self _hideTooltip];
}

- (void)delayedShowTooltip:(NSTimer *)timer
{
#if LOG_TRACKING_INFO
	NSLog(@"%s: Timer fired! Showing tooltip at %@", __PRETTY_FUNCTION__, NSStringFromPoint([[[timer userInfo] objectForKey:MOUSE_LOCATION_KEY] pointValue]));
#endif
	[delegate showTooltipAtPoint:[[[timer userInfo] objectForKey:MOUSE_LOCATION_KEY] pointValue]];

	/*
#if LOG_TRACKING_INFO
	NSLog(@"%s: Removing event handler %p", __PRETTY_FUNCTION__, mouseMovedHandler);
#endif
	RemoveEventHandler((EventHandlerRef)mouseMovedHandler);
	 */

#if LOG_TRACKING_INFO
	NSLog(@"%s: Invalidating and releasing timer %@", __PRETTY_FUNCTION__, tooltipDelayTimer);
#endif
	[tooltipDelayTimer invalidate];
	[tooltipDelayTimer release];
	tooltipDelayTimer = nil;
}

- (void)_hideTooltip
{
#if LOG_TRACKING_INFO
	NSLog(@"%s: tooltipLocation is %@; delegate is %@", __PRETTY_FUNCTION__, NSStringFromPoint(tooltipLocation), delegate);
#endif
	//If the tooltip was being shown before, hide it
	if (!NSEqualPoints(tooltipLocation,NSZeroPoint)) {
		lastMouseLocation = NSZeroPoint;
		tooltipLocation = NSZeroPoint;

		//Hide tooltip
		[delegate hideTooltip];
	}
}

@end
