//
//  AIRolloverButton.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 12/2/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIRolloverButton;

/*!
	@protocol AIRolloverButtonDelegate
	@abstract Protocol implemented by the <tt>AIRolloverButton</tt> delegate
	@discussion An AIRolloverButton delegate is required to implement <tt>AISmoothTooltipTrackerDelegate</tt>.
 */
@protocol AIRolloverButtonDelegate
/*!
	@method rolloverButton:mouseChangedToInsideButton:
	@abstract Informs the delegate of the mouse entering/leaving the button's bounds
	@discussion Informs the delegate of the mouse entering/leaving the button's bounds
	@param button The button whose status changed
	@param isInside YES if the mouse is now within the button; NO if it is now outside the button
*/ 
- (void)rolloverButton:(AIRolloverButton *)button mouseChangedToInsideButton:(BOOL)isInside;
@end

/*!
	@class AIRolloverButton
	@abstract An NSButton subclass which informs its delegate when the mouse is within its bounds
	@discussion This NSButton subclass informs its delegate when the mouse enters or leaves its bounds.
*/
@interface AIRolloverButton : NSButton {
	NSObject<AIRolloverButtonDelegate>	*delegate;
	NSTrackingRectTag					trackingTag;	
}

//Configuration
/*!
	@method setDelegate:
	@abstract Set the delegate
	@discussion Set the delegate.  See <tt>AIRolloverButtonDelegate</tt> protocol discussion for details.
	@param inDelegate The delegate, which must conform to <tt>AIRolloverButtonDelegate</tt>.
*/ 
- (void)setDelegate:(NSObject<AIRolloverButtonDelegate> *)inDelegate;

/*!
	@method delegate
	@abstract Return the delegate
	@discussion Return the delegate.
	@result The delegate
*/ 
- (NSObject<AIRolloverButtonDelegate> *)delegate;
@end
