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
    NSImage *buddyIconBadge;
    BOOL    defaultBuddyImage;
    
    NSString *mainBuddyName;
    NSString *mainBuddyStatus;
    NSString *queueField;
    
    NSMutableDictionary    *mainAttributes;
    NSDictionary    *mainAttributesMask;
    NSDictionary    *secondaryAttributes;
    NSDictionary    *secondaryAttributesMask;
    NSDictionary    *mainStatusAttributes;
    NSDictionary    *mainStatusAttributesMask;
    
    NSColor         *buddyIconLabelColor;
    NSColor         *buddyNameLabelColor;
    BOOL            useBuddyIconLabel, useBuddyNameLabel;
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

@end
