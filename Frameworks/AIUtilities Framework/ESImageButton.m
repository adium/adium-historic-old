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

//
- (id)initWithFrame:(NSRect)frame
{
	[super initWithFrame:frame];
	imageFloater = nil;
	return(self);
}

- (id)copyWithZone:(NSZone *)zone
{
	ESImageButton	*newButton = [super copyWithZone:zone];

	newButton->imageFloater = [imageFloater retain];
	
	return(newButton);
}

- (void)dealloc
{
	[imageFloater release]; imageFloater = nil;
	
	[super dealloc];
}

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

		[imageFloater release];
		imageFloater = [[ESFloater floaterWithImage:bigImage styleMask:NSBorderlessWindowMask] retain];
		[imageFloater setMaxOpacity:0.90];
		[imageFloater moveFloaterToPoint:point];
		[imageFloater setVisible:YES animate:YES];
	}
}

//Remove highlight and image on mouse up
- (void)mouseUp:(NSEvent *)theEvent
{
	[self highlight:NO];
	
	if(imageFloater){
		[imageFloater setVisible:NO animate:YES];
		
		//Let it stay around briefly before closing so the animation fades it out
		[self performSelector:@selector(destroyImageFloater)
				   withObject:nil
				   afterDelay:0.5];
	}
	
	[super mouseUp:theEvent];
}

- (void)destroyImageFloater
{
	[imageFloater close:nil];
	[imageFloater release]; imageFloater = nil;
}

@end
