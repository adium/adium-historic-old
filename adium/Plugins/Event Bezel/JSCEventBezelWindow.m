//
//  JSCEventBezelWindow.m
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelWindow.h"

@interface JSCEventBezelWindow (PRIVATE)
- (void)stopTimer;
@end

@implementation JSCEventBezelWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    NSWindow *result = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask  backing:NSBackingStoreBuffered defer:flag];
    
    onScreen = NO;
    [self setFadeTimer:nil];
    displayDuration = 3;
    
    return result;
}

- (BOOL)canBecomeKeyWindow
{
    return NO;
}

- (void)showBezelWindow
{
	[self setAlphaValue:1.0];
	[self startTimer];
}

- (void)startTimer;
{
    [self setOnScreen:YES];
	[self setFadeTimer: nil];
    [self setDisplayTimer: [NSTimer scheduledTimerWithTimeInterval:displayDuration
                                                         target:self
                                                       selector:@selector(willEndDisplay:)
                                                       userInfo:nil
                                                        repeats:NO]];
}

- (void)stopTimer
{
	[self setFadeTimer: nil];
	[self setDisplayTimer: nil];
}

- (void)willEndDisplay:(NSTimer *)timer
{
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:@"JSCEventBezelWindowEndTimer" object:nil];
}

- (void)endDisplay;
{
	[self setOnScreen:NO];
	[self setFadeTimer: [NSTimer scheduledTimerWithTimeInterval:0.05
														target:self
													  selector:@selector(fadeOut:)
													  userInfo:nil
													   repeats:YES]];
}

// Called repeatedly after the window is shown
- (void)fadeOut:(NSTimer *)timer
{
    if ([self alphaValue]>0.0) {
        [self setAlphaValue: [self alphaValue]-0.1];
    }
    if ([self alphaValue]<=0.0) {
        [self setFadeTimer:nil];
        [self close];
    }
}

// Accessor methods
- (NSTimer *)fadeTimer
{
    return fadeTimer;
}

- (void)setFadeTimer:(NSTimer *)timer
{
    [timer retain];
    [fadeTimer invalidate];
    [fadeTimer release];
    fadeTimer = timer;
}

- (NSTimer *)displayTimer
{
    return displayTimer;
}

- (void)setDisplayTimer:(NSTimer *)timer
{
    [timer retain];
    [displayTimer invalidate];
    [displayTimer release];
    displayTimer = timer;
}

- (BOOL)onScreen
{
    return onScreen;
}

- (void)setOnScreen:(BOOL)newFade
{
    onScreen = newFade;
}

- (int)displayDuration
{
    return displayDuration;
}

- (void)setDisplayDuration:(int)newDuration
{
    displayDuration = newDuration;
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[NSCursor setOpenGrabHandCursor];
	[self startTimer];
	[super mouseUp: theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[NSCursor setClosedGrabHandCursor];
	if ([self displayTimer]) {
		[self setAlphaValue:1.0];
		[self stopTimer];
	}
	[super mouseDown: theEvent];
}

@end