//
//  JSCEventBezelController.h
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelWindow.h"
#import "JSCEventBezelView.h"
#define AUTOFRAME_NAME		@"EventBezelWindow"
#define AUTOFRAME_KEY		@"NSWindow Frame EventBezelWindow"

@interface JSCEventBezelController : AIWindowController {
    IBOutlet JSCEventBezelWindow    *bezelWindow;
    IBOutlet JSCEventBezelView      *bezelView;
    
    int                             bezelDuration;
    NSRect                          bezelFrame;
    NSColor                         *buddyIconLabelColor;
    NSColor                         *buddyNameLabelColor;
	NSMutableArray					*bezelDataQueue;
}

+ (JSCEventBezelController *)eventBezelController;

- (void)showBezelWithContact:(NSString *)contactName
withImage:(NSImage *)buddyIcon
forEvent:(NSString *)event
ignoringClicks:(BOOL)ignoreClicks;

- (int)bezelDuration;
- (void)setBezelDuration:(int)newDuration;
- (NSColor *)buddyIconLabelColor;
- (void)setBuddyIconLabelColor:(NSColor *)newColor;
- (NSColor *)buddyNameLabelColor;
- (void)setBuddyNameLabelColor:(NSColor *)newColor;
@end
