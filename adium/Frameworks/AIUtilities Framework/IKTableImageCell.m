//
//  IKTableImageCell.m
//  Adium
//
//  Created by Ian Krieg on Mon Jul 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "IKTableImageCell.h"


@implementation IKTableImageCell

- (id)initImageCell:(NSImage *)anImage
{
    id me = [super initImageCell:anImage];
    [self setType:NSImageCellType];
    
    return(me);
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSImage	*img = [self image];

    if (!img){
        img = [self objectValue];
    }

    if (img) {

        // Handle flipped axes
        BOOL	wasFlipped = TRUE;
        if (![img isFlipped]) {
            wasFlipped = FALSE;
        }
        [img setFlipped:TRUE];
        
        // Size and location
          // Get image metrics
        NSSize	imgSize = [img size];
        NSRect	imgRect = NSMakeRect (0, 0, imgSize.width, imgSize.height);
        
          // Scaling
        BOOL	needsScaling = FALSE;
        NSRect	targetRect = cellFrame;
        if ((imgSize.height > cellFrame.size.height) ||
            (imgSize.width  >  cellFrame.size.width)) {
            needsScaling = TRUE;
            
            if ((imgSize.height / cellFrame.size.height) >
                (imgSize.width / cellFrame.size.width)) {
                targetRect.size.width = imgSize.width / (imgSize.height / cellFrame.size.height);
            } else {
                targetRect.size.height = imgSize.height / (imgSize.width / cellFrame.size.width);
            }
        }
        
          // Centering
        NSPoint	location = NSMakePoint ((targetRect.size.width - imgSize.width) / 2,
                                        (targetRect.size.height - imgSize.height) / 2);
                           
        
        // Draw background
        NSColor	*bgColor = nil;
        
        if ([self isHighlighted]) {
            //bgColor = [NSColor highlightColor];
            //if ([bgColor isEqual:[NSColor whiteColor]])
                bgColor = [NSColor yellowColor];
        } else {
            bgColor = [NSColor whiteColor];
        }

        if (![self isObjectEnabled]) {
            bgColor = [bgColor blendedColorWithFraction:0.5 ofColor:[NSColor grayColor]];
        }
        
        [bgColor set];
        [NSBezierPath fillRect:cellFrame];
        
        // Set appropriate transparency
        float	transparency = 0.5;
        if ([self isObjectEnabled]) {
            transparency = 1.0;
        }
        
        // Draw	Image
        if (needsScaling) {
            targetRect.origin = location;
            [img drawInRect:targetRect fromRect:imgRect operation:NSCompositeSourceOver fraction:transparency];
        } else
            [img drawAtPoint:cellFrame.origin fromRect:imgRect operation:NSCompositeSourceOver fraction:transparency];
        
        // Clean-up
        if (!wasFlipped){
            [img setFlipped:FALSE];
        }
    }
}

- (void)setObjectEnabled:(BOOL)enabled
{
    objectEnabled = enabled;
}

- (BOOL)isObjectEnabled
{
    return(objectEnabled);
}

- (void)setHighlighted:(BOOL)enabled
{
    highlighted = enabled;
}

- (BOOL)isHighlighted
{
    return(highlighted);
}
@end
