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

#define AIMessageWindow_ControllersChanged 		@"AIMessageWindow_ControllersChanged"
#define AIMessageWindow_ControllerOrderChanged 		@"AIMessageWindow_ControllerOrderChanged"
#define AIMessageWindow_SelectedControllerChanged 	@"AIMessageWindow_SelectedControllerChanged"

@class AIMessageSendingTextView, AIMiniToolbar, AIMessageViewController, AICustomTabsView, AIDualWindowInterfacePlugin;
@protocol AIContainerInterface, AIInterfaceContainer;

@interface AIMessageWindowController : AIWindowController {
    IBOutlet	NSTabView			*tabView_messages;
    IBOutlet	AICustomTabsView	*tabView_customTabs;

	NSMutableArray					*listObjectArray;
	
    BOOL			windowIsClosing;
    AIDualWindowInterfacePlugin<AIContainerInterface> 	*interface;

	BOOL			keepTabsArranged;
	BOOL			arrangeByGroup;
    BOOL			supressHiding;
    BOOL			tabIsShowing;
    BOOL			autohide_tabBar;
	int				force_tabBar_visible;  //-1 = Doesn't matter, 0 = NO, 1 = YES;
    float			tabHeight;
}

+ (AIMessageWindowController *)messageWindowControllerForInterface:(id <AIContainerInterface>)inInterface;
- (IBAction)closeWindow:(id)sender;
- (IBAction)toggleForceTabBarVisible:(id)sender;
- (NSArray *)messageContainerArray;
- (NSTabViewItem <AIInterfaceContainer> *)selectedTabViewItemContainer;
- (void)selectTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem;
- (void)addTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem;
- (void)addTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem atIndex:(int)index;
- (void)arrangeTabs;
- (void)removeTabViewItemContainer:(NSTabViewItem <AIInterfaceContainer> *)inTabViewItem;
- (BOOL)containsMessageContainer:(NSTabViewItem <AIInterfaceContainer> *)tabViewItem;
- (NSTabViewItem <AIInterfaceContainer> *)containerForListObject:(AIListObject *)inListObject;
- (AICustomTabsView *)customTabsView;
- (BOOL)selectNextTabViewItemContainer;
- (BOOL)selectPreviousTabViewItemContainer;
- (void)selectFirstTabViewItemContainer;
- (void)selectLastTabViewItemContainer;
- (NSTabViewItem <AIInterfaceContainer> *)containerForChat:(AIChat *)inChat;
@end
