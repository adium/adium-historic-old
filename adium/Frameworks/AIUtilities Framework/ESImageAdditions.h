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

+ (NSImage *)imageNamed:(NSString *)name forClass:(Class)inClass;
- (NSData *)JPEGRepresentation;
- (NSData *)PNGRepresentation;
- (NSData *)BMPRepresentation;
- (void)tileInRect:(NSRect)rect;
- (NSImage *)imageByScalingToSize:(NSSize)size;
+ (NSImage *)imageFromGWorld:(GWorldPtr)gWorldPtr;
+ (NSImage *)systemCloseButtonImageForState:(AICloseButtonState)state controlTint:(NSControlTint)inTint;
+ (NSImage *)systemCheckmark;

@end

//Defined in AppKit.framework
@interface NSImageCell(NSPrivateAnimationSupport)
- (BOOL)_animates;
- (void)_setAnimates:(BOOL)fp8;
- (void)_startAnimation;
- (void)_stopAnimation;
- (void)_animationTimerCallback:fp8;
@end