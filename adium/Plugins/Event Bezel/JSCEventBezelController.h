//
//  JSCEventBezelController.h
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelWindow.h"
#import "JSCEventBezelView.h"

@interface JSCEventBezelController : NSWindowController {
    IBOutlet JSCEventBezelWindow    *bezelWindow;
    IBOutlet JSCEventBezelView      *bezelView;
    AIAdium                         *owner;
    
    int                             bezelPosition, bezelDuration;
    BOOL                            imageBadges, useBuddyIconLabel, useBuddyNameLabel;
    NSRect                          bezelFrame;
}

+ (JSCEventBezelController *)eventBezelControllerForOwner:(id)inOwner;

- (void)showBezelWithContact:(NSString *)contactName
withImage:(NSImage *)buddyIcon
forEvent:(NSString *)event
withMessage:(NSString *)message;

- (int)bezelPosition;
- (void)setBezelPosition:(int)newPosition;
- (int)bezelDuration;
- (void)setBezelDuration:(int)newDuration;
- (void)setBuddyIconLabelColor:(NSColor *)newColor;
- (void)setBuddyNameLabelColor:(NSColor *)newColor;
- (void)setImageBadges:(BOOL)b;
- (BOOL)useBuddyIconLabel;
- (void)setUseBuddyIconLabel:(BOOL)b;
- (BOOL)useBuddyNameLabel;
- (void)setUseBuddyNameLabel:(BOOL)b;

@end
