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

#import "AIAccountListPreferences.h"

#define	ACCOUNT_DRAG_TYPE					@"AIAccount"	    										//ID for an account drag
#define	ACCOUNT_CONNECT_BUTTON_TITLE		AILocalizedString(@"Connect","Connect an account")	    	//Menu item title for the connect item
#define	ACCOUNT_DISCONNECT_BUTTON_TITLE		AILocalizedString(@"Disconnect","Disconnect an account")    //Menu item title
#define	ACCOUNT_CONNECTING_BUTTON_TITLE		AILocaliedString(@"Connecting…",nil)						//Menu item title
#define	ACCOUNT_DISCONNECTING_BUTTON_TITLE	AILocalizedString(@"Disconnecting…",nil)					//Menu item title

@interface AIAccountListPreferences (PRIVATE)
- (void)buildServicePopup;
- (void)configureViewForAccount:(AIAccount *)inAccount;
- (void)configureViewForService:(id <AIServiceController>)inService;
- (void)_addCustomViewAndTabsForController:(AIAccountViewController *)inControler;
- (void)_removeCustomViewAndTabs;
- (void)enableDisableControls;
- (void)configureAccountList;
- (void)accountListChanged:(NSNotification *)notification;
@end

@implementation AIAccountListPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Accounts);
}
- (NSString *)label{
    return(AILocalizedString(@"Accounts",nil));
}
- (NSString *)nibName{
    return(@"AccountPrefView");
}

//Configure the preference view
- (void)viewDidLoad
{
    //init
    accountViewController = nil;
    view_accountPreferences = nil;
	configuredForService = nil;
	configuredForAccount = nil;
    
	//Disable the unavailable controls
	[self enableDisableControls];

	//
	[self buildServicePopup];
	[self configureAccountList];

	//Observe account list objects so we can enable/disable our controls for connected accounts
    [[adium contactController] registerListObjectObserver:self];
}

//Preference view is closing
- (void)viewWillClose
{
	//Get any final changes to the UID field
	[textField_accountName fireImmediately];
	
    [[adium contactController] unregisterListObjectObserver:self];
    [view_accountPreferences release]; view_accountPreferences = nil;
    [accountViewController release]; accountViewController = nil;
    [[adium notificationCenter] removeObserver:self];
}

//Build the popup of available services
- (void)buildServicePopup
{
    NSEnumerator				*enumerator;
    id <AIServiceController>	service;
	
    [popupMenu_serviceList removeAllItems];
	enumerator = [[[adium accountController] availableServices] objectEnumerator];
	while((service = [enumerator nextObject])){
        NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:[service description]
														target:self 
														action:@selector(selectServiceType:) 
												 keyEquivalent:@""] autorelease];
        [item setRepresentedObject:service];
        [[popupMenu_serviceList menu] addItem:item];
    }
}


//Configuring ---------------------------------------------------------------------------------------------
#pragma mark Configuring
//Configure the account preferences for an account
- (void)configureViewForAccount:(AIAccount *)inAccount
{
	//If necessary, configure for the account's service first
	if([inAccount service] != configuredForService){
		[self configureViewForService:[inAccount service]];
	}

	//Configure for the account
	configuredForAccount = inAccount;
	[accountViewController configureForAccount:inAccount];
	[self enableDisableControls];

	//Fill in the account's name and auto-connect status
	NSString	*formattedUID = [inAccount preferenceForKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS];
	[textField_accountName setStringValue:(formattedUID && [formattedUID length] ? formattedUID : [inAccount UID])];
    [button_autoConnect setState:[[inAccount preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue]];
}

//Configure the account preferences for a service.  This determines which controls are loaded and the allowed values
- (void)configureViewForService:(id <AIServiceController>)inService
{
	AIServiceType	*serviceType = [inService handleServiceType];

	//Select the new service
	configuredForService = inService;
    [popupMenu_serviceList selectItemAtIndex:[popupMenu_serviceList indexOfItemWithRepresentedObject:inService]];
	
	//Insert the custom controls for this service
	[self _removeCustomViewAndTabs];
	[self _addCustomViewAndTabsForController:[inService accountView]];
	
	//Restrict the account name field to valid characters and length
    [textField_accountName setFormatter:
		[AIStringFormatter stringFormatterAllowingCharacters:[serviceType allowedCharacters]
													  length:[serviceType allowedLength]
											   caseSensitive:[serviceType caseSensitive]
												errorMessage:@"The characters you're entering are not valid for an account name on this service."]];
}

//Add the custom views for a controller
- (void)_addCustomViewAndTabsForController:(AIAccountViewController *)inControler
{
	NSView					*accountView;
	NSEnumerator			*enumerator;
	NSTabViewItem			*tabViewItem;
	
	//Get account view
	accountViewController = [inControler retain];
	accountView = [accountViewController view];
	
    //Swap in the account details view
    [view_accountDetails addSubview:accountView];
	float accountViewHeight = [accountView frame].size.height;
    [accountView setFrameOrigin:NSMakePoint(0,([view_accountDetails frame].size.height - accountViewHeight))];
	
    //Hook up the responder chain
    [popupMenu_serviceList setNextKeyView:[accountView nextKeyView]];
    NSView	*nextView = accountView;
    while([nextView nextKeyView]) nextView = [nextView nextKeyView];
    [nextView setNextKeyView:button_autoConnect];

	//Swap in the account auxiliary tabs
    enumerator = [[accountViewController auxiliaryTabs] objectEnumerator];
    while(tabViewItem = [enumerator nextObject]){
        [tabView_auxiliary addTabViewItem:tabViewItem];
    }
	
    //There must be a better way to do this.  When moving tabs over, they will stay selected - resulting in multiple
	//selected tabs.  My quick fix is to manually select each tab in the view.  Not the greatest, but it'll
	//work for now.
    [tabView_auxiliary selectLastTabViewItem:nil];
    int i;
    for(i = 1;i < [tabView_auxiliary numberOfTabViewItems];i++){
        [tabView_auxiliary selectPreviousTabViewItem:nil];
    }
}

//Remove any existing custom views
- (void)_removeCustomViewAndTabs
{
	int selectedTabIndex;
	
    //Remove any tabs
    if([tabView_auxiliary selectedTabViewItem]){
        selectedTabIndex = [tabView_auxiliary indexOfTabViewItem:[tabView_auxiliary selectedTabViewItem]];
    }
    while([tabView_auxiliary numberOfTabViewItems] > 1){
        [tabView_auxiliary removeTabViewItem:[tabView_auxiliary tabViewItemAtIndex:[tabView_auxiliary numberOfTabViewItems] - 1]];
    }
    
    //Close any currently open controllers
    [view_accountDetails removeAllSubviews];
    [accountViewController release]; accountViewController = nil;
}


//Controls -------------------------------------------------------------------------------------------------------------
#pragma mark Controls
//User changed the service of our account
- (IBAction)selectServiceType:(id)sender
{
	id <AIServiceController>	service = [sender representedObject];
	[[adium accountController] switchAccount:configuredForAccount toService:service];
}

- (IBAction)changeUIDField:(id)sender
{
	NSString *newUID = [textField_accountName stringValue];
	if (![[configuredForAccount UID] isEqualToString:newUID])
		[[adium accountController] changeUIDOfAccount:configuredForAccount to:newUID];	
}

//User toggled the autoconnect preference
- (IBAction)toggleAutoConnect:(id)sender
{
	BOOL	autoConnect = [sender state];
	
	[configuredForAccount setPreference:[NSNumber numberWithBool:autoConnect]
								 forKey:@"AutoConnect"
								  group:GROUP_ACCOUNT_STATUS];
}

//Disable controls for account that are connected
- (void)enableDisableControls
{
	[popupMenu_serviceList setEnabled:(configuredForAccount && ![[configuredForAccount statusObjectForKey:@"Online"] boolValue])];
	[textField_accountName setEnabled:(configuredForAccount && ![[configuredForAccount statusObjectForKey:@"Online"] boolValue])];
	[button_autoConnect setEnabled:(configuredForAccount != nil)];
	[button_deleteAccount setEnabled:([accountArray count] > 1 && configuredForAccount &&
									  ![[configuredForAccount statusObjectForKey:@"Online"] boolValue])];
}

//Account status changed.  Disable the service menu and user name field for connected accounts
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    if(inObject == configuredForAccount && [inModifiedKeys containsObject:@"Online"]){
		[self enableDisableControls];
    }
    
    return(nil);
}

//We need to make sure all changes to the account have been saved before a service switch occurs.
//This code is called when the service menu is opened, and takes focus away from the first responder,
//causing it to save any outstanding changes.
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	[[popupMenu_serviceList window] makeFirstResponder:popupMenu_serviceList];
}


//Account List ---------------------------------------------------------------------------------------------------------
#pragma mark Account List
//Configure the account list table
- (void)configureAccountList
{
    AIImageTextCell			*cell;
	
    //Configure our tableView
    cell = [[[AIImageTextCell alloc] init] autorelease];
    [cell setFont:[NSFont systemFontOfSize:12]];
    [[tableView_accountList tableColumnWithIdentifier:@"description"] setDataCell:cell];
    [tableView_accountList registerForDraggedTypes:[NSArray arrayWithObjects:ACCOUNT_DRAG_TYPE,nil]];
    [scrollView_accountList setAutoHideScrollBar:YES];
    
    //Configure our buttons
    [button_newAccount setImage:[AIImageUtilities imageNamed:@"plus" forClass:[self class]]];
    [button_deleteAccount setImage:[AIImageUtilities imageNamed:@"minus" forClass:[self class]]];
	
	//Keep an eye on list changes so we can update as necessary
    [[adium notificationCenter] addObserver:self
								   selector:@selector(accountListChanged:) 
									   name:Account_ListChanged 
									 object:nil];
	
	[self accountListChanged:nil];
}

//Account list changed, refresh our table
- (void)accountListChanged:(NSNotification *)notification
{
    //Update our reference to the accounts
    [accountArray release]; accountArray = [[[adium accountController] accountArray] retain];

    //Refresh the table (if the window is loaded)
    if(tableView_accountList != nil){
		[tableView_accountList reloadData];

		//Update selected account
		[self tableViewSelectionDidChange:nil];
    }

	[self enableDisableControls];
}

//Create a new account
- (IBAction)newAccount:(id)sender
{
    int		index = [tableView_accountList selectedRow] + 1;
    AIAccount	*newAccount;
    
    //Add the new account
    newAccount = [[adium accountController] newAccountAtIndex:index];
    
    //Select the new account
    [tableView_accountList selectRow:index byExtendingSelection:NO];
    
    //Select the 'Account' tab and put focus on the account fields
    [tabView_auxiliary selectTabViewItemAtIndex:0];
    [[popupMenu_serviceList window] makeFirstResponder:popupMenu_serviceList];
}

//Delete the selected account
- (IBAction)deleteAccount:(id)sender
{
    int 	index;
    AIAccount	*targetAccount;
    
    NSParameterAssert(accountArray != nil); NSParameterAssert([accountArray count] > 1);
    
    //Confirm
    index = [tableView_accountList selectedRow];
    NSParameterAssert(index >= 0 && index < [accountArray count]);
    targetAccount = [accountArray objectAtIndex:index];
    
    NSBeginAlertSheet(@"Delete Account",@"Delete",@"Cancel",@"",[view_accountPreferences window], self, 
					  @selector(deleteAccountSheetDidEnd:returnCode:contextInfo:), nil, targetAccount, 
					  @"Delete the account %@?", [targetAccount displayName]);
}

//Finishes the delete action when the sheet is closed
- (void)deleteAccountSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    AIAccount 	*targetAccount = contextInfo;
    int			index;
    
    NSParameterAssert(targetAccount != nil); NSParameterAssert([targetAccount isKindOfClass:[AIAccount class]]);
    
    if(returnCode == NSAlertDefaultReturn){
        //Delete it
        index = [accountArray indexOfObject:targetAccount];
        [[adium accountController] deleteAccount:targetAccount];
		
        //If it was the last row, select the new last row (by default the selection will jump to the top, which is bad)
        if(index >= [accountArray count]){
            index = [accountArray count]-1;
            [tableView_accountList selectRow:index byExtendingSelection:NO];
        }
        
        //Update our display
        [self tableViewSelectionDidChange:nil];
    }
}


//Account List Table Delegate ------------------------------------------------------------------------------------------
#pragma mark Account List (Table Delegate)
//Delete the selected row
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteAccount:nil]; //Delete them
}

//Return the number of accounts
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([accountArray count]);
}

//Return the account description or image
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    return([[accountArray objectAtIndex:row] formattedUID]);
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    AIAccount   *account = [accountArray objectAtIndex:row];
    NSImage		*image = [AIImageUtilities imageNamed:@"DefaultIcon" forClass:[self class]];
	
    [cell setImage:image];
    [cell setSubString:[account serviceID]];
	[cell setDrawsGradientHighlight:YES];
}

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    tempDragAccount = [accountArray objectAtIndex:[[rows objectAtIndex:0] intValue]];
	
    [pboard declareTypes:[NSArray arrayWithObject:ACCOUNT_DRAG_TYPE] owner:self];
    [pboard setString:@"Account" forType:ACCOUNT_DRAG_TYPE];
    
    return(YES);
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if(op == NSTableViewDropAbove && row != -1){
        return(NSDragOperationPrivate);
    }else{
        return(NSDragOperationNone);
    }
}

- (void)tableViewSelectionWillChange:(NSNotification *)notification
{
	//Make sure we get any final changes to the account name (this would require typing and then switching within half a second, but better safe than sorry.)
	[textField_accountName fireImmediately];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    int	selectedRow = [tableView_accountList selectedRow];
	
	if(selectedRow >= 0 && selectedRow < [accountArray count]){		
		[self configureViewForAccount:[accountArray objectAtIndex:selectedRow]];
    }
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ACCOUNT_DRAG_TYPE]];
	
    if([avaliableType compare:@"AIAccount"] == 0){
        int	newIndex;
        
        //Select the moved account
        newIndex = [[adium accountController] moveAccount:tempDragAccount toIndex:row];
        [tableView_accountList selectRow:newIndex byExtendingSelection:NO];
		
        return(YES);
    }else{
        return(NO);
    }
}

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSResponder	*existingResponder = [[tabView window] firstResponder];
    
    //Take focus away from any controls to ensure that they register changes and save
    [[tabView window] makeFirstResponder:tabView];
	
    //Put focus back
    [[tabView window] makeFirstResponder:existingResponder];
}

@end
