//
//  JSCEventBezelWindow.m
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelWindow.h"

@implementation JSCEventBezelWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    NSWindow *result = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask  backing:NSBackingStoreBuffered defer:NO];
    
    fadingOut = NO;
    fadingIn = NO;
    doFadeIn = NO;
    doFadeOut = YES;
    appWasHidden = NO;
    
    displayDuration = 3;
    
    return result;
}

- (BOOL)canBecomeKeyWindow
{
    return NO;
}

- (void)showBezelWindow
{
    if (doFadeIn && !fadingOut) {
        [self setAlphaValue:0.0];
        [self setFadingOut:NO];
        [self setFadingIn:YES];
        [self setFadeTimer: [NSTimer scheduledTimerWithTimeInterval:0.05
                                                             target:self
                                                           selector:@selector(fadeIn:)
                                                           userInfo:nil
                                                            repeats:YES]];
    } else {
        [self setAlphaValue:1.0];
        [self startTimer];
    }
}

- (void)startTimer;
{
    [self setFadingOut:YES];
    [self setFadingIn:NO];
    [self setFadeTimer:nil];
    [self setDisplayTimer: [NSTimer scheduledTimerWithTimeInterval:displayDuration
                                                         target:self
                                                       selector:@selector(endDisplay:)
                                                       userInfo:nil
                                                        repeats:NO]];
}

- (void)endDisplay:(NSTimer *)timer
{
    if (doFadeOut) {
        [self setFadeTimer: [NSTimer scheduledTimerWithTimeInterval:0.05
                                                            target:self
                                                          selector:@selector(fadeOut:)
                                                          userInfo:nil
                                                           repeats:YES]];
    } else {
        [self setFadingOut:NO];
        if (appWasHidden) {
            [NSApp hide:self];
        }
        [self close];
    }
}

// Called repeatedly after the window is show
- (void)fadeIn:(NSTimer *)timer
{
    if ([self alphaValue]<1.0) {
        [self setAlphaValue: [self alphaValue]+0.1];
    }
    if ([self alphaValue]>=1.0) {
        [self setFadeTimer:nil];
        [self setFadingIn:NO];
        [self startTimer];
    }
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
        if (appWasHidden) {
            [NSApp hide:self];
        }
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

- (BOOL)fadingOut
{
    return fadingOut;
}

- (void)setFadingOut:(BOOL)newFade
{
    fadingOut = newFade;
}

- (BOOL)fadingIn
{
    return fadingIn;
}

- (void)setFadingIn:(BOOL)newFade
{
    fadingIn = newFade;
}

- (int)displayDuration
{
    return displayDuration;
}

- (void)setDisplayDuration:(int)newDuration
{
    displayDuration = newDuration;
}

- (BOOL)doFadeOut
{
    return doFadeOut;
}

- (void)setDoFadeOut:(BOOL)b
{
    doFadeOut = b;
}

- (BOOL)doFadeIn
{
    return doFadeIn;
}

- (void)setDoFadeIn:(BOOL)b
{
    doFadeIn = b;
}

- (BOOL)appWasHidden
{
    return appWasHidden;
}

- (void)setAppWasHidden:(BOOL)b
{
    appWasHidden = b;
}

@end
