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

#import "AIAccountController.h"
#import "AIContactAccountsPane.h"
#import "AIContactController.h"
#import <AIUtilities/AIAlternatingRowTableView.h>
#import <AIUtilities/AIMenuAdditions.h>
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

@implementation AIContactAccountsPane

//Preference pane properties
- (CONTACT_INFO_CATEGORY)contactInfoCategory{
    return(AIInfo_Accounts);
}
- (NSString *)nibName{
    return(@"ContactAccounts");
}

//Configure the preference view
- (void)viewDidLoad
{
	[label_listedOnTheFollowingOfYourAccounts setStringValue:AILocalizedString(@"Listed on the following of your accounts:",nil)];

	//Configure Table view
	[tableView_accounts setDrawsAlternatingRows:YES];
	[tableView_accounts setAcceptsFirstMouse:YES];
	[[[tableView_accounts tableColumnWithIdentifier:@"account"] headerCell] setStringValue:AILocalizedString(@"On Account",nil)];
	[[[tableView_accounts tableColumnWithIdentifier:@"group"] headerCell] setStringValue:AILocalizedString(@"In Group",nil)];

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
}

//Preference view is closing
- (void)viewWillClose
{
	[accounts release]; accounts = nil;
    [listObject release]; listObject = nil;
	[[adium notificationCenter] removeObserver:self]; 
}

//Configure the pane for a list object
- (void)configureForListObject:(AIListObject *)inObject
{
	//New list object
	[listObject release];
	listObject = [inObject retain];

	//Rebuild our account list
	[self updateAccountList];
}

//Update our list of accounts
- (void)updateAccountList
{
	//Get the new accounts
	[accounts release];
	
	if ([listObject isKindOfClass:[AIMetaContact class]]){
		NSEnumerator	*enumerator;
		NSString		*serviceClass;
		
		accounts = [[NSMutableArray alloc] init];
		enumerator = [[(AIMetaContact *)listObject dictionaryOfServiceClassesAndListContacts] keyEnumerator];
		while (serviceClass = [enumerator nextObject]){
			[(NSMutableArray *)accounts addObjectsFromArray:[[adium accountController] accountsWithServiceClass:serviceClass]];
		}
		
	}else{
		accounts = [[[adium accountController] accountsWithServiceClassOfService:[listObject service]] retain];
	}
	
	//Refresh our table
	[tableView_accounts reloadData];
}

//Update our list of groups
- (void)updateGroupList
{
	//Get the new groups
	NSMenu		*groupMenu = [[adium contactController] menuOfAllGroupsInGroup:nil withTarget:self];
	NSMenuItem	*unlistedItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"(Not Listed)"
																					  target:self
																					  action:@selector(selectGroup:)
																			   keyEquivalent:@""] autorelease];
	[groupMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
	[groupMenu insertItem:unlistedItem atIndex:0];
	
	[[[tableView_accounts tableColumnWithIdentifier:@"group"] dataCell] setMenu:groupMenu];
	
	//Refresh our table
	[tableView_accounts reloadData];
}


//Table View Data Sources ----------------------------------------------------------------------------------------------
#pragma mark TableView Data Sources
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([accounts count]);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString		*identifier = [tableColumn identifier];
	AIAccount		*account = [accounts objectAtIndex:row];

	if([identifier isEqualToString:@"account"]){
		NSString	*accountFormattedUID = [account formattedUID];
		
		if([account integerStatusObjectForKey:@"Online"]){
			return(accountFormattedUID);
			
		}else{
			//Gray the names of offline accounts
			NSDictionary		*attributes = [NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
			NSAttributedString	*string = [[NSAttributedString alloc] initWithString:accountFormattedUID attributes:attributes];
			return([string autorelease]);
		}
		
	}
	
	return(@"");
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString		*identifier = [tableColumn identifier];
	AIAccount		*account;
	AIListContact	*exactContact;
	BOOL			accountOnline;
		
	account =  [accounts objectAtIndex:row];
	if ([listObject isKindOfClass:[AIMetaContact class]]){
		//If we're dealing with a metaContact, make sure it's the topmost one
		exactContact = (AIListContact *)[[adium contactController] parentContactForListObject:listObject];

	}else{
		//Retrieve an AIListContact on this account
		exactContact = [[adium contactController] existingContactWithService:[listObject service]
																	 account:account
																		 UID:[listObject UID]];
	}
				
	accountOnline = [account online];

	//Disable cells for offline accounts
	[cell setEnabled:accountOnline];
	
	//Select active group
	if([identifier isEqualToString:@"group"]){
		if(accountOnline){
			AIListGroup	*group;
			
			if(group = [[adium contactController] remoteGroupForContact:exactContact]){
				[cell selectItemWithRepresentedObject:group];
			}else{
				[cell selectItemAtIndex:0];			
			}
		}else{
			[cell setTitle:@"(Unavailable)"];
		}
	}
	
}

- (void)selectGroup:(id)sender
{
	//Empty.  This method is the target of our menus, and needed for menu validation.
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString		*identifier = [tableColumn identifier];
	AIAccount		*account = [accounts objectAtIndex:row];
	AIListContact	*exactContact;
	
	if([identifier isEqualToString:@"group"]){
		NSMenu		*menu = [[tableColumn dataCell] menu];
		int			menuIndex = [object intValue];
		
		if(menuIndex >= 0 && menuIndex < [menu numberOfItems]){
			AIListGroup	*group = [[menu itemAtIndex:menuIndex] representedObject];
			
			if ([listObject isKindOfClass:[AIMetaContact class]]){
				//If we're dealing with a metaContact, make sure it's the topmost one
				exactContact = (AIListContact *)[[adium contactController] parentContactForListObject:listObject];
				
			}else{
				//Retrieve an AIListContact on this account
				exactContact = [[adium contactController] existingContactWithService:[listObject service]
																			 account:account
																				 UID:[listObject UID]];
			}
			
			if (group){
				if (group != [exactContact containingObject]){
					
					if (exactContact && ([exactContact containingObject] ||
										 [exactContact isKindOfClass:[AIMetaContact class]])){
						//Move contact
						[[adium contactController] moveContact:exactContact toGroup:group];
						
					}else{
						//Add contact
						if (!exactContact){
							exactContact = [[adium contactController] contactWithService:[listObject service]
																				 account:account
																					 UID:[listObject UID]];
						}
						
						[[adium contactController] addContacts:[NSArray arrayWithObject:exactContact] 
													   toGroup:group];
					}
				}
			}else{
				if(exactContact){
					//User selected not listed, so we'll remove that contact
					[[adium contactController] removeListObjects:[NSArray arrayWithObject:exactContact]];
				}
			}
		}
	}
}

@end
