//
//  AIImageCellAnimationFix.m
//  Adium
//
//  Created by Evan Schoenberg on 12/23/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

/* 
 This NSImageCell poseAsClass implementation exists to fix a simple bug: an animating NSImageCell, as of
 10.3, does not mark its controlView as needing display, so the animation occurs but is not reflected in the view
 until something else causes a display update.
 */

#import "AIImageCellAnimationFix.h"

@implementation AIImageCellAnimationFix

+ (void)load
{
	[self poseAsClass:[NSImageCell class]];
}

- (void)_animationTimerCallback:(NSTimer *)inTimer
{
	[super _animationTimerCallback:inTimer];
	
	[[self controlView] setNeedsDisplay:YES];
}

@end
