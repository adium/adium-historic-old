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
    NSMutableParagraphStyle     *parrafo = [[[NSMutableParagraphStyle alloc] init] autorelease];
    NSShadow    *textShadow = nil;
    
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
    [parrafo setAlignment: NSCenterTextAlignment];
    
    mainAttributes = [[NSDictionary dictionaryWithObjectsAndKeys: [[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:24.0] toHaveTrait: NSBoldFontMask], NSFontAttributeName, 
                    [NSColor whiteColor], NSForegroundColorAttributeName,
                    textShadow, NSShadowAttributeName,
                    parrafo, NSParagraphStyleAttributeName, nil] retain];
    mainAttributesMask = [[NSDictionary dictionaryWithObjectsAndKeys: [[NSFontManager sharedFontManager] 
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
    NSPoint         tempPoint;
    NSRect          tempRect;
    NSString        *tempString;
    NSShadow        *tempShadow;
    
    // Clear the view and paint the backdrop image
    [[NSColor clearColor] set];
    NSRectFill([self frame]);
    [backdropImage compositeToPoint: NSZeroPoint operation:NSCompositeSourceOver];
    
    if (pantherOrLater) {
        NSSize      shadowSize;
        tempShadow = [[[NSShadow alloc] init] autorelease];
        shadowSize.width = 0.0;
        shadowSize.height = -3.0;
        [tempShadow setShadowOffset:shadowSize];
        [tempShadow setShadowBlurRadius:5.0];
        [tempShadow set];
    }
        
    // Paint the buddy icon or placeholder
    if (buddyIconLabelColor) {
        tempPoint.x = 80.0;
        tempPoint.y = 148.0;
        tempRect.size.width = 52.0;
        tempRect.size.height = 52.0;
        tempRect.origin = tempPoint;
        [buddyIconLabelColor set];
        [NSBezierPath fillRect:tempRect];
    }
    tempPoint.x = 82.0;
    tempPoint.y = 150.0;
    [buddyIconImage compositeToPoint: tempPoint operation:NSCompositeSourceOver];
    if (buddyIconBadge) {
        [buddyIconBadge compositeToPoint: tempPoint operation:NSCompositeSourceOver];
    }
            
    // Set the color of text to white and paint all the strings,
    tempPoint.x = 12.0;
    tempPoint.y = 116.0;
    tempRect.size.width = 187.0;
    tempRect.size.height = 30.0;
    tempRect.origin = tempPoint;
    tempString = [NSString stringWithString: mainBuddyName];
    [tempString drawInRect: NSMakeRect(tempPoint.x + 1.0,tempPoint.y - 1.0, tempRect.size.width, tempRect.size.height) withAttributes: mainAttributesMask];
    [mainBuddyName drawInRect: tempRect withAttributes: mainAttributes];
    
    tempPoint.y = 73.0;
    tempRect.size.height = 44.0;
    tempRect.origin = tempPoint;
    tempString = [NSString stringWithString: mainBuddyStatus];
    [tempString drawInRect: NSMakeRect(tempPoint.x + 1.0,tempPoint.y - 1.0, tempRect.size.width, tempRect.size.height) withAttributes: mainStatusAttributesMask];
    [mainBuddyStatus drawInRect: tempRect withAttributes: mainStatusAttributes];
    
    if (queueField && (![queueField isEqualToString:@""])) {
        // Paint the divider line
        tempPoint.x = 12.0;
        tempPoint.y = 66.0;
        tempRect.size.width = 187.0;
        tempRect.size.height = 1.0;
        tempRect.origin = tempPoint;
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect:tempRect];
        
        tempPoint.y = 8.0;
        tempRect.size.height = 52.0;
        tempRect.origin = tempPoint;
        tempString = [NSString stringWithString: queueField];
        [tempString drawInRect: NSMakeRect(tempPoint.x + 1.0,tempPoint.y - 1.0, tempRect.size.width, tempRect.size.height) withAttributes: secondaryAttributesMask];
        [queueField drawInRect: tempRect withAttributes: secondaryAttributes];
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

@end
