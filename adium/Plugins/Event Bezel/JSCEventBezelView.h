//
//  JSCEventBezelView.h
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//


@interface JSCEventBezelView : NSView {
    NSImage *backdropImage;
    NSImage *buddyIconImage;
    BOOL    defaultBuddyImage;
}

- (NSImage *)buddyIconImage;
- (void)setBuddyIconImage:(NSImage *)newImage;

@end
