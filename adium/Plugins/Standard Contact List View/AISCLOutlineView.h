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

//@protocol AIListObjectObserver;
@class AIAdium;

@interface AISCLOutlineView : AIAlternatingRowOutlineView <AIAutoSizingView> {    
    NSTrackingRectTag		trackingRectTag;	//Tracing rect for the whole outline view
    int				oldSelection;		//Holds the selection when it's hidden
    BOOL			editing;		//YES when the list is in edit mode... (temp)

    BOOL			showLabels;
    NSFont			*font;
    NSFont			*groupFont;
    NSColor			*color;
    NSColor			*invertedColor;
    NSColor			*groupColor;
    NSColor			*invertedGroupColor;

    int				lastSelectedRow;
    
    float                       desiredWidth[3];
    AIListObject                *hadMax[3];
}

- (void)setFont:(NSFont *)inFont;
- (NSFont *)font;
- (NSSize)desiredSize;
- (AIListContact *)contact;

- (void)setColor:(NSColor *)inColor;
- (NSColor *)color;
- (NSColor *)invertedColor;

- (void)setGroupColor:(NSColor *)inColor;
- (NSColor *)groupColor;
- (NSColor *)invertedGroupColor;

- (void)setShowLabels:(BOOL)inValue;
- (BOOL)showLabels;

- (void)setGroupFont:(NSFont *)inFont;
- (NSFont *)groupFont;

- (void)updateHorizontalSizeForObject:(AIListObject *)inObject;
- (void)performFullRecalculation;

@end
