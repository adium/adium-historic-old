//
//  JSCEventBezelWindow.m
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelWindow.h"

// This should be a preference setting
#define DISPLAY_LENGTH 3.0

@implementation JSCEventBezelWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    NSWindow *result = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask  backing:NSBackingStoreBuffered defer:NO];
    
    fadingOut = NO;
    
    return result;
}

- (BOOL)canBecomeKeyWindow
{
    return NO;
}

- (void)awakeFromNib
{
    //NSLog(@"despertando ventana");
}

- (void)orderFront:(id)sender
{
    [self setAlphaValue:1.0];
    [self setFadeTimer:nil];
    [self setDisplayTimer:nil];
    [self setFadingOut:YES];
    [[self contentView] setNeedsDisplay:YES];
    [self setDisplayTimer: [NSTimer scheduledTimerWithTimeInterval:DISPLAY_LENGTH
                                                         target:self
                                                       selector:@selector(endDisplay:)
                                                       userInfo:nil
                                                        repeats:NO]];
    [super orderFront:sender];
}

- (void)endDisplay:(NSTimer *)timer
{
    [self setFadeTimer: [NSTimer scheduledTimerWithTimeInterval:0.1
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
        [self setFadingOut:NO];
        [self orderOut:nil];
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

- (BOOL)fadingOut
{
    return fadingOut;
}

- (void)setFadingOut:(BOOL)newFade
{
    fadingOut = newFade;
}

@end
