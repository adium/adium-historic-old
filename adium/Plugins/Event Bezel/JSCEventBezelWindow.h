//
//  JSCEventBezelWindow.h
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//


@interface JSCEventBezelWindow : NSWindow {
    NSTimer     *fadeTimer, *displayTimer;
    BOOL        fadingOut, fadingIn;
    BOOL        doFadeOut, doFadeIn;
    BOOL        appWasHidden;
    int         displayDuration;
}

- (void)showBezelWindow;
- (void)startTimer;

- (NSTimer *)fadeTimer;
- (void)setFadeTimer:(NSTimer *)timer;
- (NSTimer *)displayTimer;
- (void)setDisplayTimer:(NSTimer *)timer;
- (BOOL)fadingOut;
- (void)setFadingOut:(BOOL)newFade;
- (BOOL)fadingIn;
- (void)setFadingIn:(BOOL)newFade;
- (int)displayDuration;
- (void)setDisplayDuration:(int)newDuration;
- (BOOL)doFadeOut;
- (void)setDoFadeOut:(BOOL)b;
- (BOOL)doFadeIn;
- (void)setDoFadeIn:(BOOL)b;
- (BOOL)appWasHidden;
- (void)setAppWasHidden:(BOOL)b;
@end
