//
//  JSCEventBezelView.m
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelView.h"
#define BEZEL_SIZE					160.0
#define OUTER_BORDER				4.0
#define BORDER_RADIUS				20.0
#define IMAGE_DIMENSION             48.0

#define ELIPSIS_STRING				AILocalizedString(@"...",nil)

@implementation JSCEventBezelView

- (void)awakeFromNib
{
	float   innerSize;
	NSBezierPath	*tempPath;
    NSParagraphStyle    *parrafo = [NSParagraphStyle styleWithAlignment:NSCenterTextAlignment];
	NSPoint			localPoint;
	NSRect			bezelRect = NSMakeRect(0.0,0.0,BEZEL_SIZE,BEZEL_SIZE);
	
	ignoringClicks = NO;
	useGradient = NO;
	drawBorder = NO;
	
	// Set the attributes for the main buddy name and the other strings
	mainAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName, nil] retain];
	mainStatusAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSColor whiteColor], NSForegroundColorAttributeName,
				parrafo, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:14.0], NSFontAttributeName, nil] retain];

	innerSize = BEZEL_SIZE - (OUTER_BORDER*2.0);	
	tempPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(OUTER_BORDER,OUTER_BORDER,innerSize,innerSize) radius:(BORDER_RADIUS - OUTER_BORDER)];
	backgroundContent = [[NSBezierPath bezierPathWithRoundedRect:bezelRect radius:BORDER_RADIUS] retain];
	backgroundBorder = [[NSBezierPath bezierPath] retain];
	[backgroundBorder appendBezierPath: [tempPath bezierPathByReversingPath]];
	[backgroundBorder appendBezierPath: backgroundContent];
	//Local mouse location
	localPoint = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
	localPoint = [self convertPoint:localPoint fromView:nil];
	[self addTrackingRect:bezelRect owner:self userData: nil assumeInside:NSPointInRect(localPoint,bezelRect)]; 
}

- (void)dealloc
{
    [buddyIconImage release];
    [mainBuddyName release];
    [mainBuddyStatus release];
    [mainAttributes release];
    [mainStatusAttributes release];
    [buddyIconLabelColor release];
	[backgroundBorder release];
	[backgroundContent release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    NSPoint         buddyIconPoint;
    NSRect          buddyNameRect, buddyStatusRect;
    NSSize          buddyNameSize;
    float           buddyNameFontSize = 20.0;
	NSSize			buddyIconSize;
	BOOL			minFontSize;
	float			accumulator;
	NSPoint			localPoint;	

	//Local mouse location	
	localPoint = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
	localPoint = [self convertPoint:localPoint fromView:nil];
    // Clear the view
    [[NSColor clearColor] set];
    NSRectFill([self frame]);
	// Paint the colored background
	if (ignoringClicks) {
		// Paint the transparent colored background
		[[NSColor colorWithCalibratedRed: [buddyIconLabelColor redComponent]
			green: [buddyIconLabelColor greenComponent]
			blue: [buddyIconLabelColor blueComponent]
			alpha: 0.8] set];
		[backgroundContent fill];
	} else {
		// Paint the opaque colored background
		if (useGradient) {
			[[AIGradient gradientWithFirstColor:[buddyIconLabelColor darkenAndAdjustSaturationBy:0.4] secondColor:buddyIconLabelColor direction:AIVertical] drawInBezierPath:backgroundContent];
		} else {
			[buddyIconLabelColor set];
			[backgroundContent fill];
		}
	}
	if (!ignoringClicks && (drawBorder || NSPointInRect(localPoint,NSMakeRect(0.0,0.0,BEZEL_SIZE,BEZEL_SIZE)))) {
		// Paint the white border
		[[NSColor whiteColor] set];
		[backgroundBorder fill];
	}
	
    // Resize the buddy icon if needed
	buddyIconSize = NSMakeSize(IMAGE_DIMENSION,IMAGE_DIMENSION);
    
    // Set up the Rects
	// Buddy Icon Image and label
	buddyIconPoint = NSMakePoint(57.0,83.0);
	// Main buddy name
	buddyNameRect = NSMakeRect(8.0,52.0,143.0,24.0);
	// Main buddy Status
	buddyStatusRect = NSMakeRect(8.0,19.0,143.0,34);
    
	[buddyIconImage drawInRect:NSMakeRect(buddyIconPoint.x, buddyIconPoint.y, buddyIconSize.width, buddyIconSize.height)
					  fromRect:NSMakeRect(0, 0, [buddyIconImage size].width, [buddyIconImage size].height)
					 operation:NSCompositeSourceOver
					  fraction:1.0];

    [mainAttributes setObject:[[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:buddyNameFontSize] toHaveTrait: NSBoldFontMask] forKey:NSFontAttributeName];
    buddyNameSize = [mainBuddyName sizeWithAttributes: mainAttributes];
    
	minFontSize = NO;
	accumulator = 0.0;
    while(buddyNameSize.width > (143.0 - (buddyNameSize.height / 2.0))) {
		minFontSize = (buddyNameFontSize<=12.0);
		if (minFontSize) {
			[self setMainBuddyName: [mainBuddyName substringToIndex: [mainBuddyName length]-1]];
		} else {
			buddyNameFontSize -= 1.0;
			accumulator += 0.5;
		}
		[mainAttributes setObject:[[NSFontManager sharedFontManager] 
			convertFont:[NSFont systemFontOfSize:buddyNameFontSize] toHaveTrait: NSBoldFontMask] forKey:NSFontAttributeName];
		buddyNameSize = [mainBuddyName sizeWithAttributes: mainAttributes];
    }
	buddyNameRect.origin.y += ceil(accumulator);
	if (minFontSize) {
		[self setMainBuddyName: [NSString stringWithFormat:@"%@%@",[mainBuddyName substringToIndex: [mainBuddyName length]-1], ELIPSIS_STRING]];
	}
    
    buddyNameRect.size.height = buddyNameSize.height;
    
	[mainAttributes setObject: buddyNameLabelColor forKey:NSForegroundColorAttributeName];
	[mainStatusAttributes setObject: buddyNameLabelColor forKey:NSForegroundColorAttributeName];
	
    [mainBuddyName drawInRect: buddyNameRect withAttributes: mainAttributes];
        
    [mainBuddyStatus drawInRect: buddyStatusRect withAttributes: mainStatusAttributes];
}

- (NSImage *)buddyIconImage
{
    return buddyIconImage;
}

- (void)setBuddyIconImage:(NSImage *)newImage
{
    if (newImage) {
        [newImage retain];
        [buddyIconImage release];
        buddyIconImage = newImage;
    }
}

- (NSString *)mainBuddyName
{
    return mainBuddyName;
}

- (void)setMainBuddyName:(NSString *)newString
{
    [newString retain];
    [mainBuddyName release];
    mainBuddyName = newString;
}

- (NSString *)mainBuddyStatus
{
    return mainBuddyStatus;
}

- (void)setMainBuddyStatus:(NSString *)newString
{
    [newString retain];
    [mainBuddyStatus release];
    mainBuddyStatus = newString;
}

- (NSColor *)buddyIconLabelColor
{
    return buddyIconLabelColor;
}

- (void)setBuddyIconLabelColor:(NSColor *)newColor
{
    [newColor retain];
    [buddyIconLabelColor release];
    buddyIconLabelColor = newColor;
}

- (NSColor *)buddyNameLabelColor
{
    return buddyNameLabelColor;
}

- (void)setBuddyNameLabelColor:(NSColor *)newColor
{
    [newColor retain];
    [buddyNameLabelColor release];
    buddyNameLabelColor = newColor;
}

- (BOOL)ignoringClicks
{
	return ignoringClicks;
}

- (void)setIgnoringClicks:(BOOL)ignoreClicks
{
	ignoringClicks = ignoreClicks;
}

- (BOOL)useGradient
{
	return useGradient;
}

- (void)setUseGradient:(BOOL)newValue
{
	useGradient = newValue;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	drawBorder = YES;
	[self setNeedsDisplay: YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	drawBorder = NO;
	[self setNeedsDisplay: YES];
}

@end
