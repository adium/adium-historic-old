//
//  JSCEventBezelView.m
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelView.h"
#define IMAGE_DIMENSION             48.0

BOOL pantherOrLater;

@implementation JSCEventBezelView

- (void)awakeFromNib
{
    NSParagraphStyle    *parrafo = [NSParagraphStyle styleWithAlignment:NSCenterTextAlignment];
    NSShadow		*textShadow = nil;
    
    backdropImage = [[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForResource:@"backdrop" ofType:@"png"]];
    
    buddyIconImage = [NSImage imageNamed: @"DefaultIcon"];
    [buddyIconImage setScalesWhenResized:YES];
    [buddyIconImage setSize:NSMakeSize(IMAGE_DIMENSION,IMAGE_DIMENSION)];
    
    [self setBuddyIconLabelColor: nil];
    
    defaultBuddyImage = YES;
    
    pantherOrLater = (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2);
    
    if (pantherOrLater) {
        NSSize      shadowSize;
        textShadow = [[[NSShadow alloc] init] autorelease];
        shadowSize.width = 0.0;
        shadowSize.height = -2.0;
        [textShadow setShadowOffset:shadowSize];
        [textShadow setShadowBlurRadius:3.0];
    }
    
    // Set the attributes for the main buddy name and the other strings
    mainAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:24.0] toHaveTrait: NSBoldFontMask], NSFontAttributeName, 
                    [NSColor whiteColor], NSForegroundColorAttributeName,
                    textShadow, NSShadowAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
    mainAttributesMask = [[NSMutableDictionary dictionaryWithObjectsAndKeys: [[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:24.0] toHaveTrait: NSBoldFontMask], NSFontAttributeName, 
                    [NSColor darkGrayColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
    secondaryAttributes = [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:14.0], NSFontAttributeName, 
                    [NSColor whiteColor], NSForegroundColorAttributeName,
                    textShadow, NSShadowAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
    secondaryAttributesMask = [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:14.0], NSFontAttributeName, 
                    [NSColor darkGrayColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
    mainStatusAttributes = [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:18.0], NSFontAttributeName, 
                    [NSColor whiteColor], NSForegroundColorAttributeName,
                    textShadow, NSShadowAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
    mainStatusAttributesMask = [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:18.0], NSFontAttributeName, 
                    [NSColor darkGrayColor], NSForegroundColorAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
    
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
    NSShadow        *tempShadow = [[[NSShadow alloc] init] autorelease];
    NSShadow        *noShadow = [[[NSShadow alloc] init] autorelease];
    NSSize          buddyNameSize;
    float           buddyNameFontSize = 24.0;
    
    // Clear the view and paint the backdrop image
    [[NSColor clearColor] set];
    NSRectFill([self frame]);
    [backdropImage compositeToPoint: NSZeroPoint operation:NSCompositeSourceOver];
        
    // Set up the Rects
    if (queueField && (![queueField isEqualToString:@""])) {
        // Buddy Icon Image and label
        buddyIconPoint = NSMakePoint(82.0,150.0);
        buddyIconLabelRect = NSMakeRect(80.0,148.0,52.0,52.0);
        // Main buddy name
        buddyNameRect = NSMakeRect(12.0,116.0,187.0,30.0);
        // Main buddy Status
        buddyStatusRect = NSMakeRect(12.0,73.0,187.0,44.0);
        // Queue stack
        queueRect = NSMakeRect(12.0,8.0,187.0,52.0);
    } else {
        // Buddy Icon Image and label
        buddyIconPoint = NSMakePoint(82.0,120.0);
        buddyIconLabelRect = NSMakeRect(80.0,118.0,52.0,52.0);
        // Main buddy name
        buddyNameRect = NSMakeRect(12.0,80.0,187.0,30.0);
        // Main buddy Status
        buddyStatusRect = NSMakeRect(12.0,37.0,187.0,44.0);
        // Queue stack empty, no rect
        queueRect = NSMakeRect(0.0,0.0,0.0,0.0);
    }
    
    
    // Set up the shadow for Panther or later
    if (pantherOrLater) {
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
	
	if(pantherOrLater) {
            [noShadow set];
        }
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect: NSMakeRect(buddyIconPoint.x, buddyIconPoint.y, 48.0,48.0)];
    } else {
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect: NSMakeRect(buddyIconPoint.x, buddyIconPoint.y, 48.0,48.0)];
        if(pantherOrLater) {
            [noShadow set];
        }
    }
    [buddyIconImage compositeToPoint: buddyIconPoint operation:NSCompositeSourceOver];
    if (buddyIconBadge) {
        [buddyIconBadge compositeToPoint: NSMakePoint(buddyIconPoint.x -6.0, buddyIconPoint.y - 6-0) operation:NSCompositeSourceOver];
    }
    
    
    [mainAttributes setObject:[[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:24.0] toHaveTrait: NSBoldFontMask] forKey:NSFontAttributeName];
    [mainAttributesMask setObject:[[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:24.0] toHaveTrait: NSBoldFontMask] forKey:NSFontAttributeName];
    buddyNameSize = [mainBuddyName sizeWithAttributes: mainAttributes];
    
    while (buddyNameSize.width > (187.0 - (buddyNameSize.height / 2.0))) {
        buddyNameFontSize-= 1.0;
        [mainAttributes setObject:[[NSFontManager sharedFontManager] 
            convertFont:[NSFont systemFontOfSize:buddyNameFontSize] toHaveTrait: NSBoldFontMask] forKey:NSFontAttributeName];
        [mainAttributesMask setObject:[[NSFontManager sharedFontManager] 
            convertFont:[NSFont systemFontOfSize:buddyNameFontSize] toHaveTrait: NSBoldFontMask] forKey:NSFontAttributeName];
        buddyNameSize = [mainBuddyName sizeWithAttributes: mainAttributes];
    }
    
    buddyNameRect.size.height = buddyNameSize.height;
    
    // Paint the main name label if selected, and the strings
    if (useBuddyNameLabel && buddyIconLabelColor) {
        NSRect  labelRect;
        int     borderWidth = (buddyNameSize.height / 2.0);
        int     maxWidth = (187.0 - buddyNameSize.height);
        if (buddyNameSize.width > maxWidth) {
            labelRect = NSMakeRect(12.0 + borderWidth,buddyNameRect.origin.y-2.0,maxWidth,buddyNameSize.height);
        } else {
            labelRect = NSMakeRect(106.0 - (buddyNameSize.width / 2.0),buddyNameRect.origin.y-2.0,buddyNameSize.width,buddyNameSize.height);
        }
        [buddyIconLabelColor set];
        [NSBezierPath fillRect: labelRect];
        [[NSBezierPath bezierPathWithOvalInRect: NSMakeRect(labelRect.origin.x - (labelRect.size.height / 2.0),labelRect.origin.y,labelRect.size.height,labelRect.size.height)] fill];
        [[NSBezierPath bezierPathWithOvalInRect: NSMakeRect(labelRect.origin.x + labelRect.size.width - (labelRect.size.height / 2.0),labelRect.origin.y,labelRect.size.height,labelRect.size.height)] fill];
    }
    if (useBuddyNameLabel && buddyNameLabelColor) {
        [mainAttributes setObject: buddyNameLabelColor forKey:NSForegroundColorAttributeName];
    } else {
        [mainAttributes setObject: [NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    }
    
    tempString = [NSString stringWithString: mainBuddyName];
    [tempString drawInRect: NSMakeRect(buddyNameRect.origin.x + 1.0, buddyNameRect.origin.y - 1.0, buddyNameRect.size.width, buddyNameRect.size.height) withAttributes: mainAttributesMask];
    [mainBuddyName drawInRect: buddyNameRect withAttributes: mainAttributes];
    
    tempString = [NSString stringWithString: mainBuddyStatus];
    [tempString drawInRect: NSMakeRect(buddyStatusRect.origin.x + 1.0,buddyStatusRect.origin.y - 1.0, buddyStatusRect.size.width, buddyStatusRect.size.height) withAttributes: mainStatusAttributesMask];
    [mainBuddyStatus drawInRect: buddyStatusRect withAttributes: mainStatusAttributes];
    
    if (queueField && (![queueField isEqualToString:@""])) {
        // Paint the divider line
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect:NSMakeRect(12.0,66.0,187.0,1.0)];
        
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
        //[buddyIconImage setFrameSize:NSMakeSize(IMAGE_DIMENSION,IMAGE_DIMENSION)];
        [buddyIconImage setScalesWhenResized:YES];
        [buddyIconImage setSize:NSMakeSize(IMAGE_DIMENSION,IMAGE_DIMENSION)];
        defaultBuddyImage = NO;
    } else if (!defaultBuddyImage){
        [buddyIconImage release];
        buddyIconImage = [NSImage imageNamed: @"DefaultIcon"];
        // set the flag so we don't load the default icon innecesary
        defaultBuddyImage = YES;
    }
}

- (NSImage *)buddyIconBadge
{
    return buddyIconBadge;
}

- (void)setBuddyIconBadgeType:(NSString *)badgeName
{
    if (![badgeName isEqualToString:@""]) {
        NSImage     *tempImage;
        
        tempImage = [[NSImage alloc] initWithContentsOfFile:
            [[NSBundle bundleForClass:[self class]] pathForResource:badgeName ofType:@"png"]];
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

@end
