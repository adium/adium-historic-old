//
//  JSCEventBezelView.m
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelView.h"
#define ORIGINAL_WIDTH              211.0
#define ORIGINAL_HEIGHT             206.0
#define IMAGE_DIMENSION             48.0

@interface JSCEventBezelView (PRIVATE)
- (NSBezierPath *)bezierPathLabelOfSize:(NSSize)backgroundSize;
@end

@implementation JSCEventBezelView

- (void)awakeFromNib
{
    NSParagraphStyle    *parrafo = [NSParagraphStyle styleWithAlignment:NSCenterTextAlignment];
    
    defaultBuddyImage = NO;
    
    [self setBuddyIconLabelColor: nil];
        
    if ([NSApp isOnPantherOrBetter]) {
        NSSize      shadowSize;
		
		Class NSShadowClass = NSClassFromString(@"NSShadow");
        NSShadow    *textShadow = [[[NSShadowClass alloc] init] autorelease];
		
        shadowSize.width = 0.0;
        shadowSize.height = -2.0;
        [textShadow setShadowOffset:shadowSize];
        [textShadow setShadowBlurRadius:3.0];
        
        // Set the attributes for the main buddy name and the other strings
        mainAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    [NSColor whiteColor], NSForegroundColorAttributeName,
                    textShadow, NSShadowAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
        mainAttributesMask = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    [NSColor darkGrayColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
        secondaryAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSColor whiteColor], NSForegroundColorAttributeName,
                    textShadow, NSShadowAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
        secondaryAttributesMask = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSColor darkGrayColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
        mainStatusAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSColor whiteColor], NSForegroundColorAttributeName,
                    textShadow, NSShadowAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
        mainStatusAttributesMask = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSColor darkGrayColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
    } else {
    
        // Set the attributes for the main buddy name and the other strings
        mainAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    [NSColor whiteColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
        mainAttributesMask = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    [NSColor darkGrayColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
        secondaryAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSColor whiteColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
        secondaryAttributesMask = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSColor darkGrayColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
        mainStatusAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSColor whiteColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
        mainStatusAttributesMask = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [NSColor darkGrayColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
    }
}

- (void)dealloc
{
    [backdropImage release];
    [buddyIconImage release];
    [buddyIconBadge release];
    [mainBuddyName release];
    [mainBuddyStatus release];
    [queueField release];
    [mainAttributes release];
    [mainAttributesMask release];
    [secondaryAttributes release];
    [secondaryAttributesMask release];
    [mainStatusAttributes release];
    [mainStatusAttributesMask release];
    [buddyIconLabelColor release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    NSPoint         buddyIconPoint;
    NSRect          buddyIconLabelRect, buddyNameRect, buddyStatusRect, queueRect;
    NSString        *tempString;
    NSShadow        *tempShadow = nil;
    NSShadow        *noShadow = nil;
    NSSize          buddyNameSize;
    float           buddyNameFontSize = 26.0;
    float           relativeX = 1.0;
    float           relativeY = 1.0;
	NSSize			buddyIconSize;
	BOOL			minFontSize;
	float			accumulator;
        
    // Clear the view and paint the backdrop image
    [[NSColor clearColor] set];
    NSRectFill([self frame]);
    if ((bezelSize.width != ORIGINAL_WIDTH) || (bezelSize.height != ORIGINAL_HEIGHT)) {
        // Calculate the transformations
        relativeX = bezelSize.width / ORIGINAL_WIDTH;
        relativeY = bezelSize.height / ORIGINAL_HEIGHT;
		buddyNameFontSize = floor(buddyNameFontSize*relativeY);
    }   
    [backdropImage setSize: NSMakeSize(bezelSize.width,bezelSize.height)];
    [backdropImage compositeToPoint: NSZeroPoint operation:NSCompositeSourceOver];
    
    // Resize the buddy icon if needed
	buddyIconSize = NSMakeSize(IMAGE_DIMENSION*relativeX,IMAGE_DIMENSION*relativeX);
    
    // Set up the Rects
    if (queueField && (![queueField isEqualToString:@""])) {
        // Buddy Icon Image and label
        buddyIconPoint = NSMakePoint(ceil(82.0*relativeX),ceil(150.0*relativeY));
        buddyIconLabelRect = NSMakeRect(buddyIconPoint.x-2,buddyIconPoint.y-2,buddyIconSize.width+4,buddyIconSize.height+4);
        // Main buddy name
        buddyNameRect = NSMakeRect(ceil(12.0*relativeX),ceil(116.0*relativeY),ceil(187.0*relativeX),ceil(30.0*relativeY));
        // Main buddy Status
        buddyStatusRect = NSMakeRect(ceil(12.0*relativeX),ceil(73.0*relativeY),ceil(187.0*relativeX),ceil(44.0*relativeY));
        // Queue stack
        queueRect = NSMakeRect(ceil(12.0*relativeX),8.0,ceil(187.0*relativeX),ceil(52.0*relativeY));
    } else {
        // Buddy Icon Image and label
        buddyIconPoint = NSMakePoint(ceil(82.0*relativeX),ceil(120.0*relativeY));
        buddyIconLabelRect = NSMakeRect(buddyIconPoint.x-2,buddyIconPoint.y-2,buddyIconSize.width+4,buddyIconSize.height+4);
        // Main buddy name
        buddyNameRect = NSMakeRect(ceil(12.0*relativeX),ceil(80.0*relativeY),ceil(187.0*relativeX),ceil(30.0*relativeY));
        // Main buddy Status
        buddyStatusRect = NSMakeRect(ceil(12.0*relativeX),ceil(37.0*relativeY),ceil(187.0*relativeX),ceil(44.0*relativeY));
        // Queue stack empty, no rect
        queueRect = NSMakeRect(0.0,0.0,0.0,0.0);
    }
    
    
    // Set up the shadow for Panther or later
    if ([NSApp isOnPantherOrBetter]) {
		
		Class NSShadowClass = NSClassFromString(@"NSShadow");
		
        tempShadow = [[[NSShadowClass alloc] init] autorelease];
        noShadow = [[[NSShadowClass alloc] init] autorelease];
		
        NSSize      shadowSize;
        shadowSize.width = 0.0;
        shadowSize.height = -3.0;
        [tempShadow setShadowOffset:shadowSize];
        [tempShadow setShadowBlurRadius:5.0];
        shadowSize.width = 0.0;
        shadowSize.height = 0.0;
        [noShadow setShadowOffset:shadowSize];
        [noShadow setShadowBlurRadius:0.0];
        [tempShadow set];
    }

    // Paint the buddy icon or placeholder
    if (useBuddyIconLabel && buddyIconLabelColor) {
        [buddyIconLabelColor set];
        [NSBezierPath fillRect:buddyIconLabelRect];
	
	if([NSApp isOnPantherOrBetter]) {
            [noShadow set];
        }
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect: NSMakeRect(buddyIconPoint.x, buddyIconPoint.y, 48.0*relativeX,48.0*relativeX)];
    } else {
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect: NSMakeRect(buddyIconPoint.x, buddyIconPoint.y, 48.0*relativeX,48.0*relativeX)];
        if([NSApp isOnPantherOrBetter]) {
            [noShadow set];
        }
    }

	[buddyIconImage drawInRect:NSMakeRect(buddyIconPoint.x, buddyIconPoint.y, buddyIconSize.width, buddyIconSize.height)
					  fromRect:NSMakeRect(0, 0, [buddyIconImage size].width, [buddyIconImage size].height)
					 operation:NSCompositeSourceOver
					  fraction:1.0];
    
	if (buddyIconBadge) {
        [buddyIconBadge compositeToPoint: NSMakePoint(buddyIconPoint.x -6.0, buddyIconPoint.y - 6-0) operation:NSCompositeSourceOver];
    }
	
    [mainAttributes setObject:[[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:buddyNameFontSize] toHaveTrait: NSBoldFontMask] forKey:NSFontAttributeName];
    buddyNameSize = [mainBuddyName sizeWithAttributes: mainAttributes];
    
	minFontSize = NO;
	accumulator = 0.0;
    while(buddyNameSize.width > ((187.0*relativeX) - (buddyNameSize.height / 2.0))) {
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
		[self setMainBuddyName: [NSString stringWithFormat:@"%@É",[mainBuddyName substringToIndex: [mainBuddyName length]-1]]];
	}
	[mainAttributesMask setObject:[[NSFontManager sharedFontManager] 
		convertFont:[NSFont systemFontOfSize:buddyNameFontSize] toHaveTrait: NSBoldFontMask] forKey:NSFontAttributeName];
    
    buddyNameRect.size.height = buddyNameSize.height;
    
    // Paint the main name label if selected, and the strings
	NSRect  labelRect;
	int     maxWidth = (187.0*relativeX);
	if (buddyNameSize.width > maxWidth) {
		labelRect = NSMakeRect(12.0,buddyNameRect.origin.y,maxWidth,buddyNameSize.height-3.0);
	} else {
		labelRect = NSMakeRect(106.0*relativeX - (buddyNameSize.width / 2.0) - (buddyNameSize.height / 2.0),buddyNameRect.origin.y,buddyNameSize.width + buddyNameSize.height,buddyNameSize.height-3.0);
	}
		
    if (useBuddyNameLabel && buddyIconLabelColor) {
        [buddyIconLabelColor set];
    } else {
		[[[NSColor blackColor] colorWithAlphaComponent:0.3] set];
	}
	NSBezierPath *labelPath = [self bezierPathLabelOfSize:labelRect.size];
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy:labelRect.origin.x yBy:labelRect.origin.y];
	[labelPath transformUsingAffineTransform: transform];
	[labelPath fill];

    if (useBuddyNameLabel && buddyNameLabelColor) {
        [mainAttributes setObject: buddyNameLabelColor forKey:NSForegroundColorAttributeName];
    } else {
        [mainAttributes setObject: [NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    }
    
    tempString = [NSString stringWithString: mainBuddyName];
    [tempString drawInRect: NSMakeRect(buddyNameRect.origin.x + 1.0, buddyNameRect.origin.y - 1.0, buddyNameRect.size.width, buddyNameRect.size.height) withAttributes: mainAttributesMask];
    [mainBuddyName drawInRect: buddyNameRect withAttributes: mainAttributes];
    
    [mainStatusAttributes setObject:[NSFont systemFontOfSize:18.0*relativeX] forKey:NSFontAttributeName];
    [mainStatusAttributesMask setObject:[NSFont systemFontOfSize:18.0*relativeX] forKey:NSFontAttributeName];
    
    tempString = [NSString stringWithString: mainBuddyStatus];
    [tempString drawInRect: NSMakeRect(buddyStatusRect.origin.x + 1.0,buddyStatusRect.origin.y - 1.0, buddyStatusRect.size.width, buddyStatusRect.size.height) withAttributes: mainStatusAttributesMask];
    [mainBuddyStatus drawInRect: buddyStatusRect withAttributes: mainStatusAttributes];
    
    if (queueField && (![queueField isEqualToString:@""])) {
        // Paint the divider line
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect:NSMakeRect(12.0,66.0*relativeY,187.0*relativeX,1.0)];

        [secondaryAttributes setObject:[NSFont systemFontOfSize:14.0*relativeX] forKey:NSFontAttributeName];
        [secondaryAttributesMask setObject:[NSFont systemFontOfSize:14.0*relativeX] forKey:NSFontAttributeName];

        tempString = [NSString stringWithString: queueField];
        [tempString drawInRect: NSMakeRect(queueRect.origin.x + 1.0,queueRect.origin.y - 1.0, queueRect.size.width, queueRect.size.height) withAttributes: secondaryAttributesMask];
        [queueField drawInRect: queueRect withAttributes: secondaryAttributes];
    }
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
        defaultBuddyImage = NO;
    } else if (!defaultBuddyImage){
        [buddyIconImage release];
        buddyIconImage = [[NSImage imageNamed: @"DefaultIcon"] retain];
        // set the flag so we don't load the default icon innecesary
        defaultBuddyImage = YES;
    }
//    [buddyIconImage setScalesWhenResized:YES];
//    [buddyIconImage setSize:NSMakeSize(IMAGE_DIMENSION,IMAGE_DIMENSION)];
}

- (NSImage *)buddyIconBadge
{
    return buddyIconBadge;
}

- (void)setBuddyIconBadgeType:(NSString *)badgeName
{
    if (![badgeName isEqualToString:@""]) {
        NSImage     *tempImage;
        
        tempImage = [[AIImageUtilities imageNamed:badgeName forClass:[self class]] retain];
        //tempImage = [[NSImage alloc] initWithContentsOfFile:
        //    [[NSBundle bundleForClass:[self class]] pathForResource:badgeName ofType:@"png"]];
        [buddyIconBadge release];
        buddyIconBadge = tempImage;
    } else {
        [buddyIconBadge release];
        buddyIconBadge = nil;
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

- (NSString *)queueField
{
    return queueField;
}

- (void)setQueueField:(NSString *)newString
{
    [newString retain];
    [queueField release];
    queueField = newString;
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

- (BOOL)useBuddyIconLabel
{
    return useBuddyIconLabel;
}

- (void)setUseBuddyIconLabel:(BOOL)b
{
    useBuddyIconLabel = b;
}

- (BOOL)useBuddyNameLabel
{
    return useBuddyNameLabel;
}

- (void)setUseBuddyNameLabel:(BOOL)b
{
    useBuddyNameLabel = b;
}

- (NSSize)bezelSize
{
    return bezelSize;
}

- (void)setBezelSize:(NSSize)newSize
{
    bezelSize = newSize;
}

- (NSImage *)backdropImage
{
    return backdropImage;
}

- (void)setBackdropImage:(NSImage *)newImage
{
    [newImage retain];
    [backdropImage release];
    backdropImage = newImage;
    [backdropImage setScalesWhenResized:YES];
}

//Returns a bezier path for our label
- (NSBezierPath *)bezierPathLabelOfSize:(NSSize)backgroundSize
{
	int 		innerLeft, innerRight, innerTop, innerBottom;
	float 		centerY, circleRadius;
	NSBezierPath	*pillPath;
    
	//Calculate some points
	circleRadius = backgroundSize.height / 2.0;
	innerTop = 0;
	innerBottom = backgroundSize.height;
	centerY = (innerTop + innerBottom) / 2.0;

	//Conpensate for our rounded caps
	innerLeft = circleRadius;
	innerRight = backgroundSize.width - circleRadius;

	//Create the circle path
	pillPath = [NSBezierPath bezierPath];
	[pillPath moveToPoint: NSMakePoint(innerLeft, innerTop)];
	[pillPath lineToPoint: NSMakePoint(innerRight, innerTop)];
	[pillPath appendBezierPathWithArcWithCenter:NSMakePoint(innerRight, centerY)
										 radius:circleRadius
									 startAngle:270
									   endAngle:90
									  clockwise:NO];
	[pillPath lineToPoint: NSMakePoint(innerLeft, innerBottom)];
	[pillPath appendBezierPathWithArcWithCenter:NSMakePoint(innerLeft, centerY)
										 radius:circleRadius
									 startAngle:90
									   endAngle:270
									  clockwise:NO];
	
	return(pillPath);
}

@end
