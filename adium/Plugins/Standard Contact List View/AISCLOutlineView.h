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

@interface AISCLOutlineView : AIAlternatingRowOutlineView <AIAutoSizingView,ContactListOutlineView> {    
    NSTrackingRectTag   trackingRectTag;	//Tracing rect for the whole outline view
    int					oldSelection;		//Holds the selection when it's hidden
    BOOL				editing;			//YES when the list is in edit mode... (temp)

    BOOL			showLabels;
    BOOL			labelAroundContactOnly;
    float			labelOpacity;
    BOOL			outlineLabels;
	BOOL			useGradient;
	BOOL			updateShadowsWhileDrawing;
	
	BOOL			dragging;
	
    NSFont			*font;
    NSFont			*groupFont;
    NSColor			*color;
    NSColor			*invertedColor;
    NSColor			*groupColor;
    NSColor			*invertedGroupColor;
    NSColor			*outlineGroupColor;
    NSColor			*labelGroupColor;
    
    float			spacing;
    int				lastSelectedRow;
    
    float			desiredWidth[3];
    AIListObject	*hadMax[3];
    
    NSCell			*selectedItem;
}

- (void)setFont:(NSFont *)inFont;
- (NSFont *)font;
- (NSSize)desiredSize;
- (AIListObject *)listObject;

- (void)setColor:(NSColor *)inColor;
- (NSColor *)color;
- (NSColor *)invertedColor;

- (void)setGroupColor:(NSColor *)inColor;
- (NSColor *)groupColor;
- (NSColor *)invertedGroupColor;

- (void)setUpdateShadowsWhileDrawing:(BOOL)update;

- (void)setOutlineGroupColor:(NSColor *)inOutlineGroupColor;
- (NSColor *)outlineGroupColor;

- (void)setLabelGroupColor:(NSColor *)inLabelGroupColor;
- (NSColor *)labelGroupColor;

- (void)setShowLabels:(BOOL)inValue;
- (BOOL)showLabels;

- (void)setOutlineLabels:(BOOL)inValue;
- (BOOL)outlineLabels;

- (void)setUseGradient:(BOOL)inValue;
- (BOOL)useGradient;

- (void)setLabelAroundContactOnly:(BOOL)inLabelAroundContactOnly;
- (BOOL)labelAroundContactOnly;

- (void)setLabelOpacity:(float)inValue;
- (float)labelOpacity;

- (void)setGroupFont:(NSFont *)inFont;
- (NSFont *)groupFont;

- (void)updateHorizontalSizeForObjects:(NSArray *)inObjects;
- (void)updateHorizontalSizeForObject:(AIListObject *)inObject;
- (BOOL)_performPartialRecalculationForObject:(AIListObject *)inObject;
- (void)_performFullRecalculation;

@end
