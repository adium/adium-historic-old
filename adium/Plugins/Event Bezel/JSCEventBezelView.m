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
    backdropImage = [[NSImage alloc] initWithContentsOfFile:
        [[NSBundle bundleForClass:[self class]] pathForResource:@"backdrop" ofType:@"png"]];
    [backdropImage retain];
    
    buddyIconImage = [NSImage imageNamed: @"DefaultIcon"];
    [buddyIconImage setScalesWhenResized:YES];
    [buddyIconImage setSize:NSMakeSize(IMAGE_DIMENSION,IMAGE_DIMENSION)];
    
    defaultBuddyImage = YES;
    
    pantherOrLater = (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2);
    
    if (pantherOrLater) {
        NSSize  shadowSize;
        shadowSize.width = 2.0;
        shadowSize.height = -2.0;
        textShadow = [[NSShadow alloc] init];
        [textShadow retain];
        [textShadow setShadowOffset:shadowSize];
        [textShadow setShadowBlurRadius:2.0];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)dealloc
{
    [backdropImage release];
    [buddyIconImage release];
    [buddyIconBadge release];
    [textShadow release];
    [mainBuddyName release];
    [mainBuddyStatus release];
    [mainAwayMessage release];
    [queueField release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    NSPoint tempPoint;
    NSRect tempRect;
    NSDictionary *mainAttributes;
    NSDictionary *secondaryAttributes;
    
    [[NSColor clearColor] set];
    NSRectFill([self frame]);
    [backdropImage compositeToPoint: NSZeroPoint operation:NSCompositeSourceOver];
    
    tempPoint.x = 12.0;
    tempPoint.y = 146.0;
    [buddyIconImage compositeToPoint: tempPoint operation:NSCompositeSourceOver];
    if (buddyIconBadge) {
        [buddyIconBadge compositeToPoint: tempPoint operation:NSCompositeSourceOver];
    }
    
    // Set the shadow for better readability
    if (pantherOrLater) {
        [textShadow set];
    }
    
    mainAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:0.0] toHaveTrait: NSBoldFontMask], NSFontAttributeName, 
                    [NSColor whiteColor], NSForegroundColorAttributeName, nil];
    secondaryAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, 
                    [NSColor whiteColor], NSForegroundColorAttributeName, nil];
    
    [[NSColor whiteColor] set];
    tempPoint.x = 68.0;
    tempPoint.y = 177.0;
    [mainBuddyName drawAtPoint: tempPoint withAttributes: mainAttributes];
    
    tempPoint.y = 163.0;
    [mainBuddyStatus drawAtPoint: tempPoint withAttributes: secondaryAttributes];
    
    tempPoint.y = 112.0;
    tempRect.size.width = 131.0;
    tempRect.size.height = 43.0;
    tempRect.origin = tempPoint;
    [mainAwayMessage drawInRect: tempRect withAttributes: secondaryAttributes];
    
    tempPoint.x = 12.0;
    tempPoint.y = 12.0;
    tempRect.size.width = 187.0;
    tempRect.size.height = 83.0;
    tempRect.origin = tempPoint;
    [queueField drawInRect: tempRect withAttributes: secondaryAttributes];
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
    [buddyIconBadge release];
    if (![badgeName isEqualToString:@""]) {
        buddyIconBadge = [[NSImage alloc] initWithContentsOfFile:
            [[NSBundle bundleForClass:[self class]] pathForResource:badgeName ofType:@"png"]];
        [buddyIconBadge retain];
    } else {
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

- (NSString *)mainAwayMessage
{
    return mainAwayMessage;
}

- (void)setMainAwayMessage:(NSString *)newString
{
    [newString retain];
    [mainAwayMessage release];
    mainAwayMessage = newString;
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

@end
