//
//  JSCEventBezelView.h
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//


@interface JSCEventBezelView : NSView {
    NSImage *buddyIconImage;
    
    NSString *mainBuddyName;
    NSString *mainBuddyStatus;
    
    NSMutableDictionary    *mainAttributes;
    NSMutableDictionary    *mainStatusAttributes;
    
    NSColor         *buddyIconLabelColor;
    NSColor         *buddyNameLabelColor;
	
	NSBezierPath	*backgroundBorder;
	NSBezierPath	*backgroundContent;
	BOOL			ignoringClicks, useGradient,drawBorder;
}

- (NSImage *)buddyIconImage;
- (void)setBuddyIconImage:(NSImage *)newImage;

- (NSString *)mainBuddyName;
- (void)setMainBuddyName:(NSString *)newString;
- (NSString *)mainBuddyStatus;
- (void)setMainBuddyStatus:(NSString *)newString;

- (NSColor *)buddyIconLabelColor;
- (void)setBuddyIconLabelColor:(NSColor *)newColor;
- (NSColor *)buddyNameLabelColor;
- (void)setBuddyNameLabelColor:(NSColor *)newColor;

- (BOOL)ignoringClicks;
- (void)setIgnoringClicks:(BOOL)ignoreClicks;
- (BOOL)useGradient;
- (void)setUseGradient:(BOOL)newValue;

@end
