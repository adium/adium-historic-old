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

@class AIAdium, AIFlippedCategoryView;

@interface AIPreferenceWindowController : NSWindowController {
    IBOutlet	NSTabView			*tabView_category;

    IBOutlet	AIFlippedCategoryView		*view_Accounts;

    IBOutlet	NSTabView			*tabView_contactList;
    IBOutlet	AIFlippedCategoryView		*view_ContactList_General;
    IBOutlet	AIFlippedCategoryView		*view_ContactList_Groups;
    IBOutlet	AIFlippedCategoryView		*view_ContactList_Contacts;

    IBOutlet	NSTabView			*tabView_messages;
    IBOutlet	AIFlippedCategoryView		*view_Messages_Display;
    IBOutlet	AIFlippedCategoryView		*view_Messages_Sending;

    IBOutlet	NSTabView			*tabView_status;
    IBOutlet	AIFlippedCategoryView		*view_Status_Away;
    IBOutlet	AIFlippedCategoryView		*view_Status_Idle;

    IBOutlet	AIFlippedCategoryView		*view_Dock;
    
    IBOutlet	AIFlippedCategoryView		*view_Sound;

    IBOutlet 	AIFlippedCategoryView		*view_Alerts;
    
    IBOutlet 	AIFlippedCategoryView		*view_Emoticons;

    IBOutlet	NSOutlineView			*outlineView_advanced;
    IBOutlet	AIFlippedCategoryView		*view_Advanced;
    IBOutlet	NSTextField			*textField_advancedTitle;
    IBOutlet	AIColoredBoxView		*coloredBox_advancedTitle;
    
    NSMutableArray		*loadedPanes;
    NSMutableArray		*loadedAdvancedPanes;

    AIAdium			*owner;
    NSMutableDictionary		*toolbarItems;
    NSMutableArray		*_advancedCategoryArray;

    int				yPadding;    
}

+ (AIPreferenceWindowController *)preferenceWindowControllerWithOwner:(id)inOwner;
+ (void)closeSharedInstance;
- (IBAction)closeWindow:(id)sender;
- (void)showView:(AIPreferenceViewController *)inView;

@end
