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

#define KEY_LIST_LAYOUT_NAME			@"List Layout Name"
#define KEY_LIST_THEME_NAME				@"List Theme Name"

@class AIListWindowController, AICLPreferences;
@protocol AIContactListController;

@interface AISCLViewPlugin : AIPlugin <AIContactListController> {	
	AIListWindowController		*contactListWindowController;
    AICLPreferences				*preferences;
	int							windowStyle;
}

//Contact List Controller
- (void)contactListDidClose;
- (void)showContactListAndBringToFront:(BOOL)bringToFront;
- (BOOL)contactListIsVisibleAndMain;
- (void)closeContactList;
- (void)contactListDidClose;

//Themes and Layouts
+ (void)applySetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder toPreferenceGroup:(NSString *)preferenceGroup;
+ (BOOL)createSetFromPreferenceGroup:(NSString *)preferenceGroup withName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder;
+ (BOOL)deleteSetWithName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder;
+ (NSArray *)availableLayoutSets;
+ (NSArray *)availableThemeSets;
+ (NSArray *)availableSetsWithExtension:(NSString *)extension fromFolder:(NSString *)folder;
+ (void)resetXtrasCache;

@end
