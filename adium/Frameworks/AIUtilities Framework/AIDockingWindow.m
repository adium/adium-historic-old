//
//  AIDockingWindow.m
//  Adium
//
//  Created by Adam Iser on Sun May 02 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIDockingWindow.h"

#define WINDOW_DOCKING_DISTANCE 	10	//Distance in pixels before the window is snapped to an edge

@interface AIDockingWindow (PRIVATE)
- (id)_init;
- (NSRect)dockWindowFrame:(NSRect)windowFrame toScreenFrame:(NSRect)screenFrame;
@end

@implementation AIDockingWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	[super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    [self _init];
	return(self);
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _init];
    return(self);
}
- (id)init
{
	[super init];
    [self _init];
    return(self);
}

//Observe window movement
- (id)_init
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidMode:) name:NSWindowDidMoveNotification object:self];
}

//Stop observing movement
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidMoveNotification object:self];
	[super dealloc];
}

//Watch the window move.  If it gets near an edge, dock it to that edge
- (void)windowDidMode:(NSNotification *)notification
{
	static	BOOL alreadyMoving = NO;
	
	if(!alreadyMoving){  //Our setFrame call below will cause a re-entry into this function, we must guard against this
		alreadyMoving = YES;	
		
		//Attempt to dock this window the the visible frame first, and then to the screen frame
		NSRect	windowFrame = [self frame];
		windowFrame = [self dockWindowFrame:windowFrame toScreenFrame:[[self screen] visibleFrame]];
		windowFrame = [self dockWindowFrame:windowFrame toScreenFrame:[[self screen] frame]];

		//If the window wants to dock, animate it into place
		if(!NSEqualRects([self frame], windowFrame)){
			[self setFrame:windowFrame display:YES animate:YES];
		}
		
		alreadyMoving = NO; //Clear the guard, we are now safe
	}
}

//Dock the passed window frame if it's close enough to the screen edges
- (NSRect)dockWindowFrame:(NSRect)windowFrame toScreenFrame:(NSRect)screenFrame
{
	//Left
	if(abs(NSMinX(windowFrame) - NSMinX(screenFrame)) < WINDOW_DOCKING_DISTANCE){
		windowFrame.origin.x = screenFrame.origin.x;
	}
	
	//Bottom
	if(abs(NSMinY(windowFrame) - NSMinY(screenFrame)) < WINDOW_DOCKING_DISTANCE){
		windowFrame.origin.y = screenFrame.origin.y;
	}
	
	//Right
	if(abs(NSMaxX(windowFrame) - NSMaxX(screenFrame)) < WINDOW_DOCKING_DISTANCE){
		windowFrame.origin.x -= NSMaxX(windowFrame) - NSMaxX(screenFrame);
	}
	
	//Top
	if(abs(NSMaxY(windowFrame) - NSMaxY(screenFrame)) < WINDOW_DOCKING_DISTANCE){
		windowFrame.origin.y -= NSMaxY(windowFrame) - NSMaxY(screenFrame);
	}
	
	return(windowFrame);
}

@end
