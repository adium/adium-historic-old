//
//  AIListContactBubbleCell.m
//  Adium
//
//  Created by Adam Iser on Thu Jul 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactBubbleCell.h"

#define BUBBLE_TOP_PADDING		0
#define BUBBLE_BOTTOM_PADDING	1
#define EDGE_INDENT 			4
#define BUBBLE_NAME_ONLY		YES

@implementation AIListContactBubbleCell

//Add padding for our bubble
- (NSSize)cellSize
{
	NSSize	size = [super cellSize];

	size.height += BUBBLE_TOP_PADDING + BUBBLE_BOTTOM_PADDING;

	return(size);
}

//Padding
- (int)topPadding{
	return(BUBBLE_TOP_PADDING);
}
- (int)bottomPadding{
	return(BUBBLE_BOTTOM_PADDING);
}
- (int)leftPadding{
	return(EDGE_INDENT);
}
- (int)rightPadding{
	return(EDGE_INDENT);
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	NSColor			*labelColor = [self backgroundColor];
	
	//Draw our label
	if(labelColor){
		NSRect		labelRect = rect;//cellFrame;
		
		//Restict our label to the object name if desired
		if(BUBBLE_NAME_ONLY){				
			labelRect.size.width = [[self displayNameStringWithAttributes:NO] size].width + (EDGE_INDENT * 2);
		}

		//Retrieve the label and shift it into position
		NSBezierPath *pillPath = [NSBezierPath bezierPathWithRoundedRect:labelRect];
		
		//Fill the label
		[labelColor set];
		[pillPath fill];
		
		//Outline the label
		if([self isHighlighted]){
			[pillPath setLineWidth:1.0];
			[[NSColor selectedControlColor] set];
			[pillPath stroke];
		}
	}
}




@end
