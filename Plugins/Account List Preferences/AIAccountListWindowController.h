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
	//Account status
	IBOutlet		NSTextField					*textField_status;
	IBOutlet		NSProgressIndicator			*progress_status;
	IBOutlet		NSButton					*button_toggleConnect;
	IBOutlet		NSButton					*button_register;
	
	//Account preferences
    IBOutlet		NSTabView					*tabView_auxiliary;
    IBOutlet		NSView						*view_accountDetails;
    IBOutlet		NSPopUpButton				*popupMenu_serviceList;
	IBOutlet		ESDelayedTextField			*textField_accountName;
	IBOutlet		NSTextField					*textField_userNameLabel;
    IBOutlet		NSButton					*button_autoConnect;
	IBOutlet		ESImageViewWithImagePicker  *imageView_userIcon;

	//Account list
    IBOutlet		AIAutoScrollView			*scrollView_accountList;
    IBOutlet		NSTableView					*tableView_accountList;
	IBOutlet		NSPopUpButton				*button_newAccount;
    IBOutlet		NSButton					*button_deleteAccount;

	//Current configuration
	AIService						*configuredForService;
	AIAccount						*configuredForAccount;
    AIAccountViewController			*accountViewController;
	NSTimer							*responderChainTimer;

    //Account List
    NSArray							*accountArray;
    AIAccount						*tempDragAccount;
}

+ (AIAccountListWindowController *)accountListWindowController;

- (IBAction)deleteAccount:(id)sender;
- (IBAction)selectServiceType:(id)sender;
- (IBAction)toggleAutoConnect:(id)sender;
- (IBAction)changeUIDField:(id)sender;
- (IBAction)toggleConnectStatus:(id)sender;
- (IBAction)registerAccount:(id)sender;

@end
