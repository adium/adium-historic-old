/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <Cocoa/Cocoa.h>


@interface AICustomTab : NSView {
    //Images
    NSImage		*tabBackLeft;
    NSImage		*tabBackMiddle;
    NSImage		*tabBackRight;
    NSImage		*tabFrontLeft;
    NSImage		*tabFrontMiddle;
    NSImage		*tabFrontRight;
    NSImage		*tabPushLeft;
    NSImage		*tabPushMiddle;
    NSImage		*tabPushRight;

    //Properties
    BOOL		selected;
    BOOL		depressed;
    BOOL		dragging;

    NSTrackingRectTag	trackingRectTag;

    NSTabViewItem	*tabViewItem;
    NSSize		oldSize;

    NSPoint		clickLocation;
}

+ (id)customTabWithFrame:(NSRect)frameRect forTabViewItem:(NSTabViewItem *)inTabViewItem;
- (void)setSelected:(BOOL)inSelected;
- (void)setDepressed:(BOOL)inDepressed;
- (NSTabViewItem *)tabViewItem;
- (NSSize)size;
- (NSComparisonResult)compareWidth:(AICustomTab *)tab;

@end
