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

- (int)topPadding
{
	return(BUBBLE_TOP_PADDING);
}

- (int)bottomPadding
{
	return(BUBBLE_BOTTOM_PADDING);
}

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{	
	//Indent for rounded caps
	rect.origin.x += EDGE_INDENT;
	rect.size.width -= (EDGE_INDENT * 2);
	
	[super drawContentWithFrame:rect];
}


//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	NSColor			*labelColor = nil;
	
	//Padding
	rect.origin.y += BUBBLE_TOP_PADDING;
	rect.size.height -= BUBBLE_BOTTOM_PADDING + BUBBLE_TOP_PADDING;

	//Determine our label color
//	if([self isHighlighted] && ([[outlineView window] isKeyWindow] && [[outlineView window] firstResponder] == outlineView)){
//		if(labelAroundContactOnly) {
//			labelColor = [[NSColor alternateSelectedControlColor] colorWithAlphaComponent:[outlineView labelOpacity]];
//		}
//	}else{
//		if(isGroup){
//			labelColor = [[outlineView labelGroupColor] colorWithAlphaComponent:[outlineView labelOpacity]];
//		}else{
			labelColor = [[[listObject displayArrayForKey:@"Label Color"] objectValue] colorWithAlphaComponent:1.0];
//		}
//	}
	
	//Draw our label
	if(labelColor){
		NSRect		labelRect = rect;//cellFrame;
		
		//Restict our label to the object name if desired
		if(BUBBLE_NAME_ONLY){				
			labelRect.size.width = [[self displayNameStringWithAttributes:NO] size].width + (EDGE_INDENT * 2);
		}
		
		//Indent our label into the available margins
//		float	indent = ;//[self labelEdgePaddingRequiredForLabelOfSize:labelRect.size];
		
		//EDS - This should technically be * 2 but that doesn't look right at present.
//		labelRect.size.width += indent * 3;
		
		//Adjust labels slightly when displaying for a group (to avoid overlapping the flippy triangle)
//		if(isGroup){
//			labelRect.origin.x += GROUP_LABEL_LEFT_OFFSET;
//			labelRect.size.width -= GROUP_LABEL_LEFT_OFFSET + GROUP_LABEL_RIGHT_OFFSET;
//		}
		
		//Retrieve the label and shift it into position
		NSBezierPath *pillPath = [NSBezierPath bezierPathWithRoundedRect:labelRect];
		
		//Fill the label
//		if(![outlineView useGradient]){
			[labelColor set];
			[pillPath fill];
//		}else{
//			[[AIGradient gradientWithFirstColor:labelColor secondColor:[labelColor darkenAndAdjustSaturationBy:0.4] direction:AIVertical] drawInBezierPath:pillPath];
//		}
		
		//Outline the label
		if([self isHighlighted]){
			[pillPath setLineWidth:1.0];
			//[[self textColorInView:outlineView] set];
			[[NSColor selectedControlColor] set];
			[pillPath stroke];
		}
			
//		if([outlineView outlineLabels]){
//			[pillPath setLineWidth:1.0];
//			//[[self textColorInView:outlineView] set];
//			[[NSColor greenColor] set];
//			[pillPath stroke];
//		}
	}
}




@end
