//
//  AIPlasticButton.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AIUtilities/AIUtilities.h>
#import "AIPlasticButton.h"

#define LABEL_OFFSET_X	1
#define LABEL_OFFSET_Y	-1

#define IMAGE_OFFSET_X	0
#define IMAGE_OFFSET_Y	0

@implementation AIPlasticButton

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];

    //Load images
    plasticCaps = [[AIImageUtilities imageNamed:@"PlasticButtonNormal_Caps" forClass:[self class]] retain];
    plasticMiddle = [[AIImageUtilities imageNamed:@"PlasticButtonNormal_Middle" forClass:[self class]] retain];
    plasticPressedCaps = [[AIImageUtilities imageNamed:@"PlasticButtonPressed_Caps" forClass:[self class]] retain];
    plasticPressedMiddle = [[AIImageUtilities imageNamed:@"PlasticButtonPressed_Middle" forClass:[self class]] retain];
    plasticDefaultCaps = [[AIImageUtilities imageNamed:@"PlasticButtonDefault_Caps" forClass:[self class]] retain];
    plasticDefaultMiddle = [[AIImageUtilities imageNamed:@"PlasticButtonDefault_Middle" forClass:[self class]] retain];

    return(self);    
}

- (void)drawRect:(NSRect)rect
{
    NSRect	sourceRect, destRect;
    int		capWidth;
    int		capHeight;
    int		middleRight;
    NSImage	*caps;
    NSImage	*middle;

    //Get the correct images
    if(![[self cell] isHighlighted]){
        if([[self keyEquivalent] compare:@"\r"] == 0){
            caps = plasticDefaultCaps;
            middle = plasticDefaultMiddle;
        }else{
            caps = plasticCaps;
            middle = plasticMiddle;
        }
    }else{
        caps = plasticPressedCaps;
        middle = plasticPressedMiddle;
    }

    //Precalc some sizes
    capWidth = [caps size].width / 2.0;
    capHeight = [caps size].height;
    middleRight = ((rect.origin.x + rect.size.width) - capWidth);

    //Draw the left cap
    [caps compositeToPoint:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height)
                  fromRect:NSMakeRect(0, 0, capWidth, capHeight)
                 operation:NSCompositeSourceOver];

    //Draw the middle
    sourceRect = NSMakeRect(0, 0, [middle size].width, [middle size].height);
    destRect = NSMakeRect(rect.origin.x + capWidth, rect.origin.y + rect.size.height, sourceRect.size.width, sourceRect.size.height);

    while(destRect.origin.x < middleRight && sourceRect.size.width != 0){
        //Crop
        if((destRect.origin.x + destRect.size.width) > middleRight){
            sourceRect.size.width -= (destRect.origin.x + destRect.size.width) - middleRight;
        }

        [middle compositeToPoint:destRect.origin
                        fromRect:sourceRect
                       operation:NSCompositeSourceOver];
        destRect.origin.x += destRect.size.width;
    }

    //Draw right mask
    [caps compositeToPoint:NSMakePoint(middleRight, rect.origin.y + rect.size.height)
                  fromRect:NSMakeRect(capWidth, 0, capWidth, capHeight)
                 operation:NSCompositeSourceOver];

    //Draw Label
    if([self title]){
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self font], NSFontAttributeName, nil];
        NSSize	size = [[self title] sizeWithAttributes:attributes];
        NSPoint	centeredPoint;


        centeredPoint = NSMakePoint(rect.origin.x + ((rect.size.width - size.width) / 2.0) + LABEL_OFFSET_X,
                                    rect.origin.y + ((capHeight - size.height) / 2.0) + LABEL_OFFSET_Y);

        [[self title] drawAtPoint:centeredPoint withAttributes:attributes];
    }

    //Draw
    if([self image]){
        NSSize	size = [[self image] size];
        NSRect	centeredRect;

        centeredRect = NSMakeRect(rect.origin.x + ((rect.size.width - size.width) / 2.0) + IMAGE_OFFSET_X,
                                  rect.origin.y + ((capHeight - size.height) / 2.0) + IMAGE_OFFSET_Y,
                                  size.width,
                                  size.height);

        [[self image] setFlipped:YES];
        [[self image] drawInRect:centeredRect fromRect:NSMakeRect(0,0,size.width,size.height) operation:NSCompositeSourceOver fraction:1.0];
    }
    
}

- (BOOL)isOpaque
{
    return(NO);
}

- (void)dealloc
{
    [plasticCaps release];
    [plasticMiddle release];
    [plasticPressedCaps release];
    [plasticPressedMiddle release];    

    [super dealloc];
}

@end
