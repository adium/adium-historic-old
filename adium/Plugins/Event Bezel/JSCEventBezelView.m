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
        [textShadow setShadowBlurRadius:3.0];
    }
    
    // Set the attributes for the main buddy name and the other strings
    mainAttributes = [[NSDictionary dictionaryWithObjectsAndKeys: [[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:18.0] toHaveTrait: NSBoldFontMask], NSFontAttributeName, 
                    [NSColor whiteColor], NSForegroundColorAttributeName, nil] retain];
    mainAttributesMask = [[NSDictionary dictionaryWithObjectsAndKeys: [[NSFontManager sharedFontManager] 
        convertFont:[NSFont systemFontOfSize:18.0] toHaveTrait: NSBoldFontMask], NSFontAttributeName, 
                    [NSColor darkGrayColor], NSForegroundColorAttributeName, nil] retain];
    secondaryAttributes = [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, 
                    [NSColor whiteColor], NSForegroundColorAttributeName, nil] retain];
    secondaryAttributesMask = [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, 
                    [NSColor darkGrayColor], NSForegroundColorAttributeName, nil] retain];
    mainStatusAttributes = [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:14.0], NSFontAttributeName, 
                    [NSColor whiteColor], NSForegroundColorAttributeName, nil] retain];
    mainStatusAttributesMask = [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:14.0], NSFontAttributeName, 
                    [NSColor darkGrayColor], NSForegroundColorAttributeName, nil] retain];
    
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
    [mainAttributes release];
    [mainAttributesMask release];
    [secondaryAttributes release];
    [secondaryAttributesMask release];
    [mainStatusAttributes release];
    [mainStatusAttributesMask release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    NSPoint         tempPoint;
    NSRect          tempRect;
    NSString        *tempString;
    
    // Clear the view and paint the backdrop image
    [[NSColor clearColor] set];
    NSRectFill([self frame]);
    [backdropImage compositeToPoint: NSZeroPoint operation:NSCompositeSourceOver];
    
    // Paint the buddy icon or placeholder
    tempPoint.x = 12.0;
    tempPoint.y = 114.0;
    [buddyIconImage compositeToPoint: tempPoint operation:NSCompositeSourceOver];
    if (buddyIconBadge) {
        [buddyIconBadge compositeToPoint: tempPoint operation:NSCompositeSourceOver];
    }
    
    // Set the shadow for better readability in Panther
    if (pantherOrLater) {
        [textShadow set];
    }
    
    // Set the color of text to white and paint all the strings,
    
    tempPoint.y = 167.0;
    tempString = [NSString stringWithString: mainBuddyName];
    [tempString drawAtPoint: NSMakePoint(tempPoint.x + 1.0,tempPoint.y - 1.0) withAttributes: mainAttributesMask];
    [mainBuddyName drawAtPoint: tempPoint withAttributes: mainAttributes];
    tempPoint.x = 68.0;
    tempPoint.y = 146.0;
    tempString = [NSString stringWithString: mainBuddyStatus];
    [tempString drawAtPoint: NSMakePoint(tempPoint.x + 1.0,tempPoint.y - 1.0) withAttributes: mainStatusAttributesMask];
    [mainBuddyStatus drawAtPoint: tempPoint withAttributes: mainStatusAttributes];
    
    tempPoint.y = 112.0;
    tempRect.size.width = 131.0;
    tempRect.size.height = 33.0;
    tempRect.origin = tempPoint;
    //[self setMainAwayMessage: @"test status message string placeholder."];
    tempString = [NSString stringWithString: mainAwayMessage];
    [tempString drawInRect: NSMakeRect(tempPoint.x + 1.0,tempPoint.y - 1.0, tempRect.size.width, tempRect.size.height) withAttributes: secondaryAttributesMask];
    [mainAwayMessage drawInRect: tempRect withAttributes: secondaryAttributes];
    
    tempPoint.x = 12.0;
    tempPoint.y = 12.0;
    tempRect.size.width = 187.0;
    tempRect.size.height = 83.0;
    tempRect.origin = tempPoint;
    tempString = [NSString stringWithString: queueField];
    [tempString drawInRect: NSMakeRect(tempPoint.x + 1.0,tempPoint.y - 1.0, tempRect.size.width, tempRect.size.height) withAttributes: secondaryAttributesMask];
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
