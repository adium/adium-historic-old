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
#import "ESFloater.h"

@class AIAdium, AICustomTabCell, AICustomTabsView;

@protocol AICustomTabsViewDelegate <NSObject>
- (void)customTabView:(AICustomTabsView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)customTabView:(AICustomTabsView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)customTabViewDidChangeNumberOfTabViewItems:(AICustomTabsView *)TabView;
- (void)customTabViewDidChangeOrderOfTabViewItems:(AICustomTabsView *)TabView;
- (NSMenu *)customTabView:(AICustomTabsView *)tabView menuForTabViewItem:(NSTabViewItem *)tabViewItem;
@end

@interface AICustomTabsView : NSView {
    IBOutlet	NSTabView	*tabView;

    NSMutableArray	*tabCellArray;
    AICustomTabCell	*selectedCustomTabCell;

    //Images
    NSImage		*tabDivider;
    
    BOOL		viewsRearranging;	//YES if our views are currently animating/rearranging
    int			tabXOrigin;
    
    //Drag tracking and receiving
    NSSize		hoverSize;		//The size of that object
    int			hoverIndex;		//The index it's hovering at
    BOOL		draggingATabCell;
    BOOL		focusedForDrag;		//YES if we are being dragged onto
    BOOL                hovering;
    
    //Dragging source
    NSImage		*dragImage;
    ESFloater           *dragFloater;
    NSSize		draggedSize;		//The item's size
    NSSize		draggedOffset;
    int			draggedIndex;       
    BOOL                draggingLastItem;
    float               tabBarHeight;
    
    NSPoint		lastClickLocation;

    AIAdium             *owner;
    
    //Delegate
    id <AICustomTabsViewDelegate>	delegate;
}

- (void)removeTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)setOwner:(AIAdium *)inOwner;
- (void)acceptDropInMessageView;
- (void)updateHoverAtScreenPoint:(NSPoint)inPoint;
- (void)removeHover;
- (void)acceptDropAtScreenPoint:(NSPoint)inPoint;

@end

