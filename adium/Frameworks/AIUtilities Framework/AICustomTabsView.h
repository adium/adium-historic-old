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

#import "ESFloater.h"

@class AICustomTabCell, AICustomTabsView;

@protocol AICustomTabsViewDelegate <NSObject>
- (void)customTabView:(AICustomTabsView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)customTabView:(AICustomTabsView *)tabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)customTabViewDidChangeNumberOfTabViewItems:(AICustomTabsView *)tabView;
- (void)customTabViewDidChangeOrderOfTabViewItems:(AICustomTabsView *)tabView;
- (void)customTabView:(AICustomTabsView *)tabView didMoveTabViewItem:(NSTabViewItem *)tabViewItem toCustomTabView:(AICustomTabsView *)destTabView index:(int)index screenPoint:(NSPoint)point;
- (NSMenu *)customTabView:(AICustomTabsView *)tabView menuForTabViewItem:(NSTabViewItem *)tabViewItem;
- (BOOL)customTabView:(AICustomTabsView *)tabView didAcceptDragPasteboard:(NSPasteboard *)pasteboard onTabViewItem:(NSTabViewItem *)tabViewItem;
- (NSArray *)customTabViewAcceptableDragTypes:(AICustomTabsView *)tabView;
@end

@interface AICustomTabsView : NSView {
    IBOutlet	NSTabView	*tabView;

    NSMutableArray	*tabCellArray;
    AICustomTabCell	*selectedCustomTabCell;
    BOOL                removingLastTabHidesWindow;
    BOOL		allowsInactiveTabClosing;
    
    NSTimer             *arrangeCellTimer;
    
    //Drag tracking and receiving
    int			hoverIndex;		//The index it's hovering at
    NSPoint		lastClickLocation;
    
    //Delegate
    id <AICustomTabsViewDelegate>	delegate;
}

+ (void)dragTabCell:(AICustomTabCell *)inTabCell fromCustomTabsView:(AICustomTabsView *)sourceView withEvent:(NSEvent *)inEvent;
- (id <AICustomTabsViewDelegate>)delegate;
- (void)removeTabViewItem:(NSTabViewItem *)tabViewItem;
- (int)numberOfTabViewItems;
- (void)setDelegate:(id <AICustomTabsViewDelegate>)inDelegate;
- (id <AICustomTabsViewDelegate>)delegate;
- (void)setRemovingLastTabHidesWindow:(BOOL)inValue;
- (BOOL)removingLastTabHidesWindow;
- (void)setAllowsInactiveTabClosing:(BOOL)inValue;
- (BOOL)allowsInactiveTabClosing;

@end

