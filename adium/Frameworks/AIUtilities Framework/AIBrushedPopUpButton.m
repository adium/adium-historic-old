//
//  AIBrushedPopUpButton.m
//  Adium
//
//  Created by Adam Iser on Fri Jul 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIBrushedPopUpButton.h"
#import <AIUtilities/AIUtilities.h>

#define TRIANGLE_PADDING_X 	3
#define TRIANGLE_OFFSET_Y 	7
#define LABEL_OFFSET_Y 		2
#define BACK_OFFSET_Y		4

@interface AIBrushedPopUpButton (PRIVATE)
- (void)stopTrackingCursor;
- (void)startTrackingCursor;
@end

@implementation AIBrushedPopUpButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];

    //Preload some images
    popUpRolloverCaps = [[AIImageUtilities imageNamed:@"PopUpRollover_Caps" forClass:[self class]] retain];
    popUpRolloverMiddle = [[AIImageUtilities imageNamed:@"PopUpRollover_Middle" forClass:[self class]] retain];
    popUpPressedCaps = [[AIImageUtilities imageNamed:@"PopUpPressed_Caps" forClass:[self class]] retain];
    popUpPressedMiddle = [[AIImageUtilities imageNamed:@"PopUpPressed_Middle" forClass:[self class]] retain];
    popUpTriangle = [[AIImageUtilities imageNamed:@"PopUpArrow" forClass:[self class]] retain];
    popUpTriangleWhite = [[AIImageUtilities imageNamed:@"PopUpArrowWhite" forClass:[self class]] retain];

    //
    mouseIn = NO;
    trackingTag = 0;

    return(self);    
}

- (void)dealloc
{
    //
    [popUpRolloverCaps release];
    [popUpRolloverMiddle release];
    [popUpPressedCaps release];
    [popUpPressedMiddle release];
    [popUpTriangle release];
    [popUpTriangleWhite release];

    [super dealloc];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    //If we're being removed from the window, we need to remove our tracking rects
    if(newWindow == nil){
        [self stopTrackingCursor];
    }
}

- (void)sizeToFit
{
    NSDictionary	*textAttributes;
    NSString		*title;
    NSFont		*font;
    NSRect		frame;
    
    font = [NSFont boldSystemFontOfSize:11];
    title = [self titleOfSelectedItem];

    textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];

    frame = [self frame];
    [[self superview] setNeedsDisplayInRect:frame];
    
    frame.size.width = [title sizeWithAttributes:textAttributes].width + TRIANGLE_PADDING_X + [popUpTriangle size].width + [popUpRolloverCaps size].width;
    [self setFrame:frame];
}

- (void)drawRect:(NSRect)rect
{
    NSDictionary	*textAttributes, *bezelAttributes;
    NSColor		*textColor, *bezelColor;
    NSString		*title;
    NSImage		*triangle;
    NSFont		*font;
    int			contentRight, labelWidth;
    NSImage		*caps, *middle;
    NSRect 		frame, sourceRect, destRect;
    int 		capWidth, capHeight;

    //Get the font and displayed string
    font = [NSFont boldSystemFontOfSize:11];
    title = [self titleOfSelectedItem];
    
    //Get the colors
    if(mouseIn){
        textColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
        bezelColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.4];
    }else{
        textColor = [NSColor colorWithCalibratedWhite:0.16 alpha:1.0];
        bezelColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.4];
    }
    
    //Create the attributes
    textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, nil];
    bezelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, bezelColor, NSForegroundColorAttributeName, nil];

    //Get the correct images
    triangle = (mouseIn ? popUpTriangleWhite: popUpTriangle);
    if(![[self cell] isHighlighted]){
        caps = popUpRolloverCaps;
        middle = popUpRolloverMiddle;
    }else{
        caps = popUpPressedCaps;
        middle = popUpPressedMiddle;
    }

    //Precalc dimensions
    capWidth = [caps size].width / 2.0;
    capHeight = [caps size].height;
    labelWidth = [title sizeWithAttributes:textAttributes].width;
    contentRight = capWidth + labelWidth + TRIANGLE_PADDING_X + [triangle size].width;
    frame = [self bounds];
    frame.origin.y -= BACK_OFFSET_Y;
    
    //Draw the backgound
    if(mouseIn){
        //Draw the left cap
        [caps compositeToPoint:NSMakePoint(frame.origin.x, frame.origin.y + frame.size.height)
                      fromRect:NSMakeRect(0, 0, capWidth, capHeight)
                     operation:NSCompositeSourceOver];

        //Draw the middle
        sourceRect = NSMakeRect(0, 0, [middle size].width, [middle size].height);
        destRect = NSMakeRect(frame.origin.x + capWidth, frame.origin.y + frame.size.height, sourceRect.size.width, sourceRect.size.height);

        while(destRect.origin.x < contentRight && sourceRect.size.width != 0){
            if((destRect.origin.x + destRect.size.width) > contentRight){ //Crop
                sourceRect.size.width -= (destRect.origin.x + destRect.size.width) - contentRight;
            }

            [middle compositeToPoint:destRect.origin
                            fromRect:sourceRect
                           operation:NSCompositeSourceOver];
            destRect.origin.x += destRect.size.width;
        }

        //Draw right cap
        [caps compositeToPoint:NSMakePoint(contentRight, frame.origin.y + frame.size.height)
                      fromRect:NSMakeRect(capWidth, 0, capWidth, capHeight)
                     operation:NSCompositeSourceOver];        
    }

    //Draw the embossed title
    [title drawInRect:NSOffsetRect(rect, capWidth, LABEL_OFFSET_Y + 1) withAttributes:bezelAttributes];
    [title drawInRect:NSOffsetRect(rect, capWidth, LABEL_OFFSET_Y) withAttributes:textAttributes];

    //Draw the triangle
    [triangle compositeToPoint:NSMakePoint(rect.origin.x + capWidth + labelWidth + TRIANGLE_PADDING_X, rect.origin.y + [triangle size].height + TRIANGLE_OFFSET_Y) operation:NSCompositeSourceOver];
}

- (void)resetCursorRects
{
    //Reset our cursor rects
    [self stopTrackingCursor];
    [self startTrackingCursor];

    //Redisplay
    [self setNeedsDisplay:YES];
}

- (void)stopTrackingCursor
{
    if(trackingTag){
        [self removeTrackingRect:trackingTag];
        trackingTag = 0;
    }    
}

- (void)startTrackingCursor
{
    if(trackingTag == 0){
        NSRect 		trackRect;

        //Tracking rect
        mouseIn = NO;
        trackRect = NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height);

        //Track only if we're within a valid window
        if([self window]){
            trackingTag = [self addTrackingRect:trackRect owner:self userData:nil assumeInside:mouseIn];
        }
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    if([self canDraw]){
        mouseIn = YES;
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    if([self canDraw]){
        mouseIn = NO;
        [self setNeedsDisplay:YES];
    }
}

@end
