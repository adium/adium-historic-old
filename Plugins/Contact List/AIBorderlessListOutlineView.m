//
//  AIBorderlessListOutlineView.m
//  Adium
//
//  Created by Adam Iser on Thu Jul 29 2004.
//

#import "AIBorderlessListOutlineView.h"


@implementation AIBorderlessListOutlineView

//Forward mouse down events to our containing window (when command is pressed) to allow dragging
- (void)mouseDown:(NSEvent *)theEvent
{
	if([theEvent cmdKey]){
		//Wait for the next event
		NSEvent *nextEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)
														untilDate:[NSDate distantFuture]
														   inMode:NSEventTrackingRunLoopMode
														  dequeue:NO];
		
		//Pass along the event (either to ourself or our window, depending on what it is)
		if([nextEvent type] == NSLeftMouseUp){
			[super mouseDown:theEvent];   
			[super mouseUp:nextEvent];   
		}else if([nextEvent type] == (NSEventType)NSLeftMouseDraggedMask){
			[[self window] mouseDown:theEvent];
			[[self window] mouseDragged:theEvent];
		}else{
			[[self window] mouseDown:theEvent];
		}
	}else{
        [super mouseDown:theEvent];   
	}
}
- (void)mouseDragged:(NSEvent *)theEvent
{
    if([theEvent cmdKey]){
        [[self window] mouseDragged:theEvent];   
	}else{
		[super mouseDragged:theEvent];
	}
}

@end
