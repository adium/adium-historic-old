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

#define	ACCOUNT_DRAG_TYPE					@"AIAccount"			//ID for an account drag
#define	ACCOUNT_CONNECT_BUTTON_TITLE		@"Connect"				//Menu item title for the connect item
#define	ACCOUNT_DISCONNECT_BUTTON_TITLE		@"Disconnect"			//Menu item title
#define	ACCOUNT_CONNECTING_BUTTON_TITLE		@"Connecting…"			//Menu item title
#define	ACCOUNT_DISCONNECTING_BUTTON_TITLE	@"Disconnecting…"		//Menu item title

@interface AIAccountListPreferences (PRIVATE)
- (void)updateAccountList;
- (void)refreshAccountList;
- (void)accountListChanged:(NSNotification *)notification;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableViewSelectionDidChange:(NSNotification *)notification;
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard;
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
- (void)deleteAccountSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)tableViewSelectionDidChange:(NSNotification *)notification;
- (void)configureView;
- (void)configureAccountOptionsView;
- (void)accountPropertiesChanged:(NSNotification *)notification;
@end

@implementation AIAccountListPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Accounts);
}
- (NSString *)label{
    return(@"Accounts");
}
- (NSString *)nibName{
    return(@"AccountPrefView");
}

//Configure the preference view
- (void)viewDidLoad
{
    NSEnumerator		*enumerator;
    id <AIServiceController>	service;
    AIImageTextCell		*cell;
    
    //init
    accountViewController = nil;
    view_accountPreferences = nil;
    selectedAccount = nil;
	
    //Configure our tableView
    cell = [[[AIImageTextCell alloc] init] autorelease];
    [cell setFont:[NSFont systemFontOfSize:12]];
    [[tableView_accountList tableColumnWithIdentifier:@"description"] setDataCell:cell];
    [tableView_accountList registerForDraggedTypes:[NSArray arrayWithObjects:ACCOUNT_DRAG_TYPE,nil]];
    [scrollView_accountList setAutoHideScrollBar:YES];
    
    //Configure our buttons
    [button_newAccount setImage:[AIImageUtilities imageNamed:@"plus" forClass:[self class]]];
    [button_deleteAccount setImage:[AIImageUtilities imageNamed:@"minus" forClass:[self class]]];
    
    //Configure the service list
    enumerator = [[[[adium accountController] availableServices] allValues] objectEnumerator];
    [popupMenu_serviceList removeAllItems];
    while((service = [enumerator nextObject])){
        NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:[service description] target:self action:@selector(selectServiceType:) keyEquivalent:@""] autorelease];
	
        [item setRepresentedObject:service];
        [[popupMenu_serviceList menu] addItem:item];
    }

    //Install our observers
    [[adium notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
    [[adium contactController] registerListObjectObserver:self];
    
    //Refresh our view
    [self accountListChanged:nil];
}

//Preference view is closing
- (void)viewWillClose
{
    [[adium contactController] unregisterListObjectObserver:self];
    [view_accountPreferences release]; view_accountPreferences = nil;
    [accountViewController release]; accountViewController = nil;
    [[adium notificationCenter] removeObserver:self];
}
    
//Configure the account specific options
- (void)configureAccountOptionsView
{
    NSEnumerator	*enumerator;
    NSTabViewItem	*tabViewItem;
    NSView			*accountView;
    BOOL			autoConnect;
    int				selectedTabIndex;

    //Remove any tabs
    if([tabView_auxilary selectedTabViewItem]){
		selectedTabIndex = [tabView_auxilary indexOfTabViewItem:[tabView_auxilary selectedTabViewItem]];
    }
    while([tabView_auxilary numberOfTabViewItems] > 1){
        [tabView_auxilary removeTabViewItem:[tabView_auxilary tabViewItemAtIndex:[tabView_auxilary numberOfTabViewItems] - 1]];
    }

    //Close any currently open controllers
    [view_accountDetails removeAllSubviews];
    if(accountViewController){
        [accountViewController release]; accountViewController = nil;
    }

    //select the correct service in the service menu
    [popupMenu_serviceList selectItemAtIndex:[popupMenu_serviceList indexOfItemWithRepresentedObject:[selectedAccount service]]];
	[popupMenu_serviceList setEnabled:![[selectedAccount statusObjectForKey:@"Online"] boolValue]];

    //Configure the auto-connect button
    autoConnect = [[selectedAccount preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue];
    [button_autoConnect setState:autoConnect];

    //Correctly size the sheet for the account details view
    accountViewController = [[selectedAccount accountView] retain];
    accountView = [accountViewController view];

    //Swap in the account details view
    [view_accountDetails addSubview:accountView];
    [accountView setFrameOrigin:NSMakePoint(0,([view_accountDetails frame].size.height - [accountView frame].size.height))];
    if([accountViewController conformsToProtocol:@protocol(AIAccountViewController)]){
        [accountViewController configureViewAfterLoad]; //allow the account subview to set itself up after the window has loaded
    }

    //Hook up the key view chain
    [popupMenu_serviceList setNextKeyView:[accountView nextKeyView]];
    NSView	*nextView = accountView;
    while([nextView nextKeyView]) nextView = [nextView nextKeyView];
    [nextView setNextKeyView:button_autoConnect];
	
    //Swap in the account auxilary tabs
    enumerator = [[accountViewController auxilaryTabs] objectEnumerator];
    while(tabViewItem = [enumerator nextObject]){
        [tabView_auxilary addTabViewItem:tabViewItem];
    }
	
    //There must be a better way to do this.  When moving tabs over, they will stay selected - resulting in multiple selected tabs.  My quick fix is to manually select each tab in the view.  Not the greatest, but it'll work for now.
    [tabView_auxilary selectLastTabViewItem:nil];
    int i;
    for(i = 1;i < [tabView_auxilary numberOfTabViewItems];i++){
        [tabView_auxilary selectPreviousTabViewItem:nil];
    }
	
    //Re-select same index (if possible)
    if(selectedTabIndex > 0 && selectedTabIndex < [tabView_auxilary numberOfTabViewItems]){
        [tabView_auxilary selectTabViewItemAtIndex:selectedTabIndex];
    }else{
        [tabView_auxilary selectFirstTabViewItem:nil];
    }
}

//Account list changed
- (void)accountListChanged:(NSNotification *)notification
{
    //Update our reference to the accounts
    selectedAccount = nil;
    [accountArray release]; accountArray = [[[adium accountController] accountArray] retain];
    
    //Refresh the table (if the window is loaded)
    if(tableView_accountList != nil){
		[tableView_accountList reloadData];
		[self tableViewSelectionDidChange:nil];
    }
}

//Account status changed
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys delayed:(BOOL)delayed silent:(BOOL)silent
{
    if(inObject == selectedAccount){
		if([inModifiedKeys containsObject:@"Online"]){
			[popupMenu_serviceList setEnabled:![[selectedAccount statusObjectForKey:@"Online"] boolValue]];
		}
    }
    
    return(nil);
}


//Editing ------------------------------------------------------------------------
//User selected a service type from the menu
- (IBAction)selectServiceType:(id)sender
{
    id <AIServiceController>	service = [sender representedObject];
    
    //Switch it
    [selectedAccount autorelease];
    selectedAccount = [[[adium accountController] switchAccount:selectedAccount toService:service] retain];
}

//User toggled the autoconnect preference
- (IBAction)toggleAutoConnect:(id)sender
{
    BOOL	autoConnect = [sender state];
    
    //Apply the new value
    [selectedAccount setPreference:[NSNumber numberWithBool:autoConnect] forKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS];
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
    [tabView_auxilary selectTabViewItemAtIndex:0];
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
    
    NSBeginAlertSheet(@"Delete Account",@"Delete",@"Cancel",@"",[view_accountPreferences window], self, @selector(deleteAccountSheetDidEnd:returnCode:contextInfo:), nil, targetAccount, @"Delete the account %@?", [targetAccount displayName]);
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


//Account list table view delegate ------------------------------------------------------------------------
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
    return([[accountArray objectAtIndex:row] displayName]);
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    AIAccount		*account = [accountArray objectAtIndex:row];
    NSImage		*image = [AIImageUtilities imageNamed:@"DefaultIcon" forClass:[self class]];
	
    [cell setImage:image];
    [cell setSubString:[account serviceID]];
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

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    int	selectedRow = [tableView_accountList selectedRow];
	
    if(selectedRow >=0 && selectedRow < [accountArray count]){
        //Correctly enable/disable our delete button
        if([accountArray count] > 1){
            [button_deleteAccount setEnabled:YES];
        }else{
            [button_deleteAccount setEnabled:NO];
        }
		
        //Configure for the newly selected account
        selectedAccount = [accountArray objectAtIndex:selectedRow];
        [self configureAccountOptionsView];
		
    }else{
        [button_deleteAccount setEnabled:NO];
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
