//
//  JSCEventBezelView.m
//  Adium XCode
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelView.h"
#define IMAGE_DIMENSION             48.0

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
    [self setNeedsDisplay:YES];
}

- (void)dealloc
{
    [backdropImage release];
    [buddyIconImage release];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    NSPoint tempPoint;
    
    [[NSColor clearColor] set];
    NSRectFill([self frame]);
    [backdropImage compositeToPoint: NSZeroPoint operation:NSCompositeSourceOver];
    
    tempPoint.x = 12.0;
    tempPoint.y = 146.0;
    [buddyIconImage compositeToPoint: tempPoint operation:NSCompositeSourceOver];
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

@end
