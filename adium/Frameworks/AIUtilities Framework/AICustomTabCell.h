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

@interface AICustomTabCell : NSCell {
    //Properties
    BOOL		selected;
    BOOL		highlighted;
    BOOL		dragging;
    BOOL		allowsInactiveTabClosing;
    
    NSRect		closeButtonRect;
    BOOL		trackingClose;
    BOOL		hoveringClose;
    
    NSTrackingRectTag	trackingTag;
    NSDictionary        *userData;
    NSTrackingRectTag   closeTrackingTag;
    NSDictionary        *closeUserData;
    
    NSTabViewItem	*tabViewItem;
    NSSize		oldSize;

    NSRect		frame;
}

+ (id)customTabForTabViewItem:(NSTabViewItem *)inTabViewItem;
- (void)setAllowsInactiveTabClosing:(BOOL)inValue;
- (void)setSelected:(BOOL)inSelected;
- (BOOL)isSelected;
- (NSTabViewItem *)tabViewItem;
- (NSSize)size;
- (NSComparisonResult)compareWidth:(AICustomTabCell *)tab;
- (void)setFrame:(NSRect)inFrame;
- (NSRect)frame;
- (BOOL)willTrackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView;
- (void)setHighlighted:(BOOL)inHighlighted;
- (void)addTrackingRectsInView:(NSView *)view withFrame:(NSRect)trackRect cursorLocation:(NSPoint)cursorLocation;
- (void)removeTrackingRectsFromView:(NSView *)view;

@end
