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
    
    NSDictionary    *mainAttributes;
    NSDictionary    *mainAttributesMask;
    NSDictionary    *secondaryAttributes;
    NSDictionary    *secondaryAttributesMask;
    NSDictionary    *mainStatusAttributes;
    NSDictionary    *mainStatusAttributesMask;
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
@end
