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

@interface AIListOutlineView : AIMultiCellOutlineView <AIAutoSizingView, ContactListOutlineView> {    
//    NSTrackingRectTag   trackingRectTag;	//Tracing rect for the whole outline view
//    int					oldSelection;		//Holds the selection when it's hidden
//    BOOL				editing;			//YES when the list is in edit mode... (temp)
//
//    BOOL			showLabels;
//    BOOL			labelAroundContactOnly;
//    float			labelOpacity;
//    BOOL			outlineLabels;
//	BOOL			useGradient;
//	BOOL			updateShadowsWhileDrawing;
//	
//	BOOL			dragging;
//	
//    NSFont			*font;
//    NSFont			*groupFont;
//    NSColor			*color;
//    NSColor			*invertedColor;
//    NSColor			*groupColor;
//    NSColor			*invertedGroupColor;
//    NSColor			*outlineGroupColor;
//    NSColor			*labelGroupColor;
//    
//    float			spacing;
//    
//    float			desiredWidth[3];
//    AIListObject	*hadMax[3];
//    
//    NSCell			*selectedItem;
	
	//Selection hiding
//	int					lastSelectedRow;
	BOOL updateShadowsWhileDrawing;

	NSImage		*backgroundImage;
	float 		backgroundFade;
	BOOL		drawsBackground;
	
	NSColor		*backgroundColor;
	
	//Tooltops
//	NSTimer				*tooltipMouseLocationTimer;
//	NSPoint				tooltipLocation;
//	NSPoint				lastMouseLocation;
//    NSTrackingRectTag	tooltipTrackingTag;        
//    int 				tooltipCount;
}

- (void)setDelegate:(id)delegate;
- (void)setRowHeightFromDataCellOfColumn:(NSTableColumn *)column;

//Frame and superview tracking
- (void)viewWillMoveToSuperview:(NSView *)newSuperview;
- (void)viewDidMoveToSuperview;
- (void)frameDidChange:(NSNotification *)notification;

//Selection Hiding
- (void)configureSelectionHidingForNewSuperview:(NSView *)newSuperview;
- (void)windowBecameMain:(NSNotification *)notification;
- (void)windowResignedMain:(NSNotification *)notification;

//Contact menu 
- (AIListObject *)listObject;

//Tooltips (Cursor rects)
- (void)configureTooltipsForNewSuperview:(NSView *)newSuperview;
- (void)configureTooltipsForNewScrollViewFrame;
- (void)_installCursorRect;
- (void)_removeCursorRect;

//Tooltips (Cursor movement)
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)_startTrackingMouse;
- (void)_stopTrackingMouse;
- (void)mouseMovementTimer:(NSTimer *)inTimer;

//Tooltips (Display)
- (void)hideTooltip;
- (void)_showTooltipAtPoint:(NSPoint)screenPoint;

- (void)setUpdateShadowsWhileDrawing:(BOOL)update;
- (void)setBackgroundImage:(NSImage *)inImage;
- (void)setBackgroundFade:(float)fade;
- (void)setDrawsBackground:(BOOL)inDraw;
	
@end

@interface NSObject (AIStandardListOutlineViewDelegate)
- (NSCell *)outlineViewDataCellForContent:(NSOutlineView *)outlineView;
- (NSCell *)outlineViewDataCellForGroup:(NSOutlineView *)outlineView;
@end


