/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@class AIModularPaneCategoryView, AIAutoScrollView, AIColoredBoxView, AIPreferencePane;

@interface AIPreferenceWindowController : AIWindowController {
    IBOutlet	NSTabView					*tabView_category;

	IBOutlet	AIModularPaneCategoryView	*view_General;
    IBOutlet	AIModularPaneCategoryView	*view_ContactList;
    IBOutlet	AIModularPaneCategoryView	*view_Messages;
	IBOutlet	AIModularPaneCategoryView	*view_Events;
    IBOutlet	AIModularPaneCategoryView	*view_Dock;
    IBOutlet 	AIModularPaneCategoryView	*view_Emoticons;
    IBOutlet 	AIModularPaneCategoryView	*view_FileTransfer;

    IBOutlet	NSTableView					*tableView_advanced;
	IBOutlet	AIAutoScrollView			*scrollView_advanced;

    IBOutlet	AIModularPaneCategoryView   *view_Advanced;
	IBOutlet	NSButton					*button_restoreDefaults;
    
	NSArray				    *viewArray;
    NSMutableArray		    *loadedPanes;
    NSMutableArray		    *loadedAdvancedPanes;
    NSMutableArray		    *_advancedCategoryArray;
}

+ (void)openPreferenceWindow;
+ (void)openPreferenceWindowToCategory:(PREFERENCE_CATEGORY)category;
+ (void)openPreferenceWindowToAdvancedPane:(NSString *)advancedPane;
+ (void)closePreferenceWindow;

//Panes
- (void)selectCategory:(PREFERENCE_CATEGORY)category;
- (void)selectAdvancedPane:(NSString *)advancedPane;

//Advanced Preferences
- (void)configureAdvancedPreferencesForPane:(AIPreferencePane *)preferencePane;
- (NSArray *)advancedCategoryArray;
- (IBAction)restoreDefaults:(id)sender;

@end
