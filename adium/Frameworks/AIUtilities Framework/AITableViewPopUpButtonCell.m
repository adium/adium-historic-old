//
//  AITableViewPopUpButtonCell.m
//  Adium
//
//  Created by Adam Iser on Sat Feb 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AITableViewPopUpButtonCell.h"

//A small, borderless pop-up button with a menu whose items contain icons will INCORRECTLY align the icon next to the text.  This custom subclass overrides the drawing method to correctly align the icon (in the case of a 16x16 icon and small 11-point menu text)

#define POPUP_Y_OFFSET		2
#define POPUP_X_OFFSET		-10
#define POPUP_WIDTH_OFFSET	10

@implementation AITableViewPopUpButtonCell

- (void)drawImageWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    cellFrame.origin.y += POPUP_Y_OFFSET;
    cellFrame.origin.x += POPUP_X_OFFSET;

    [super drawImageWithFrame:cellFrame inView:controlView];
}

- (void)drawTitleWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    cellFrame.origin.x += POPUP_X_OFFSET;
    cellFrame.size.width += POPUP_WIDTH_OFFSET;

    [super drawTitleWithFrame:cellFrame inView:controlView];
}

@end
