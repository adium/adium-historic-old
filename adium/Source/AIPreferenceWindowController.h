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

@class AIAdium, AIFlippedCategoryView;

@interface AIPreferenceWindowController : NSWindowController {
    IBOutlet	NSTabView			*tabView_category;

    IBOutlet	NSTabView			*tabView_accounts;
    IBOutlet	AIFlippedCategoryView		*view_Accounts_Connections;
    IBOutlet	AIFlippedCategoryView		*view_Accounts_Profile;
    IBOutlet	AIFlippedCategoryView		*view_Accounts_Hosts;

    IBOutlet	NSTabView			*tabView_contactList;
    IBOutlet	AIFlippedCategoryView		*view_ContactList_General;
    IBOutlet	AIFlippedCategoryView		*view_ContactList_Groups;
    IBOutlet	AIFlippedCategoryView		*view_ContactList_Contacts;

    IBOutlet	NSTabView			*tabView_messages;
    IBOutlet	AIFlippedCategoryView		*view_Messages_Display;
    IBOutlet	AIFlippedCategoryView		*view_Messages_Sending;
    IBOutlet	AIFlippedCategoryView		*view_Messages_Receiving;
    IBOutlet	AIFlippedCategoryView		*view_Messages_Emoticons;

    IBOutlet	NSTabView			*tabView_status;
    IBOutlet	AIFlippedCategoryView		*view_Status_Away;
    IBOutlet	AIFlippedCategoryView		*view_Status_Idle;

    IBOutlet	NSTabView			*tabView_dock;
    IBOutlet	AIFlippedCategoryView		*view_Dock_General;
    IBOutlet	AIFlippedCategoryView		*view_Dock_Icon;
    
    IBOutlet	AIFlippedCategoryView		*view_Sound;

    IBOutlet 	AIFlippedCategoryView		*view_Alerts;
    
    NSMutableArray		*loadedPanes;

    AIAdium			*owner;
    NSMutableDictionary		*toolbarItems;

    int				yPadding;    
}

+ (AIPreferenceWindowController *)preferenceWindowControllerWithOwner:(id)inOwner;
+ (void)closeSharedInstance;
- (IBAction)closeWindow:(id)sender;
- (void)showView:(AIPreferenceViewController *)inView;

@end
