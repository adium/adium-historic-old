//
//  ESImageAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Dec 02 2003.

typedef enum {
    AIButtonActive = 0,
    AIButtonPressed,
    AIButtonUnknown,
    AIButtonDisabled,
    AIButtonHovered
} AICloseButtonState;

@interface NSImage (ESImageAdditions)

- (NSData *)JPEGRepresentation;
- (void)tileInRect:(NSRect)rect;
+ (NSImage *)imageFromGWorld:(GWorldPtr)gWorldPtr;
+ (NSImage *)systemCloseButtonImageForState:(AICloseButtonState)state controlTint:(NSControlTint)inTint;
+ (NSImage *)systemCheckmark;

@end
