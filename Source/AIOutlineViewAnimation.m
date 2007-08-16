//
//  AIOutlineViewAnimation.m
//  Adium
//
//  Created by Evan Schoenberg on 6/9/07.
//

#import "AIOutlineViewAnimation.h"
#import "AIAnimatingListOutlineView.h"

@interface AIAnimatingListOutlineView (AIOutlineViewAnimationDelegate)
- (void)animation:(AIOutlineViewAnimation *)animation didSetCurrentValue:(float)currentValue forDict:(NSDictionary *)animatingRowsDict;
@end

@interface AIOutlineViewAnimation (PRIVATE)
- (id)initWithDictionary:(NSDictionary *)inDict outlineView:(AIAnimatingListOutlineView *)inOutlineView;
@end

/*!
 * @class AIOutlineViewAnimation
 * @brief NSAnimation subclass for AIOutlineView's animations
 *
 * This NSAnimation subclass is a simple subclass to let the outline view handle changes in progress
 * along a non-blocking ease-in/ease-out animation.
 * AIOutlineView should release the AIOutlineViewAnimation when the animation is complete.
 */
@implementation AIOutlineViewAnimation
+ (AIOutlineViewAnimation *)listObjectAnimationWithDictionary:(NSDictionary *)inDict outlineView:(AIAnimatingListOutlineView *)inOutlineView
{
	return [[[self alloc] initWithDictionary:inDict outlineView:inOutlineView] autorelease];
}

- (id)initWithDictionary:(NSDictionary *)inDict outlineView:(AIAnimatingListOutlineView *)inOutlineView
{
	if ((self = [super initWithDuration:LIST_OBJECT_ANIMATION_DURATION animationCurve:NSAnimationEaseInOut])) {
		dict = [inDict retain];
		outlineView = [inOutlineView retain];

		[self setAnimationBlockingMode:NSAnimationNonblocking];
	}
	
	return self;
}

- (void)dealloc
{
	[dict release];
	[outlineView release];

	[super dealloc];
}

/*!
 * @brief We want to run our animation no matter what's going on
 */
- (NSArray *)runLoopModesForAnimating
{
    return [NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil];
}

/*!
 * @brief When progress updates, inform the delegate
 */
- (void)setCurrentProgress:(NSAnimationProgress)progress
{
	[super setCurrentProgress:progress];

	[outlineView animation:self didSetCurrentValue:[self currentValue] forDict:dict];
}

@end
