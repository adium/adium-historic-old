//
//  AIListGroupBubbleToFitCell.m
//  Adium
//
//  Created by Adam Iser on 8/12/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupBubbleToFitCell.h"

@implementation AIListGroupBubbleToFitCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//Adjust the bubble rect to tightly fit our label string
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	NSAttributedString	*displayName = [[NSAttributedString alloc] initWithString:[self labelString]
																	   attributes:[self labelAttributes]];
	NSSize				nameSize = [displayName size];
	float				originalWidth = rect.size.width;

	//Alignment
	switch([self textAlignment]){
		case NSCenterTextAlignment:
			rect.origin.x += ((rect.size.width - nameSize.width) / 2.0) - [self leftPadding];
		break;
		case NSRightTextAlignment:
			rect.origin.x += (rect.size.width - nameSize.width) - [self leftPadding] - [self rightPadding];
		break;
		default:
		break;
	}
	
	//Fit the bubble to their name
	rect.size.width = nameSize.width + [self leftPadding] + [self rightPadding];
	
	//Until we get right aligned/centered flippies, this will do
	if([self textAlignment] == NSLeftTextAlignment){
		rect.size.width += [self flippyIndent];
	}
	
	//Don't let the bubble try to draw larger than the width we were passed, which was the full width possible
	if (rect.size.width > originalWidth) rect.size.width = originalWidth;
	
	return(rect);
}

@end
