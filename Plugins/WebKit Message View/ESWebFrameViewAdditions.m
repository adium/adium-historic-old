//
//  ESWebFrameViewAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Mar 05 2004.
//

#import "ESWebFrameViewAdditions.h"

@implementation ESWebFrameView

+ (void)initialize
{
	[self poseAsClass:[WebFrameView class]];
}

- (unsigned int)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSLog(@"dragging entered: %@",[[sender draggingPasteboard] types]);
	return (NSDragOperationPrivate);
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSLog(@"Prepare?");
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSLog(@"Perform?");
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSLog(@"conclude");
}

/*
@implementation WebFrameView (ESWebFrameViewAdditions)

//WebDynamicScrollBarsView is a subclass of NSScrollView
- (WebDynamicScrollBarsView *)frameScrollView
{
	return [_private frameScrollView];
}

@end

//ESWebFrameViewPrivateHack lets us access WebFrameViewPrivate's protected variables
@implementation WebFrameViewPrivate (ESWebFrameViewPrivateHack)

//frameScrollView is normally protected; add an accesssor to it
- (WebDynamicScrollBarsView *)frameScrollView
{
	return frameScrollView;
}

@end
*/