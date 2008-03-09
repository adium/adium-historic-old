//
//  AIAdvancedInspectorPane.m
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AIAdvancedInspectorPane.h"

#define ADVANCED_NIB_NAME (@"AIAdvancedInspectorPane")

static NSComparisonResult compareContactsByTheirAccounts(id firstContact, id secondContact, void *context);

@interface AIAdvancedInspectorPane(PRIVATE)
- (void)updateAccountList;
- (void)updateGroupList;
-(void)reloadPopup;
@end

@implementation AIAdvancedInspectorPane

- (id) init
{
	self = [super init];
	if (self != nil) {
		[NSBundle loadNibNamed:[self nibName] owner:self];
		
		//Load Encryption menus
		[encryptionButton setMenu:[[adium contentController] encryptionMenuNotifyingTarget:self withDefault:YES]];
		[[encryptionButton menu] setAutoenablesItems:NO];
		
		//Table view setup methods
		[accountsLabel setLocalizedString:AILocalizedString(@"Accounts:",nil)];
				
		//Configure Table view
		[accountsTableView setUsesAlternatingRowBackgroundColors:YES];
		[accountsTableView setAcceptsFirstMouse:YES];

		//[[[accountsTableView tableColumnWithIdentifier:@"account"] headerCell] setTitle:AILocalizedString(@"Account",nil)];
		[[[accountsTableView tableColumnWithIdentifier:@"contact"] headerCell] setTitle:AILocalizedString(@"Contact","This header for the table in the Accounts tab of the Get Info window indicates the name of the contact within a metacontact")];
		[[[accountsTableView tableColumnWithIdentifier:@"group"] headerCell] setTitle:AILocalizedString(@"Group",nil)];
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
	
		[accountsTableView sizeToFit];
	}
	
	return self;
}

- (void) dealloc
{
	[accounts release]; accounts = nil;
	[contacts release]; contacts = nil;
    [displayedObject release]; displayedObject = nil;
	[[adium notificationCenter] removeObserver:self]; 
	[super dealloc];
}


-(NSString *)nibName
{
	return ADVANCED_NIB_NAME;
}

-(NSView *)inspectorContentView
{
	return inspectorContentView;
}

-(void)updateForListObject:(AIListObject *)inObject
{
	//TODO: Figure out why group changes aren't being applied properly.
	//TODO: Figure out why the width of the table view keeps growing.
	if (displayedObject != inObject) {
		//Update the table view to have or not have the "Individual Contact" column, as appropriate.
		//It should have the column when our list object is a metacontact.
		if ([inObject isKindOfClass:[AIMetaContact class]]) {
			if (!contactsColumnIsInAccountsTableView) {
				//Add the column.
				[accountsTableView addTableColumn:contactsColumn];
				//It was added as last; move to the middle.
				[accountsTableView moveColumn:1 toColumn:0];
				//Set all of the table view's columns to be the same width.
				float columnWidth = [accountsTableView frame].size.width / 2.0;
				//NSLog(@"Setting columnWidth to: %f / 2.0 == %f", [accountsTableView frame].size.width, columnWidth);
				[[accountsTableView tableColumns] setValue:[NSNumber numberWithFloat:columnWidth] forKey:@"width"];
				[accountsTableView sizeToFit];
				//We don't need it retained anymore.
				[contactsColumn release];

				contactsColumnIsInAccountsTableView = YES;
			}
		} else if(contactsColumnIsInAccountsTableView) {
			//Remove the column.
			//Note that the column is in the table in the nib, so it is in the table view before we have been configured for the first time.
			//And be sure to retain it before removing it from the view.
			[contactsColumn retain];
			[accountsTableView removeTableColumn:contactsColumn];
			//Set both of the table view's columns to be the same width.
			float columnWidth = [accountsTableView frame].size.width;
			//NSLog(@"Setting columnWidth to: %f", [accountsTableView frame].size.width);
			[[accountsTableView tableColumns] setValue:[NSNumber numberWithFloat:columnWidth] forKey:@"width"];
			[accountsTableView sizeToFit];

			contactsColumnIsInAccountsTableView = NO;
		}
	
		[displayedObject release];
		displayedObject = ([inObject isKindOfClass:[AIListContact class]] ?
					[(AIListContact *)inObject parentContact] :
					inObject);
		[displayedObject retain];
		
		//Rebuild the account list
		[self updateAccountList];
	}
	
	NSNumber *encryption;
	
	encryption = [inObject preferenceForKey:KEY_ENCRYPTED_CHAT_PREFERENCE group:GROUP_ENCRYPTION];
	
	if(!encryption) {
		[encryptionButton compatibleSelectItemWithTag:EncryptedChat_Default];
	}
	
	[encryptionButton compatibleSelectItemWithTag:[encryption intValue]];
	
	[visibilityButton setEnabled:![inObject isKindOfClass:[AIListGroup class]]];
	[visibilityButton setState:[inObject alwaysVisible]];
}

- (IBAction)selectedEncryptionPreference:(id)sender
{
	if(!displayedObject)
		return;
	[displayedObject setPreference:[NSNumber numberWithInt:[sender tag]] 
							forKey:KEY_ENCRYPTED_CHAT_PREFERENCE 
							group:GROUP_ENCRYPTION];
}

- (IBAction)setVisible:(id)sender
{
	if(!displayedObject)
		return;
	
	[displayedObject setAlwaysVisible:[visibilityButton state]];
}

#pragma mark Accounts Table View methods
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

	if ([displayedObject isKindOfClass:[AIMetaContact class]]) {
		//Get all contacts of the metacontact.
		//Sort them by account.
		//Get the account of each contact.
		//Finally, uniquify the accounts through a set.
		NSMutableArray	*workingAccounts = [NSMutableArray array];
		NSMutableArray	*workingContacts = [NSMutableArray array];
		NSEnumerator	*enumerator;
		AIListContact	*listContact;
		enumerator = [[[(AIMetaContact *)displayedObject listContacts] sortedArrayUsingFunction:compareContactsByTheirAccounts
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

	} else if ([displayedObject isKindOfClass:[AIListContact class]]) {
		[self getAccounts:&accounts withContacts:&contacts forListContact:(AIListContact *)displayedObject];
		[accounts retain];
		[contacts retain];
	} else {
		accounts = nil;
		contacts = nil;
	}
	
	//Refresh our table
	[self reloadPopup];
	[accountsTableView reloadData];
}

/*!
 * @brief Update our list of groups
 */
- (void)updateGroupList
{
	//Get the new groups
	NSMenu		*groupMenu = [[adium contactController] menuOfAllGroupsInGroup:nil withTarget:self];
	[[[accountsTableView tableColumnWithIdentifier:@"group"] dataCell] setMenu:groupMenu];
	
	//Refresh our table
	[accountsTableView reloadData];
}

//

-(void)reloadPopup
{
	//Remove all entries from current popup.
	[accountsButton removeAllItems];
	
	//Enumerate through accounts and add each one to the popup button.
	id currentAccount = nil;
	NSEnumerator *accountEnumerator = [accounts objectEnumerator];
	
	while((currentAccount = [accountEnumerator nextObject])) {
		NSString *accountUID = [(AIAccount *)currentAccount UID];
		[accountsButton addItemWithTitle:accountUID];
	}
}

-(IBAction)selectAccount:(id)sender
{
	//int selectedAccount = [sender indexOfSelectedItem];
	
	[self updateGroupList];
}

#pragma mark Accounts Table View Data Sources

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

	//if ([identifier isEqualToString:@"account"]) {
//		AIAccount		*account = [accounts objectAtIndex:row];
//		NSString	*accountFormattedUID = [account formattedUID];
//		
//		if ([account online]) {
//			result = accountFormattedUID;
//			
//		} else {
//			//Gray the names of offline accounts
//			NSDictionary		*attributes = [NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
//			NSAttributedString	*string = [[NSAttributedString alloc] initWithString:accountFormattedUID attributes:attributes];
//			result = [string autorelease];
//		}
		
	/*} else*/ if ([identifier isEqualToString:@"contact"]) {
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
		
	//account =  [accounts objectAtIndex:row];
	account = [accounts objectAtIndex:[accountsButton indexOfSelectedItem]];
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
	AIAccount		*account = [accounts objectAtIndex:[accountsButton indexOfSelectedItem]];
	AIListContact	*exactContact;
	
	if ([identifier isEqualToString:@"group"]) {
		NSMenu		*menu = [[tableColumn dataCell] menu];
		int			menuIndex = [object intValue];
		
		if (menuIndex >= 0 && menuIndex < [menu numberOfItems]) {
			AIListGroup	*group = [[menu itemAtIndex:menuIndex] representedObject];
			
			if ([displayedObject isKindOfClass:[AIMetaContact class]]) {
				//If we're dealing with a metaContact, make sure it's the topmost one
				exactContact = [(AIMetaContact *)displayedObject parentContact];
				
			} else {
				//Retrieve an AIListContact on this account
				exactContact = [[adium contactController] existingContactWithService:[displayedObject service]
																			 account:account
																				 UID:[displayedObject UID]];
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
							exactContact = [[adium contactController] contactWithService:[displayedObject service]
																				 account:account
																					 UID:[displayedObject UID]];
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

static NSComparisonResult compareContactsByTheirAccounts(id firstContact, id secondContact, void *context) {
	NSComparisonResult result = [[firstContact account] compare:[secondContact account]];
	//If they have the same account, sort the contacts themselves within the account.
	if(result == NSOrderedSame) result = [firstContact compare:secondContact];
	return result;
}

@end
