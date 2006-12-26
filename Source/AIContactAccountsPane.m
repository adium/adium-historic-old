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

#import "AIContactAccountsPane.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <AIUtilities/AIAlternatingRowTableView.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListGroup.h>
#import <Adium/AILocalizationTextField.h>
#import <Adium/AIMetaContact.h>

@interface AIContactAccountsPane (PRIVATE)
- (void)updateAccountList;
- (void)updateGroupList;
@end

static NSComparisonResult compareContactsByTheirAccounts(id firstContact, id secondContact, void *context);

/*!
 * @class AIContactAccountsPane
 * @brief Accounts pane in the contact info window
 *
 * Provides a list of what accounts list a contact and in what group.
 */
@implementation AIContactAccountsPane

//Preference pane properties
/*!
 * @brief Category
 */
- (AIContactInfoCategory)contactInfoCategory
{
    return AIInfo_Accounts;
}

/*!
 * @brief Nib name
 */
- (NSString *)nibName
{
    return @"ContactAccounts";
}

/*!
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	[label_listedOnTheFollowingOfYourAccounts setLocalizedString:AILocalizedString(@"Listed on the following of your accounts:",nil)];

	//Configure Table view
	[tableView_accounts setUsesAlternatingRowBackgroundColors:YES];
	[tableView_accounts setAcceptsFirstMouse:YES];

	[[[tableView_accounts tableColumnWithIdentifier:@"account"] headerCell] setTitle:AILocalizedString(@"On Account",nil)];
	[[[tableView_accounts tableColumnWithIdentifier:@"contact"] headerCell] setTitle:AILocalizedString(@"Individual Contact",nil)];
	[[[tableView_accounts tableColumnWithIdentifier:@"group"] headerCell] setTitle:AILocalizedString(@"In Group",nil)];
	contactsColumnIsInAccountsTableView = YES; //It's in the table view in the nib.

	//Observe contact list changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateGroupList)
									   name:Contact_ListChanged
									 object:nil];
	[self updateGroupList];
	
	//Observe account changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateAccountList)
									   name:Account_ListChanged
									 object:nil];
	[self updateAccountList];
	
	[tableView_accounts sizeToFit];
}

/*!
 * @brief Preference view is closing
 */
- (void)viewWillClose
{
	[accounts release]; accounts = nil;
	[contacts release]; contacts = nil;
    [listObject release]; listObject = nil;
	[[adium notificationCenter] removeObserver:self]; 
}

/*!
 * @brief Configure the pane for a list object
 */
- (void)configureForListObject:(AIListObject *)inObject
{
	if (listObject != inObject) {
		//Update the table view to have or not have the "Individual Contact" column, as appropriate.
		//It should have the column when our list object is a metacontact.
		if ([inObject isKindOfClass:[AIMetaContact class]]) {
			if (!contactsColumnIsInAccountsTableView) {
				//Add the column.
				[tableView_accounts addTableColumn:tableColumn_contacts];
				//It was added as last; move to the middle.
				[tableView_accounts moveColumn:2 toColumn:1];
				//Set all of the table view's columns to be the same width.
				float columnWidth = [tableView_accounts frame].size.width / 3.0;
				[[tableView_accounts tableColumns] setValue:[NSNumber numberWithFloat:columnWidth] forKey:@"width"];
				[tableView_accounts tile];
				//We don't need it retained anymore.
				[tableColumn_contacts release];

				contactsColumnIsInAccountsTableView = YES;
			}
		} else if(contactsColumnIsInAccountsTableView) {
			//Remove the column.
			//Note that the column is in the table view in the nib, so it is in the table view before we have been configured for the first time.
			//And be sure to retain it before removing it from the view.
			[tableColumn_contacts retain];
			[tableView_accounts removeTableColumn:tableColumn_contacts];
			//Set both of the table view's columns to be the same width.
			float columnWidth = [tableView_accounts frame].size.width / 2.0;
			[[tableView_accounts tableColumns] setValue:[NSNumber numberWithFloat:columnWidth] forKey:@"width"];
			[tableView_accounts tile];

			contactsColumnIsInAccountsTableView = NO;
		}

		//Switch to the new list object.
		[listObject release];
		listObject = [inObject retain];

		//Rebuild our account list.
		[self updateAccountList];
	}
}

- (void)getAccounts:(NSArray **)outAccounts withContacts:(NSArray **)outContacts forListContact:(AIListContact *)listContact
{
	//Build a list of all accounts (compatible with the service of the input contact) that have the input contact's UID on their contact list.
	AIService		*service = [listContact service];
	NSString		*UID = [listContact UID];
	
	NSArray			*compatibleAccounts = [[adium accountController] accountsCompatibleWithService:service];
	NSMutableArray	*foundAccounts = [[NSMutableArray alloc] initWithCapacity:[compatibleAccounts count]];
	NSMutableArray	*contactTimesN = [[NSMutableArray alloc] initWithCapacity:[compatibleAccounts count]];

	id <AIContactController> contactController = [adium contactController];
	NSEnumerator *compatibleAccountsEnum = [compatibleAccounts objectEnumerator];
	AIAccount *account;
	while ((account = [compatibleAccountsEnum nextObject])) {
		AIListContact *contactOnThisAccount;
		if ((contactOnThisAccount = [contactController existingContactWithService:service account:account UID:UID]) &&
			[contactOnThisAccount remoteGroupName]) {
			[foundAccounts addObject:account];
			[contactTimesN addObject:contactOnThisAccount];
		}
	}
	
	if (outAccounts) *outAccounts = [foundAccounts autorelease];
	if (outContacts) *outContacts = [contactTimesN autorelease];
}

/*!
 * @brief Update our list of accounts
 */
- (void)updateAccountList
{
	//Get the new accounts
	[accounts release];
	[contacts release];

	if ([listObject isKindOfClass:[AIMetaContact class]]) {
		//Get all contacts of the metacontact.
		//Sort them by account.
		//Get the account of each contact.
		//Finally, uniquify the accounts through a set.
		NSMutableArray	*workingAccounts = [NSMutableArray array];
		NSMutableArray	*workingContacts = [NSMutableArray array];
		NSEnumerator	*enumerator;
		AIListContact	*listContact;
		enumerator = [[[(AIMetaContact *)listObject listContacts] sortedArrayUsingFunction:compareContactsByTheirAccounts
																				   context:NULL] objectEnumerator];
		while ((listContact = [enumerator nextObject])) {
			NSArray *thisContactAccounts;
			NSArray *thisContactContacts;
			
			[self getAccounts:&thisContactAccounts withContacts:&thisContactContacts forListContact:listContact];
			[workingAccounts addObjectsFromArray:thisContactAccounts];
			[workingContacts addObjectsFromArray:thisContactContacts];
		}

		accounts = [workingAccounts retain];
		contacts = [workingContacts retain];

	} else if ([listObject isKindOfClass:[AIListContact class]]) {
		[self getAccounts:&accounts withContacts:&contacts forListContact:(AIListContact *)listObject];
		[accounts retain];
		[contacts retain];
	} else {
		accounts = nil;
		contacts = nil;
	}
	
	//Refresh our table
	[tableView_accounts reloadData];
}

/*!
 * @brief Update our list of groups
 */
- (void)updateGroupList
{
	//Get the new groups
	NSMenu		*groupMenu = [[adium contactController] menuOfAllGroupsInGroup:nil withTarget:self];
	[[[tableView_accounts tableColumnWithIdentifier:@"group"] dataCell] setMenu:groupMenu];
	
	//Refresh our table
	[tableView_accounts reloadData];
}


//Table View Data Sources ----------------------------------------------------------------------------------------------
#pragma mark TableView Data Sources
/*!
 * @brief Number of table view rows
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [accounts count];
}

/*!
 * @brief Table view object value
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	id result = @"";

	NSString		*identifier = [tableColumn identifier];

	if ([identifier isEqualToString:@"account"]) {
		AIAccount		*account = [accounts objectAtIndex:row];
		NSString	*accountFormattedUID = [account formattedUID];
		
		if ([account online]) {
			result = accountFormattedUID;
			
		} else {
			//Gray the names of offline accounts
			NSDictionary		*attributes = [NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
			NSAttributedString	*string = [[NSAttributedString alloc] initWithString:accountFormattedUID attributes:attributes];
			result = [string autorelease];
		}
		
	} else if ([identifier isEqualToString:@"contact"]) {
		AIListObject *contact = [contacts objectAtIndex:row];
		result = [contact formattedUID];
	}
	
	return result;
}

/*!
 * @brief Table view will display a cell
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString		*identifier = [tableColumn identifier];
	AIAccount		*account;
	AIListContact	*exactContact;
	BOOL			accountOnline;
		
	account =  [accounts objectAtIndex:row];
	accountOnline = [account online];

	exactContact = [contacts objectAtIndex:row];				

	//Disable cells for offline accounts
	[cell setEnabled:accountOnline];
	
	//Select active group
	if ([identifier isEqualToString:@"group"]) {
		if (accountOnline) {
			AIListGroup	*group;
			
			if ((group = [[adium contactController] remoteGroupForContact:exactContact])) {
				[cell selectItemWithRepresentedObject:group];
			} else {
				[cell selectItemAtIndex:0];			
			}
		} else {
			[cell setTitle:AILocalizedString(@"(Unavailable)",nil)];
		}
	}
	
}

/*!
 * @brief Empty.  This method is the target of our menus, and needed for menu validation.
 */
- (void)selectGroup:(id)sender {};

/*!
 * @brief Table view set object value
 */
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString		*identifier = [tableColumn identifier];
	AIAccount		*account = [accounts objectAtIndex:row];
	AIListContact	*exactContact;
	
	if ([identifier isEqualToString:@"group"]) {
		NSMenu		*menu = [[tableColumn dataCell] menu];
		int			menuIndex = [object intValue];
		
		if (menuIndex >= 0 && menuIndex < [menu numberOfItems]) {
			AIListGroup	*group = [[menu itemAtIndex:menuIndex] representedObject];
			
			if ([listObject isKindOfClass:[AIMetaContact class]]) {
				//If we're dealing with a metaContact, make sure it's the topmost one
				exactContact = [(AIMetaContact *)listObject parentContact];
				
			} else {
				//Retrieve an AIListContact on this account
				exactContact = [[adium contactController] existingContactWithService:[listObject service]
																			 account:account
																				 UID:[listObject UID]];
			}
			
			if (group) {
				if (group != [exactContact containingObject]) {
					
					if (exactContact && ([exactContact containingObject] ||
										 [exactContact isKindOfClass:[AIMetaContact class]])) {
						//Move contact
						[[adium contactController] moveContact:exactContact intoObject:group];
						
					} else {
						//Add contact
						if (!exactContact) {
							exactContact = [[adium contactController] contactWithService:[listObject service]
																				 account:account
																					 UID:[listObject UID]];
						}
						
						[[adium contactController] addContacts:[NSArray arrayWithObject:exactContact] 
													   toGroup:group];
					}
				}
			} else {
				if (exactContact) {
					//User selected not listed, so we'll remove that contact
					[[adium contactController] removeListObjects:[NSArray arrayWithObject:exactContact]];
				}
			}
		}
	}
}

@end

static NSComparisonResult compareContactsByTheirAccounts(id firstContact, id secondContact, void *context) {
	NSComparisonResult result = [[firstContact account] compare:[secondContact account]];
	//If they have the same account, sort the contacts themselves within the account.
	if(result == NSOrderedSame) result = [firstContact compare:secondContact];
	return result;
}
