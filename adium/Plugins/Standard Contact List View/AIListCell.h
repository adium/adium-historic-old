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

@class AIListObject, AISCLOutlineView;

@interface AIListCell : NSCell {
    AIListObject	*listObject;
    BOOL			isGroup;
	
	NSView			*controlView;
	
	NSTextAlignment	textAlignment;
	
	int				topSpacing;
	int				bottomSpacing;
	int				topPadding;
	int				bottomPadding;

	int				leftPadding;
	int				rightPadding;
	int				leftSpacing;
	int				rightSpacing;

//	NSTextStorage 	*textStorage;
//	NSLayoutManager	*layoutManager;
//	NSTextContainer	*textContainer;
	
	NSFont			*font;
	
	
	
	NSImage			*genericUserIcon;
}

- (void)setListObject:(AIListObject *)inObject;
- (void)setControlView:(NSView *)inControlView;

- (void)setTextAlignment:(NSTextAlignment)inAlignment;
- (NSTextAlignment)textAlignment;

//
- (void)setStatusFont:(NSFont *)inFont;
- (NSFont *)statusFont;

//
- (void)setSplitVerticalPadding:(int)inPadding;
- (void)setTopPadding:(int)inPadding;
- (void)setBottomPadding:(int)inPadding;
- (void)setLeftPadding:(int)inPadding;
- (void)setRightPadding:(int)inPadding;

//Sizing and Display
- (NSSize)cellSize;
- (int)topSpacing;
- (int)bottomSpacing;
- (int)topPadding;
- (int)bottomPadding;
- (int)leftPadding;
- (int)rightPadding;

//
- (void)drawSelectionWithFrame:(NSRect)rect;
- (NSRect)drawDisplayNameWithFrame:(NSRect)rect;

//
- (void)setSplitVerticalSpacing:(int)inSpacing;
- (void)setTopSpacing:(int)inSpacing;
- (void)setBottomSpacing:(int)inSpacing;
- (void)setLeftSpacing:(int)inSpacing;
- (void)setRightSpacing:(int)inSpacing;

@end
