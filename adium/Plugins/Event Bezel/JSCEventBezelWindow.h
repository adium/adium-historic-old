//
//  JSCEventBezelWindow.h
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//


@interface JSCEventBezelWindow : NSWindow {
    NSTimer     *fadeTimer, *displayTimer;
    BOOL        fadingOut;
    int         displayDuration;
}

- (void)startTimer;

- (NSTimer *)fadeTimer;
- (void)setFadeTimer:(NSTimer *)timer;
- (NSTimer *)displayTimer;
- (void)setDisplayTimer:(NSTimer *)timer;
- (BOOL)fadingOut;
- (void)setFadingOut:(BOOL)newFade;
- (int)displayDuration;
- (void)setDisplayDuration:(int)newDuration;
@end
