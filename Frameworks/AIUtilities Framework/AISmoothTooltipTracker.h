//
//  AISmoothTooltipTracker.h
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//


//Delegate handles displaying the tooltips, we handle all the tracking
/*!
	@protocol AISmoothTooltipTrackerDelegate
	@abstract Protocol implemented by the <tt>AISmoothTooltipTracker</tt> delegate
	@discussion An AISmoothTooltipTracker delegate is required to implement <tt>AISmoothTooltipTrackerDelegate</tt>.
 */
@protocol AISmoothTooltipTrackerDelegate
/*!
	@method showTooltipAtPoint:
	@abstract Informs the delegate the point at which the mouse is hovering.
	@discussion Sent continuously as the mouse moves within the visible view monitored by the <tt>AISmoothTooltipTracker</tt>.  It is initially sent after the mouse hovers for at least a second in a single location within the view. Sent regardless of whether the application is active or not.
	@param screenPoint The point, in screen coordinates, at which the mouse is hovering.
*/ 
- (void)showTooltipAtPoint:(NSPoint)screenPoint;

/*!
	@method hideTooltip
	@abstract Informs the delegate that the mouse has left the view so the tooltip should be hidden.
	@discussion Informs the delegate that the mouse has left the view so the tooltip should be hidden. Sent when the mouse leaves the view or it becomes obscured or hidden.
*/ 
- (void)hideTooltip;
@end

/*!
@class AISmoothTooltipTracker
@abstract Controller to track the mouse when it hovers over a view, informing a delegate of the hover point
@discussion <p>An <tt>AISmoothTooltipTracker</tt> is created for a specific view.  It informs its delegate when the mouse hovers over the view for about a second.</p>
<p>The delegate will be informed of the mouse hover even if the application is not currently active (so long as the view is visible to the user).</p>
The delegate is updated as the mouse moves (via showTooltipAtPoint:), and is informed when the mouse leaves or the view is obscured or hidden (via hideTooltip)</p>
<p>Note: The delegate is not retained.  For maximum stability, the delegate should call setDelete:nil some time before it deallocs. Not all implementations will -need- this, but it is recommended.</p>
*/
@interface AISmoothTooltipTracker : NSObject {
	NSView										*view;		//View we are tracking tooltips for
	id<AISmoothTooltipTrackerDelegate>			delegate;	//Our delegate

	NSPoint				lastMouseLocation;				//Last known location of the mouse, used for movement tracking
	NSTimer				*tooltipMouseLocationTimer;		//Checks for mouse movement
	NSPoint				tooltipLocation;				//Last tooltip location we told our delegate about
    NSTrackingRectTag	tooltipTrackingTag;				//Tag for our tracking rect
    int 				tooltipCount;					//Used to determine how long before a tooltip appears
}

/*!
	@method smoothTooltipTrackerForView:withDelegate:
	@abstract Create an <tt>AISmoothTooltipTracker</tt>
	@discussion Create and return an autoreleased <tt>AISmoothTooltipTracker</tt> for <tt>inView</tt> and <tt>inDelegate</tt>.
	@param inView The view in which to track mouse movements
	@param inDelegate The 
	@result	An <tt>AISmoothTooltipTracker</tt> instance
*/ 
+ (AISmoothTooltipTracker *)smoothTooltipTrackerForView:(NSView *)inView withDelegate:(id<AISmoothTooltipTrackerDelegate>)inDelegate;

/*!
	@method setDelegate:
	@abstract Set the delegate
	@discussion Set the delegate.  See <tt>AISmoothTooltipTrackerDelegate</tt> protocol discussion for details.
*/ 
- (void)setDelegate:(id<AISmoothTooltipTrackerDelegate>)inDelegate;

@end
