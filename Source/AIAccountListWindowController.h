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

@class AIAccountController, AIAccount, AIAutoScrollView, ESImageViewWithImagePicker;

@interface AIAccountListWindowController : AIWindowController <AIListObjectObserver> {
	//Account list
    IBOutlet		AIAutoScrollView			*scrollView_accountList;
    IBOutlet		NSTableView					*tableView_accountList;
	IBOutlet		NSButton					*button_newAccount;
    IBOutlet		NSButton					*button_deleteAccount;
	IBOutlet		NSButton					*button_editAccount;
	IBOutlet		NSTextField					*textField_overview;

    //Account List
    NSArray							*accountArray;
    AIAccount						*tempDragAccount;
}

+ (AIAccountListWindowController *)accountListWindowController;
- (IBAction)deleteAccount:(id)sender;
- (IBAction)editAccount:(id)sender;
- (void)updateAccountOverview;
- (void)updateControlAvailability;

@end
