//
//  AIRolloverButton.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 12/2/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "AIRolloverButton.h"

@implementation AIRolloverButton

- (void)awakeFromNib
{	
	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]){
        [super awakeFromNib];
	}

	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(rolloverFrameDidChange:)
												 name:NSViewFrameDidChangeNotification
											   object:self];
	[self setPostsFrameChangedNotifications:YES];
	[self resetCursorRects];
}

- (void)dealloc
{
	if(trackingTag != -1){
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}
	
	[super dealloc];
}

#pragma mark Configuration
//Set our delegate
- (void)setDelegate:(id)inDelegate
{
    delegate = inDelegate;
	
	//Make sure this delegate responds to the required method
	NSParameterAssert([delegate respondsToSelector:@selector(rolloverButton:mouseChangedToInsideButton:)]);
}
- (id)delegate{
    return(delegate);
}

//Cursor Tracking  -----------------------------------------------------------------------------------------------------
#pragma mark Cursor Tracking

//Remove old tracking rects when we change superviews
- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	[super viewWillMoveToSuperview:newSuperview];
	
	if(trackingTag != -1){
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}	
}

- (void)rolloverFrameDidChange:(NSNotification *)inNotification
{
	[self resetCursorRects];
}

//Reset our cursor tracking
- (void)resetCursorRects
{
	NSRect	frame = [self frame];
		
	//Stop any existing tracking
	if(trackingTag != -1){
		[self removeTrackingRect:trackingTag];
		trackingTag = -1;
	}
	
	//Add a tracking rect if our superview and window are ready
	if([self window]){
		NSRect	trackRect = NSMakeRect(0,0,frame.size.width, frame.size.height);
		NSPoint	localPoint = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]]
									   fromView:nil];
		BOOL	mouseInside = NSPointInRect(localPoint, trackRect);
		
		trackingTag = [self addTrackingRect:trackRect owner:self userData:nil assumeInside:mouseInside];
		if(mouseInside) [self mouseEntered:nil];
	}
}

//Cursor entered our view
- (void)mouseEntered:(NSEvent *)theEvent
{
	[delegate rolloverButton:self mouseChangedToInsideButton:YES];
}

//Cursor left our view
- (void)mouseExited:(NSEvent *)theEvent
{
	[delegate rolloverButton:self mouseChangedToInsideButton:NO];
}

@end
