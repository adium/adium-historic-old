//
//  AITextColorPreviewView.m
//  Adium
//
//  Created by Adam Iser on 8/14/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AITextColorPreviewView.h"


@implementation AITextColorPreviewView

- (void)drawRect:(NSRect)rect
{
	NSDictionary		*attributes;
	NSAttributedString	*sample;
		
	//Background
	if(backgroundGradientColor){
		[[AIGradient gradientWithFirstColor:[backgroundGradientColor color]
							   secondColor:[backgroundColor color]
								 direction:AIVertical] drawInRect:rect];
	}else{
		[[backgroundColor color] set];
		[NSBezierPath fillRect:rect];
	}

	//Text
	attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:12], NSFontAttributeName,
		[NSParagraphStyle styleWithAlignment:NSCenterTextAlignment], NSParagraphStyleAttributeName,
		[textColor color], NSForegroundColorAttributeName,
		nil];
	sample = [[[NSAttributedString alloc] initWithString:@"Sample Text" attributes:attributes] autorelease];
	int	sampleHeight = [sample size].height;
	
	[sample drawInRect:NSMakeRect(rect.origin.x,
								  rect.origin.y + (rect.size.height - sampleHeight) / 2.0,
								  rect.size.width,
								  sampleHeight)];
}

@end
