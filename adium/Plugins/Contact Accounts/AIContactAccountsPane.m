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
//	AIImageTextCell *actionsCell;
//	
	//Configure Table view
	[tableView_accounts setDrawsAlternatingRows:YES];
//    [tableView_actions setTarget:self];
//    [tableView_actions setDoubleAction:@selector(editAlert:)];
//	actionsCell = [[[AIImageTextCell alloc] init] autorelease];
//    [actionsCell setFont:[NSFont systemFontOfSize:12]];
//	[actionsCell setIgnoresFocus:YES];
//	[[tableView_actions tableColumnWithIdentifier:@"description"] setDataCell:actionsCell];
	
	
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
	AIListContact	*existing = [[adium contactController] existingContactWithService:[listObject serviceID]
																			accountID:[account uniqueObjectID]
																				  UID:[listObject UID]];

	if([identifier isEqualToString:@"check"]){
		return([NSNumber numberWithBool:(existing != nil)]);
		
	}else if([identifier isEqualToString:@"account"]){
		return([account displayName]);

	}else{// if([identifier isEqualToString:@"group"]){
		return([existing containingGroup]);

	}

}


@end
