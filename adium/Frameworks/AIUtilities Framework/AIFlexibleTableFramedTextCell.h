//
//  AIFlexibleTableFramedTextCell.h
//  Adium
//
//  Created by Adam Iser on Tue Sep 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIFlexibleTableTextCell.h"

@interface AIFlexibleTableFramedTextCell : AIFlexibleTableTextCell {
    BOOL	drawTop;
    BOOL	drawBottom;

    NSColor 	*borderColor;
    NSColor	*bubbleColor;
}

- (void)setDrawTop:(BOOL)inDrawTop;
- (void)setDrawBottom:(BOOL)inDrawBottom;
- (void)setFrameBackgroundColor:(NSColor *)inBubbleColor borderColor:(NSColor *)inBorderColor;

@end
