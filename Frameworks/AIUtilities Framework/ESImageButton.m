//
//  ESImageButton.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/16/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESImageButton.h"
#import "ESFloater.h"

@implementation ESImageButton

//Mouse Tracking -------------------------------------------------------------------------------------------------------
#pragma mark Mouse Tracking
//Custom mouse down tracking to display our image and highlight
- (void)mouseDown:(NSEvent *)theEvent
{
	if([self isEnabled]){
		[self highlight:YES];
		
		//Find our display point, the bottom-left of our button, in screen coordinates
		NSPoint point = [[self window] convertBaseToScreen:[self convertPoint:[self bounds].origin toView:nil]];
		point.y -= NSHeight([self frame]) + 2;
		point.x -= 1;
		
		//Move the display point down by the height of our image
		point.y -= [bigImage size].height;

		//imageFloater retains itself until it closes
		imageFloater = [ESFloater floaterWithImage:bigImage styleMask:NSBorderlessWindowMask];
		[imageFloater setMaxOpacity:0.90];
		[imageFloater moveFloaterToPoint:point];
		[imageFloater setVisible:YES animate:YES];
	}
}

//Remove highlight and image on mouse up
- (void)mouseUp:(NSEvent *)theEvent
{
	[self highlight:NO];

	[imageFloater setVisible:NO animate:YES];
	
	//Let it stay around briefly before closing so the animation fades it out
	[imageFloater performSelector:@selector(close:)
					 withObject:nil
					 afterDelay:0.5];

	[super mouseUp:theEvent];
}	

@end
