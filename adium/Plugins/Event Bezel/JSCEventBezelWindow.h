//
//  JSCEventBezelWindow.h
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//


@interface JSCEventBezelWindow : NSWindow {
    NSTimer     *fadeTimer, *displayTimer;
    BOOL        onScreen;
    int         displayDuration;
}

- (void)showBezelWindow;
- (void)startTimer;
- (void)endDisplay;

- (NSTimer *)fadeTimer;
- (void)setFadeTimer:(NSTimer *)timer;
- (NSTimer *)displayTimer;
- (void)setDisplayTimer:(NSTimer *)timer;
- (BOOL)onScreen;
- (void)setOnScreen:(BOOL)newFade;
- (int)displayDuration;
- (void)setDisplayDuration:(int)newDuration;
@end
