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

#define AIMessageWindow_ControllersChanged 		@"AIMessageWindow_ControllersChanged"
#define AIMessageWindow_ControllerOrderChanged 		@"AIMessageWindow_ControllerOrderChanged"
#define AIMessageWindow_SelectedControllerChanged 	@"AIMessageWindow_SelectedControllerChanged"

@class AIMessageSendingTextView, AIMessageTabViewItem, AIMessageViewController, AICustomTabsView, AIDualWindowInterfacePlugin;
@protocol AIContainerInterface, AIInterfaceContainer;

@interface AIMessageWindowController : AIWindowController {
    IBOutlet	NSTabView			*tabView_messages;
    IBOutlet	AICustomTabsView	*tabView_customTabs;
    AIDualWindowInterfacePlugin 	*interface;
	NSString						*containerName;
	NSString						*containerID;
//	NSMutableArray					*listObjectArray;
	
	BOOL			windowIsClosing;
		
//	BOOL			keepTabsArranged;
//	BOOL			arrangeByGroup;
    BOOL			supressHiding;		//YSE to temporarily suppress hiding of the tabs (used for dragging)
	BOOL			alwaysShowTabs;		//YES if the tabs should always be visible, even if there is only 1
    float			tabBarHeight;		//Height of the tab bar, used to restore their visibility
	BOOL			tabBarIsVisible;	//YES if the tab bar is currently visible
	
	NSDictionary	*toolbarItems;
	NSMutableArray	*containedChats;
	
}

+ (AIMessageWindowController *)messageWindowControllerForInterface:(AIDualWindowInterfacePlugin *)inInterface
															withID:(NSString *)inContainerID
															  name:(NSString *)inName;
- (void)showWindowInFront:(BOOL)inFront;
- (IBAction)closeWindow:(id)sender;
- (NSString *)containerID;
- (NSString *)name;

//Contained Chats
- (void)addTabViewItem:(AIMessageTabViewItem *)inTabViewItem;
- (void)addTabViewItem:(AIMessageTabViewItem *)inTabViewItem atIndex:(int)index silent:(BOOL)silent;
- (void)removeTabViewItem:(AIMessageTabViewItem *)inTabViewItem silent:(BOOL)silent;
- (void)moveTabViewItem:(AIMessageTabViewItem *)inTabViewItem toIndex:(int)index;
- (BOOL)containerIsEmpty;
- (NSArray *)containedChats;

//Tabs
- (void)updateTabBarVisibilityAndAnimate:(BOOL)animate;
- (void)updateIconForTabViewItem:(AIMessageTabViewItem *)tabViewItem;
- (void)updateTabArrangingBehavior;

@end

