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

#define AITabView_DidChangeOrderOfItems		@"AITabView_DidChangeOrderOfItems"
#define AITabView_DidChangeSelectedItem		@"AITabView_DidChangeSelectedItem"
#define AITabView_DidChangeNumberOfItems	@"AITabView_DidChangeNumberOfItems"

@class AICustomTab;

@interface AICustomTabsView : NSView {
    IBOutlet	NSTabView	*tabView;

    NSMutableArray	*tabArray;

    //Images
    NSImage		*tabBackground;
    NSImage		*tabDivider;
    
    //Dragging
    NSImage		*dragImage;
    NSSize		dragInitialOffset;	//Offset of the cursor on the drag image
    AICustomTab		*dragTab;

    BOOL		tabHasBeenDragged;
    BOOL		viewsRearranging;	//YES if our views are currently animating/rearranging

    int			tabXOrigin;
}

- (void)beginDragOfTab:(AICustomTab *)inTab fromOffset:(NSSize)inOffset;
- (void)updateDragAtOffset:(int)inOffset;
- (BOOL)concludeDrag;

@end
