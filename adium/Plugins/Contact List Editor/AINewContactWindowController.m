/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AINewContactWindowController.h"

#define ADD_CONTACT_PROMPT_NIB	@"AddContact"

@interface AINewContactWindowController (PRIVATE)
- (void)buildContactTypeMenu;
- (void)buildGroupMenu;
- (void)_buildGroupMenu:(NSMenu *)menu forGroup:(AIListGroup *)group level:(int)level;
- (void)validateEnteredName;
- (void)updateAccountList;
- (void)configureNameAndService;
- (void)setContactName:(NSString *)contact;
- (void)setServiceID:(NSString *)inServiceID;
- (void)selectGroup:(id)sender;
@end

@implementation AINewContactWindowController

//Prompt for a new user.  Pass nil for a panel prompt. Include a particular name if you wish.
+ (void)promptForNewContactOnWindow:(NSWindow *)parentWindow name:(NSString *)contact serviceID:(NSString *)inServiceID
{
	AINewContactWindowController	*newContactWindow;
	
	newContactWindow = [[self alloc] initWithWindowNibName:ADD_CONTACT_PROMPT_NIB];
	[newContactWindow setContactName:contact];
	[newContactWindow setServiceID:inServiceID];
		
	if(parentWindow){
		[NSApp beginSheet:[newContactWindow window]
		   modalForWindow:parentWindow
			modalDelegate:newContactWindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[newContactWindow showWindow:nil];
	}
	
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];
	accounts = nil;
	contactName = nil;
	serviceID = nil;
	
    return(self);
}

//Dealloc
- (void)dealloc
{
	[accounts release];
	[contactName release];
	[serviceID release];
	
    [super dealloc];
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[self buildContactTypeMenu];
	[self buildGroupMenu];

	[[adium notificationCenter] addObserver:self
								   selector:@selector(updateAccountList)
									   name:Account_ListChanged
									 object:nil];

	[self configureNameAndService];
	
	[[self window] center];
}

//Window is closing
- (BOOL)windowShouldClose:(id)sender
{
	[[adium notificationCenter] removeObserver:self];
	
    return(YES);
}

//Stop automatic window positioning
- (BOOL)shouldCascadeWindows
{
    return(NO);
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Called as the user list edit sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

//Cancel
- (IBAction)cancel:(id)sender
{
	if([[self window] isSheet]){
		[NSApp endSheet:[self window]];
	}else{
		[self closeWindow:nil];
	}
}

//Add the contact
- (IBAction)addContact:(id)sender
{
	AIServiceType	*serviceType = [[popUp_contactType selectedItem] representedObject];
	NSString		*currentServiceID = [serviceType identifier];
	NSString		*UID = [textField_contactName stringValue];
	NSEnumerator	*enumerator = [accounts objectEnumerator];
	AIAccount		*account;
	
	while(account = [enumerator nextObject]){
		if([account conformsToProtocol:@protocol(AIAccount_List)] &&
		   [(AIAccount<AIAccount_List> *)account contactListEditable] &&
		   [[account preferenceForKey:KEY_ADD_CONTACT_TO group:PREF_GROUP_ADD_CONTACT] boolValue]){
			AIListContact	*contact = [[adium contactController] contactWithService:currentServiceID
																		   accountID:[account uniqueObjectID]
																				 UID:UID];
			[[adium contactController] addContacts:[NSArray arrayWithObject:contact]
										   toGroup:[[popUp_targetGroup selectedItem] representedObject]];
		}
	}
	
	if([[self window] isSheet]){
		[NSApp endSheet:[self window]];
	}else{
		[self closeWindow:nil];
	}
}


//Service Type ---------------------------------------------------------------------------------------------------------
#pragma mark Service Type
//Build the menu of contact service types
- (void)buildContactTypeMenu
{
	NSEnumerator		*enumerator;
	AIServiceType		*serviceType;

	//Empty the menu
	[popUp_contactType removeAllItems];
	
	//Add an item for each service
	enumerator = [[[adium accountController] activeServiceTypes] objectEnumerator];
	while(serviceType = [enumerator nextObject]){
		[[popUp_contactType menu] addItemWithTitle:[serviceType description]
											target:self
											action:@selector(selectServiceType:)
									 keyEquivalent:@""
								 representedObject:serviceType];
		
	}
	[[popUp_contactType menu] update];
	enumerator = [[popUp_contactType itemArray] objectEnumerator];
	NSMenuItem			*menuItem;
	while(menuItem = [enumerator nextObject]) {
		if([menuItem isEnabled]) {
			[popUp_contactType selectItem:menuItem];
			break;
		}
	}
	
}

//Service type selected from the menu
- (void)selectServiceType:(id)sender
{
	[self updateAccountList];
	[self validateEnteredName];
}


//Add to Group ---------------------------------------------------------------------------------------------------------
#pragma mark Add to Group
//Build the menu of available destination groups
- (void)buildGroupMenu
{
	AIListObject	*selectedObject;
	AIListGroup		*group;
	
	//Rebuild the menu
	[popUp_targetGroup setMenu:[[adium contactController] menuOfAllGroupsInGroup:nil withTarget:self]];

	//Select the group of the currently selected object on the contact list
	selectedObject = [[adium contactController] selectedListObject];

	if(selectedObject != nil) {
		if([selectedObject isKindOfClass:[AIListGroup class]]){
			group = (AIListGroup*)selectedObject;
		}else{
			group = [selectedObject containingGroup];
		}
		
		if(group){
			[popUp_targetGroup selectItemWithRepresentedObject:group];			
		}else if([popUp_targetGroup numberOfItems] > 0){
			[popUp_targetGroup selectItemAtIndex:0];
		}
		
	}
}


//Contact Name ---------------------------------------------------------------------------------------------------------
#pragma mark Contact Name
//Fill in the name field if we came from a tab
- (void)configureNameAndService
{
	if(contactName) {
		[textField_contactName setStringValue:contactName];
	}
	
	if(serviceID){
		NSMenuItem		*item;
		NSEnumerator	*enumerator = [[popUp_contactType itemArray] objectEnumerator];
		
		while (item = [enumerator nextObject]){
			if ([[[item representedObject] identifier] isEqualToString:serviceID]){
				[popUp_contactType selectItem:item];
				break;
			}
		}
	}
	
	[self updateAccountList];
	[self validateEnteredName];
}

- (void)setContactName:(NSString *)contact
{
	[contactName release];
	contactName = [contact retain];
}

- (void)setServiceID:(NSString *)inServiceID
{
	[serviceID release];
	serviceID = [inServiceID retain];
}

//Entered name is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	if([notification object] == textField_contactName){
		[self validateEnteredName];
	}
}

//Validate the entered name, enabling the add button if it is valid
- (void)validateEnteredName
{
	NSString		*name = [textField_contactName stringValue];
	AIServiceType	*serviceType = [[popUp_contactType selectedItem] representedObject];
	BOOL			enabled = YES;
	
	if([name length] != 0 && [name length] < [serviceType allowedLength]){
		BOOL		caseSensitive = [serviceType caseSensitive];
		NSScanner	*scanner = [NSScanner scannerWithString:(caseSensitive ? name : [name lowercaseString])];
		NSString	*validSegment = nil;
		
		[scanner scanCharactersFromSet:[serviceType allowedCharacters] intoString:&validSegment];
		if(!validSegment || [validSegment length] != [name length]){
			enabled = NO;
		}
	}else{
		enabled = NO;
	}
	
	
	//If enabled so far, make sure an account is checked
	if (enabled){
		NSEnumerator	*enumerator = [accounts objectEnumerator];
		AIAccount		*account;
		
		BOOL anAccountIsChecked = NO;
		
		while(account = [enumerator nextObject]){
			if([account conformsToProtocol:@protocol(AIAccount_List)] &&
			   [(AIAccount<AIAccount_List> *)account contactListEditable] &&
			   [[account preferenceForKey:KEY_ADD_CONTACT_TO group:PREF_GROUP_ADD_CONTACT] boolValue]){
				anAccountIsChecked = YES;
				break;
			}
		}	
		
		enabled = anAccountIsChecked;
	}
	
	
	[button_add setEnabled:enabled];
}


//Add to Accounts ------------------------------------------------------------------------------------------------------
#pragma mark Add to Accounts
//Update the accounts list
- (void)updateAccountList
{
	AIServiceType	*serviceType = [[popUp_contactType selectedItem] representedObject];
	
	NSEnumerator	*enumerator;
	AIAccount		*account;
	NSNumber		*addTo;
	
	[accounts release];
	accounts = [[[adium accountController] accountsWithServiceID:[serviceType identifier]] retain];
	
	//Select accounts by default
	enumerator = [accounts objectEnumerator];
	while(account = [enumerator nextObject]) {
		addTo = [account preferenceForKey:KEY_ADD_CONTACT_TO group:PREF_GROUP_ADD_CONTACT];
		if(!addTo)
			[account setPreference:[NSNumber numberWithBool:YES] forKey:KEY_ADD_CONTACT_TO 
							 group:PREF_GROUP_ADD_CONTACT];
	}
	[tableView_accounts reloadData];
}

//
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([accounts count]);
}

//
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString	*identifier = [tableColumn identifier];
	
	if([identifier isEqualToString:@"check"]){
		return([[accounts objectAtIndex:row] contactListEditable] ?
			   [[accounts objectAtIndex:row] preferenceForKey:KEY_ADD_CONTACT_TO 
														group:PREF_GROUP_ADD_CONTACT] :
			   [NSNumber numberWithBool:NO]);
	}else if([identifier isEqualToString:@"account"]){
		return([[accounts objectAtIndex:row] formattedUID]);
	}else{
		return(@"");
	}
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	[cell setEnabled:[[accounts objectAtIndex:row] contactListEditable]];
}

//
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString	*identifier = [tableColumn identifier];

	if([identifier isEqualToString:@"check"]){
		[[accounts objectAtIndex:row] setPreference:[NSNumber numberWithBool:[object boolValue]] 
											 forKey:KEY_ADD_CONTACT_TO 
											  group:PREF_GROUP_ADD_CONTACT];
		[self validateEnteredName];
	}
}

//I don't want the table to display it's selection.
//Returning NO from 'shouldSelectRow' would work, but if we do that
//the checkbox cells stop working.  The best solution I've come up with
//so far is to just force a deselect here :( .
- (void)tableViewSelectionIsChanging:(NSNotification *)notification{
	[tableView_accounts deselectAll:nil];
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification{
	[tableView_accounts deselectAll:nil];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if([[menuItem representedObject] isKindOfClass:[AIServiceType class]]) {
		AIServiceType   *serviceType = [menuItem representedObject];
		NSEnumerator	*enumerator;
		AIAccount		*account;
		
		enumerator = [[[adium accountController] accountsWithServiceID:[serviceType identifier]] objectEnumerator];
		while(account = [enumerator nextObject]) {
			if([account conformsToProtocol:@protocol(AIAccount_List)] &&
			   [(AIAccount<AIAccount_List> *)account contactListEditable]) {
				return YES;
			}
		}
		return NO;
	}
	return YES;
}

- (void)selectGroup:(id)sender
{
}

@end

