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
	NSMutableDictionary	*attributes;
	NSAttributedString	*sample;
	id					shadow = nil;
		
	//Background
	if(backgroundGradientColor){
		[[AIGradient gradientWithFirstColor:[backgroundGradientColor color]
							   secondColor:[backgroundColor color]
								 direction:AIVertical] drawInRect:rect];
	}else{
		[[backgroundColor color] set];
		[NSBezierPath fillRect:rect];
	}

	//Shadow
	if([NSApp isOnPantherOrBetter] && [textShadowColor color]){
		Class 	shadowClass = NSClassFromString(@"NSShadow"); //Weak Linking for 10.2 compatability
		shadow = [[[shadowClass alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:[textShadowColor color]];
	}

	//Text
	attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:12], NSFontAttributeName,
		[NSParagraphStyle styleWithAlignment:NSCenterTextAlignment], NSParagraphStyleAttributeName,
		[textColor color], NSForegroundColorAttributeName,
		nil];
	if(shadow) [attributes setObject:shadow forKey:NSShadowAttributeName];
	
	sample = [[[NSAttributedString alloc] initWithString:@"Sample Text" attributes:attributes] autorelease];
	int	sampleHeight = [sample size].height;
	
	[sample drawInRect:NSMakeRect(rect.origin.x,
								  rect.origin.y + (rect.size.height - sampleHeight) / 2.0,
								  rect.size.width,
								  sampleHeight)];
}

@end
