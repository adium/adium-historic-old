//
//  JSCEventBezelView.h
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//


@interface JSCEventBezelView : NSView {
    NSImage *backdropImage;
    NSImage *buddyIconImage;
    NSImage *buddyIconBadge;
    BOOL    defaultBuddyImage;
    
    NSString *mainBuddyName;
    NSString *mainBuddyStatus;
    NSString *queueField;
    
    NSMutableDictionary    *mainAttributes;
    NSMutableDictionary    *mainAttributesMask;
    NSMutableDictionary    *secondaryAttributes;
    NSMutableDictionary    *secondaryAttributesMask;
    NSMutableDictionary    *mainStatusAttributes;
    NSMutableDictionary    *mainStatusAttributesMask;
    
    NSColor         *buddyIconLabelColor;
    NSColor         *buddyNameLabelColor;
    BOOL            useBuddyIconLabel, useBuddyNameLabel;
    
    NSSize          bezelSize;
}

- (NSImage *)buddyIconImage;
- (void)setBuddyIconImage:(NSImage *)newImage;
- (NSImage *)buddyIconBadge;
- (void)setBuddyIconBadgeType:(NSString *)badgeName;

- (NSString *)mainBuddyName;
- (void)setMainBuddyName:(NSString *)newString;
- (NSString *)mainBuddyStatus;
- (void)setMainBuddyStatus:(NSString *)newString;
- (NSString *)queueField;
- (void)setQueueField:(NSString *)newString;

- (NSColor *)buddyIconLabelColor;
- (void)setBuddyIconLabelColor:(NSColor *)newColor;
- (NSColor *)buddyNameLabelColor;
- (void)setBuddyNameLabelColor:(NSColor *)newColor;

- (BOOL)useBuddyIconLabel;
- (void)setUseBuddyIconLabel:(BOOL)b;
- (BOOL)useBuddyNameLabel;
- (void)setUseBuddyNameLabel:(BOOL)b;
- (NSSize)bezelSize;
- (void)setBezelSize:(NSSize)newSize;

- (NSImage *)backdropImage;
- (void)setBackdropImage:(NSImage *)newImage;
@end
