//
//  ESFloater.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Oct 08 2003.//

#import "ESFloater.h"

/*
 Create a temporary floating window with an animated image
 */

@interface ESFloater (PRIVATE)
- (id)initWithImage:(NSImage *)inImage at:(NSPoint)inPoint;
@end

@implementation ESFloater

+ (id)floaterWithImage:(NSImage *)inImage at:(NSPoint)inPoint;
{
    return([[self alloc] initWithImage:inImage at:inPoint]);
}

- (id)initWithImage:(NSImage *)inImage at:(NSPoint)inPoint
{
    NSRect  frame;
    
    [self init];
    
    //Set up the panel
    frame = NSMakeRect(0, 0, [inImage size].width, [inImage size].height);    
    panel = [[NSPanel alloc] initWithContentRect:frame
                                       styleMask:NSBorderlessWindowMask
                                         backing:NSBackingStoreBuffered
                                           defer:NO];

    [panel setHidesOnDeactivate:NO];
    [panel setLevel:NSStatusWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    //Setup the animated view
    staticView = [[ESStaticView alloc] initWithFrame:frame image:inImage];
    [[panel contentView] addSubview:[staticView autorelease]];
    
    [panel setFrameOrigin:inPoint];
    [panel makeKeyAndOrderFront:nil];
    [panel setFrameOrigin:inPoint];
    
    [staticView setNeedsDisplay:YES];
    [panel display];
    
    return(self);
}

- (void)moveFloaterToPoint:(NSPoint)inPoint
{
    [panel setFrameOrigin:inPoint];
    [panel display];
}

- (void)setImage:(NSImage *)inImage
{
    NSRect frame = [panel frame];
    frame.size = NSMakeSize([inImage size].width, [inImage size].height);
    [staticView setImage:inImage];
    [panel setFrame:frame display:YES animate:YES];
}

- (NSImage *)image
{
    return [staticView image];
}

- (void)endFloater
{
    [self close:nil];   
}

- (void)dealloc
{
    [super dealloc];
}

- (IBAction)close:(id)sender
{
    [panel orderOut:nil];
    [panel release];
    
    [self release];
}


@end
