//
//  AIContactAccountsPane.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 14 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIContactAccountsPane.h"

@interface AIContactAccountsPane (PRIVATE)
- (void)updateAccountList;
- (void)updateGroupList;
@end

@implementation AIContactAccountsPane

//Preference pane properties
- (CONTACT_INFO_CATEGORY)contactInfoCategory{
    return(AIInfo_Accounts);
}
- (NSString *)label{
    return(@"Contact Accounts");
}
- (NSString *)nibName{
    return(@"ContactAccounts");
}

//Configure the preference view
- (void)viewDidLoad
{
	//Configure Table view
	[tableView_accounts setDrawsAlternatingRows:YES];
	[tableView_accounts setAcceptsFirstMouse:YES];
	
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
	accounts = [[[adium accountController] accountsWithServiceID:[listObject serviceID]] retain];
	
	//Refresh our table
	[tableView_accounts reloadData];
}

//Update our list of groups
- (void)updateGroupList
{
	//Get the new groups
	NSMenu		*groupMenu = [[adium contactController] menuOfAllGroupsInGroup:nil withTarget:self];
	NSMenuItem	*unlistedItem = [[[NSMenuItem alloc] initWithTitle:@"(Not Listed)"
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
	AIAccount		*account = [accounts objectAtIndex:row];
	AIListContact	*existing = [[adium contactController] existingContactWithService:[listObject serviceID]
																			accountID:[account uniqueObjectID]
																				  UID:[listObject UID]];
	BOOL			accountOnline = ([account integerStatusObjectForKey:@"Online"]);
	
	
	//Disable cells for offline accounts
	[cell setEnabled:accountOnline];
	
	//Select active group
	if([identifier isEqualToString:@"group"]){
		if(accountOnline){
			//Get the containing group (taking into account meta contacts)
			AIListGroup	*group = [existing containingObject];
			while ([group isKindOfClass:[AIMetaContact class]]){
				group = [group containingObject];
			}

			if(group){
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
	AIListContact	*existing = [[adium contactController] existingContactWithService:[listObject serviceID]
																			accountID:[account uniqueObjectID]
																				  UID:[listObject UID]];
	
	if([identifier isEqualToString:@"group"]){
		NSMenu		*menu = [[tableColumn dataCell] menu];
		int			menuIndex = [object intValue];
		
		if(menuIndex >= 0 && menuIndex < [menu numberOfItems]){
			AIListGroup	*group = [[menu itemAtIndex:menuIndex] representedObject];
			
			if(group && (group != [listObject containingObject])){
				if(existing){ //Move contact
					[[adium contactController] addContacts:[NSArray arrayWithObject:existing] toGroup:group];

				}else{ //Add contact
					AIListContact	*contact = [[adium contactController] contactWithService:[listObject serviceID]
																				   accountID:[account uniqueObjectID]
																						 UID:[listObject UID]];
					[[adium contactController] addContacts:[NSArray arrayWithObject:contact] toGroup:group];

				}
				
			}else if (!group){
				//User selected not listed, so we'll remove that contact
				if(existing){
					[[adium contactController] removeListObjects:[NSArray arrayWithObject:existing]];
				}
			}
		}
	}
}

@end
