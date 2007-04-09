//
//  AIMessageTabSplitView.m
//  Adium
//
//  Created by Evan Schoenberg on 4/9/07.
//

#import "AIMessageTabSplitView.h"
#import <PSMTabBarControl/NSBezierPath_AMShading.h>

@implementation AIMessageTabSplitView

-(void)drawDividerInRect:(NSRect)aRect
{	
	NSLog(@"%@",NSStringFromRect(aRect));
	NSBezierPath *path = [NSBezierPath bezierPathWithRect:aRect];
	[path linearVerticalGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]
										  endColor:[NSColor colorWithCalibratedWhite:0.91 alpha:1.0]];
}

@end
