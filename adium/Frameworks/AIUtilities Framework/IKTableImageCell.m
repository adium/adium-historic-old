//
//  IKTableImageCell.m
//  Adium
//
//  Created by Ian Krieg on Mon Jul 28 2003.
//

#import "CSBezierPathAdditions.h"
#import "IKTableImageCell.h"

@implementation IKTableImageCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    //Highlight
    if([self isHighlighted]){
        [[NSColor alternateSelectedControlColor] set];
        [[NSBezierPath bezierPathWithRoundedRect:cellFrame radius:4] fill];
    }

    //Draw our interior
    [super drawWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSImage	*img = [self image];
    
    if(img){
        // Handle flipped axes
		[img setFlipped:![img isFlipped]];
		
        // Size and location
        // Get image metrics
        NSSize	imgSize = [img size];
        NSRect	imgRect = NSMakeRect (0, 0, imgSize.width, imgSize.height);

        // Scaling
        NSRect	targetRect = cellFrame;
        if ((imgSize.height > cellFrame.size.height) ||
            (imgSize.width  >  cellFrame.size.width)) {

            if ((imgSize.height / cellFrame.size.height) >
                (imgSize.width / cellFrame.size.width)) {
                targetRect.size.width = imgSize.width / (imgSize.height / cellFrame.size.height);
            } else {
                targetRect.size.height = imgSize.height / (imgSize.width / cellFrame.size.width);
            }

        }else{
            targetRect.size.width = imgSize.width;
            targetRect.size.height = imgSize.height;
        }

        // Centering
        targetRect = NSOffsetRect(targetRect, (cellFrame.size.width - targetRect.size.width) / 2, (cellFrame.size.height - targetRect.size.height) / 2);
        
        // Draw	Image
        [img drawInRect:targetRect fromRect:imgRect operation:NSCompositeSourceOver fraction:([self isEnabled] ? 1.0 : 0.5)];

        // Clean-up
		[img setFlipped:![img isFlipped]];
    }
}

//Super doesn't appear to handle the isHighlighted flag correctly, so we handle it to be safe.
- (void)setHighlighted:(BOOL)flag
{
    [self setState:(flag ? NSOnState : NSOffState)];
    isHighlighted = flag;
}
- (BOOL)isHighlighted{
    return(isHighlighted);
}

@end
