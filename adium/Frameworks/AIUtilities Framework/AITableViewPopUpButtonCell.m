/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AITableViewPopUpButtonCell.h"

/*
    A small, borderless pop-up button with a menu whose items contain icons will INCORRECTLY align the icon next to the text.  This custom subclass overrides the drawing method to correctly align the icon (in the case of a 16x16 icon and small 11-point menu text)
 */

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
