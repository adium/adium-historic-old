//
//  AIListContactBubbleCell.m
//  Adium
//
//  Created by Adam Iser on Thu Jul 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactBubbleCell.h"

#define BUBBLE_TOP_PADDING		0
#define BUBBLE_BOTTOM_PADDING	0
#define EDGE_INDENT 			4
#define BUBBLE_NAME_ONLY		YES

@implementation AIListContactBubbleCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//Add padding for our bubble
- (NSSize)cellSize
{
	NSSize	size = [super cellSize];

	size.height += BUBBLE_TOP_PADDING + BUBBLE_BOTTOM_PADDING;

	return(size);
}

//Give ourselves more padding
- (int)topPadding{
	return([super topPadding] + BUBBLE_TOP_PADDING);
}
- (int)bottomPadding{
	return([super bottomPadding] + BUBBLE_BOTTOM_PADDING);
}
#warning need a real fix...
- (int)leftPadding{
	return([super leftPadding] + EDGE_INDENT);
}
- (int)rightPadding{
	return([super rightPadding] + EDGE_INDENT);
}

- (BOOL)padToFlippy{
	return(NO);
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	NSColor			*labelColor = [self labelColor];
	if(drewSelection) {
		drewSelection = NO;
		return;
	}
	//Draw our label
	if(labelColor){
		//Retrieve the label and shift it into position
		NSBezierPath *pillPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]];
		
		//Fill the label
		[labelColor set];
		[pillPath fill];
		
		//Outline the label
//		if([self isHighlighted]){
//			[pillPath setLineWidth:1.0];
//			[[NSColor selectedControlColor] set];
//			[pillPath stroke];
//		}
	}
}

//Draw
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	[self drawBackgroundWithFrame:cellFrame];
	
	NSRect rect = [self bubbleRectForFrame:cellFrame];
	
	rect = NSInsetRect(rect,1,1);
	
	NSLog(@"_drawHighlightWithFrame");
	NSBezierPath *pillPath = [NSBezierPath bezierPathWithRoundedRect:rect];

	[pillPath setLineWidth:2.0];
	[[NSColor alternateSelectedControlColor] set];
	[pillPath stroke];
	
	drewSelection = YES;
}
	
//
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	return(rect);
}

@end
