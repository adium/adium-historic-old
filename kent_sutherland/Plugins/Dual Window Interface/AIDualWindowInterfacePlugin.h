/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Adium/AIPlugin.h>

@class AIContactListWindowController, AIDualWindowPreferences, AIMessageTabViewItem,
	AIMessageWindowController, ESDualWindowMessageAdvancedPreferences, AIChat;

@protocol AIInterfaceController;

#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"

#define DUAL_INTERFACE_DEFAULT_PREFS		@"DualWindowDefaults"

//#define KEY_ALWAYS_CREATE_NEW_WINDOWS 		@"Always Create New Windows"
//#define KEY_USE_LAST_WINDOW					@"Use Last Window"
//#define KEY_AUTOHIDE_TABBAR					@"Autohide Tab Bar"
//#define KEY_ENABLE_INACTIVE_TAB_CLOSE		@"Enable Inactive Tab Close"
//#define KEY_KEEP_TABS_ARRANGED				@"Keep Tabs Arranged"
//#define KEY_ARRANGE_TABS_BY_GROUP			@"Arrange Tabs By Group"
#define KEY_TABBAR_ORIENTATION				@"Tab Bar Orientation"
#define KEY_TABBAR_WIDTH					@"Tab Bar Width"

#define KEY_ALWAYS_CREATE_NEW_WINDOWS 		@"Always Create New Windows"
#define KEY_USE_LAST_WINDOW					@"Use Last Window"
#define KEY_AUTOHIDE_TABBAR					@"Autohide Tab Bar"
#define KEY_ENABLE_INACTIVE_TAB_CLOSE		@"Enable Inactive Tab Close"
#define KEY_KEEP_TABS_ARRANGED				@"Keep Tabs Arranged"
#define KEY_ARRANGE_TABS_BY_GROUP			@"Arrange Tabs By Group"
#define	KEY_WINDOW_LEVEL					@"Window Level"
#define KEY_WINDOW_HIDE						@"Hide While in Background"

#define PREF_GROUP_CONTACT_LIST_DISPLAY		@"Contact List Display"
#define KEY_SCL_BORDERLESS					@"Borderless"

@protocol AIInterfaceContainer <NSObject>
- (void)makeActive:(id)sender;	//Make the container active/front
- (void)close:(id)sender;	//Close the container
@end

@interface AIDualWindowInterfacePlugin : AIPlugin <AIInterfaceController> {
    
	NSMutableArray			*delayedContainerShowArray;
	NSMutableDictionary		*containers;
	int						uniqueContainerNumber;
	
    //Menus
    NSMutableArray			*windowMenuArray;
    NSMenuItem				*menuItem_close;
    NSMenuItem				*menuItem_closeTab;
    NSMenuItem				*menuItem_nextMessage;
    NSMenuItem				*menuItem_previousMessage;

    NSMenuItem				*menuItem_openInNewWindow;
    NSMenuItem				*menuItem_openInPrimaryWindow;
    NSMenuItem				*menuItem_consolidate;
	NSMenuItem				*menuItem_splitByGroup;
	NSMenuItem				*menuItem_toggleTabBar;
	
	NSMenuItem				*menuItem_arrangeTabs;
	NSMenuItem				*menuItem_arrangeTabs_alternate;
    
    //Containers
    AIContactListWindowController 	*contactListWindowController;
    id <AIInterfaceContainer>		activeContainer;

    //messageWindow stuff
    NSMutableArray			*messageWindowControllerArray;
    AIMessageWindowController		*lastUsedMessageWindow;
    NSMutableArray			*lastUsedContainerArray;
	NSMutableDictionary		*arrangeByGroupWindowList;
    
    //Preferences
    AIDualWindowPreferences                 *preferenceController;
    ESDualWindowMessageAdvancedPreferences	*preferenceMessageAdvController;

	BOOL					applicationIsHidden;

}

- (id)openContainerWithID:(NSString *)containerID name:(NSString *)containerName;
- (void)closeContainer:(AIMessageWindowController *)container;
- (void)containerDidClose:(AIMessageWindowController *)container;
- (void)transferMessageTab:(AIMessageTabViewItem *)tabViewItem toContainer:(id)newMessageWindow atIndex:(int)index withTabBarAtPoint:(NSPoint)screenPoint;

@end
