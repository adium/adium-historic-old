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

typedef enum {
	IMAGE_POSITION_LEFT = 0,
	IMAGE_POSITION_RIGHT,
	IMAGE_POSITION_LOWER_LEFT,
	IMAGE_POSITION_LOWER_RIGHT
} IMAGE_POSITION;

@interface NSImage (ESImageAdditions)

+ (NSImage *)imageNamed:(NSString *)name forClass:(Class)inClass;
- (NSData *)JPEGRepresentation;
- (NSData *)PNGRepresentation;
- (NSData *)BMPRepresentation;
- (void)tileInRect:(NSRect)rect;
- (NSImage *)imageByScalingToSize:(NSSize)size;
- (NSImage *)imageByFadingToFraction:(float)delta;
- (NSImage *)imageByScalingToSize:(NSSize)size fraction:(float)delta;
- (NSImage *)imageByScalingToSize:(NSSize)size fraction:(float)delta flipImage:(BOOL)flipImage proportionally:(BOOL)proportionally;
+ (NSImage *)imageFromGWorld:(GWorldPtr)gWorldPtr;
+ (NSImage *)systemCloseButtonImageForState:(AICloseButtonState)state controlTint:(NSControlTint)inTint;
+ (NSImage *)systemCheckmark;
- (NSRect)drawInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position fraction:(float)fraction;
- (NSRect)rectForDrawingInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position;

@end

//Defined in AppKit.framework
@interface NSImageCell(NSPrivateAnimationSupport)
- (BOOL)_animates;
- (void)_setAnimates:(BOOL)fp8;
- (void)_startAnimation;
- (void)_stopAnimation;
- (void)_animationTimerCallback:fp8;
@end