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
    NSShadow *textShadow;
    
    NSString *mainBuddyName;
    NSString *mainBuddyStatus;
    NSString *mainAwayMessage;
    NSString *queueField;
}

- (NSImage *)buddyIconImage;
- (void)setBuddyIconImage:(NSImage *)newImage;

- (NSString *)mainBuddyName;
- (void)setMainBuddyName:(NSString *)newString;
- (NSString *)mainBuddyStatus;
- (void)setMainBuddyStatus:(NSString *)newString;
- (NSString *)mainAwayMessage;
- (void)setMainAwayMessage:(NSString *)newString;
- (NSString *)queueField;
- (void)setQueueField:(NSString *)newString;
@end
