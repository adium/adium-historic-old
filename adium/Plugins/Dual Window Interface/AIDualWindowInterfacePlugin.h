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

#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"

//#define DUAL_INTERFACE_DEFAULT_PREFS		@"DualWindowDefaults"
//#define DUAL_INTERFACE_WINDOW_DEFAULT_PREFS	@"DualWindowMessageDefaults"
//
//
//#define KEY_ALWAYS_CREATE_NEW_WINDOWS 		@"Always Create New Windows"
//#define KEY_USE_LAST_WINDOW					@"Use Last Window"
//#define KEY_AUTOHIDE_TABBAR					@"Autohide Tab Bar"
//#define KEY_ENABLE_INACTIVE_TAB_CLOSE		@"Enable Inactive Tab Close"
//#define KEY_KEEP_TABS_ARRANGED				@"Keep Tabs Arranged"
//#define KEY_ARRANGE_TABS_BY_GROUP			@"Arrange Tabs By Group"

@class ESDualWindowMessageAdvancedPreferences, AIMessageWindowController, AIMessageTabViewItem;

@interface AIDualWindowInterfacePlugin : AIPlugin <AIInterfaceController> {
    ESDualWindowMessageAdvancedPreferences  *preferenceMessageAdvController;
    
	BOOL					applicationIsHidden;
	NSMutableArray			*delayedContainerShowArray;
	NSMutableDictionary		*containers;
	int						uniqueContainerNumber;
}

- (id)openContainerNamed:(NSString *)containerName;
- (void)closeContainer:(AIMessageWindowController *)container;
- (void)transferMessageTab:(AIMessageTabViewItem *)tabViewItem toContainer:(id)newMessageWindow atIndex:(int)index withTabBarAtPoint:(NSPoint)screenPoint;

@end
