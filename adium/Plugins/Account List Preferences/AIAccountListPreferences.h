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

@class AIAccountController, AIAccount, AIAutoScrollView;

@interface AIAccountListPreferences : AIPreferencePane <AIListObjectObserver> {
	//Account status
	IBOutlet		NSTextField					*textField_status;
	IBOutlet		NSProgressIndicator			*progress_status;
	IBOutlet		NSButton					*button_toggleConnect;
	
	//Account preferences
    IBOutlet		NSTabView					*tabView_auxiliary;
    IBOutlet		NSView						*view_accountDetails;
    IBOutlet		NSPopUpButton				*popupMenu_serviceList;
	IBOutlet		ESDelayedTextField			*textField_accountName;
    IBOutlet		NSButton					*button_autoConnect;

	//Account list
    IBOutlet		AIAutoScrollView			*scrollView_accountList;
    IBOutlet		AIAlternatingRowTableView   *tableView_accountList;
	IBOutlet		NSButton					*button_newAccount;
    IBOutlet		NSButton					*button_deleteAccount;

	//Current configuration
	id <AIServiceController>		configuredForService;
	AIAccount						*configuredForAccount;
    AIAccountViewController			*accountViewController;
	NSTimer							*responderChainTimer;

    //Account List
    NSArray							*accountArray;
    AIAccount						*tempDragAccount;
}

- (IBAction)deleteAccount:(id)sender;
- (IBAction)newAccount:(id)sender;
- (IBAction)selectServiceType:(id)sender;
- (IBAction)toggleAutoConnect:(id)sender;
- (IBAction)changeUIDField:(id)sender;
- (IBAction)toggleConnectStatus:(id)sender;

@end
