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

#define PREF_GROUP_ADD_CONTACT  @"Add Contact"
#define KEY_ADD_CONTACT_TO		@"Add Contacts to account"

@interface AINewContactWindowController : AIWindowController <AIListObjectObserver> {
	IBOutlet	NSPopUpButton				*popUp_contactType;
	IBOutlet	NSPopUpButton				*popUp_targetGroup;
	IBOutlet	NSTextField					*textField_contactName;
	IBOutlet	NSTextField					*textField_contactAlias;
	IBOutlet	NSTableView					*tableView_accounts;

	IBOutlet	AILocalizationButton		*button_add;
	IBOutlet	AILocalizationButton		*button_cancel;
	
	IBOutlet	AILocalizationTextField		*textField_type;
	IBOutlet	AILocalizationTextField		*textField_alias;
	IBOutlet	AILocalizationTextField		*textField_inGroup;
	IBOutlet	AILocalizationTextField		*textField_addToAccounts;
	IBOutlet	NSTextField					*textField_contactNameLabel;

	NSArray							*accounts;
	NSString						*contactName;
	AIService						*service;
	
	NSRect							originalContactNameLabelFrame;
}

+ (void)promptForNewContactOnWindow:(NSWindow *)parentWindow name:(NSString *)contact service:(AIService *)inService;
- (IBAction)cancel:(id)sender;
- (IBAction)addContact:(id)sender;
- (IBAction)closeWindow:(id)sender;

@end
