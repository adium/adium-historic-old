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

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAccountListPreferencesPlugin.h"
#import "AIAdium.h"
#import "AIAccountController.h"
#import "AIPreferenceController.h"


#define	ACCOUNT_DRAG_TYPE			@"AIAccount"			//ID for an account drag
#define ACCOUNT_PREFERENCE_VIEW_NIB		@"AccountPrefView"		//Filename for the accounts preference view nib
#define	ACCOUNT_PREFERENCE_TITLE		@"Accounts"			//Title for the accounts preference view
#define	ACCOUNT_CONNECT_BUTTON_TITLE		@"Connect"			//Menu item title for the connect item
#define	ACCOUNT_DISCONNECT_BUTTON_TITLE		@"Disconnect"			//Menu item title
#define	ACCOUNT_CONNECTING_BUTTON_TITLE		@"Connecting…"			//Menu item title
#define	ACCOUNT_DISCONNECTING_BUTTON_TITLE	@"Disconnecting…"		//Menu item title

@interface AIAccountListPreferencesPlugin (PRIVATE)
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

@implementation AIAccountListPreferencesPlugin

// init the account view controller
- (void)installPlugin
{
    //init
    accountArray = [[[owner accountController] accountArray] retain];
    accountViewController = nil;
    view_accountPreferences = nil;

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Accounts_Connections withDelegate:self label:ACCOUNT_PREFERENCE_TITLE]];
}

- (void)dealloc
{
    [accountArray release];

    [super dealloc];
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_accountPreferences){
        [NSBundle loadNibNamed:ACCOUNT_PREFERENCE_VIEW_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_accountPreferences);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_accountPreferences release]; view_accountPreferences = nil;
    [accountViewController release]; accountViewController = nil;
    [[owner notificationCenter] removeObserver:self];
}

//Configure our preference view
- (void)configureView
{
    NSEnumerator		*enumerator;
    id <AIServiceController>	service;
    AIImageTextCell		*cell;

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
    enumerator = [[[owner accountController] availableServiceArray] objectEnumerator];
    [popupMenu_serviceList removeAllItems];
    while((service = [enumerator nextObject])){
        NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:[service description] target:self action:@selector(selectServiceType:) keyEquivalent:@""] autorelease];

        [item setRepresentedObject:service];
        [[popupMenu_serviceList menu] addItem:item];
    }

    //Install our observers
    [[owner notificationCenter] addObserver:self
                                   selector:@selector(refreshAccountList)
                                       name:Account_PropertiesChanged
                                     object:nil];
    [[owner notificationCenter] addObserver:self
                                   selector:@selector(accountListChanged:)
                                       name:Account_ListChanged
                                     object:nil];
    [[owner notificationCenter] addObserver:self
                                   selector:@selector(accountPropertiesChanged:) name:Account_PropertiesChanged
                                     object:nil];
    
    //Refresh our view
    [self updateAccountList];
    [self tableViewSelectionDidChange:nil];
}

//The properties of our account changed
- (void)accountPropertiesChanged:(NSNotification *)notification
{
    NSString	*key = [[notification userInfo] objectForKey:@"Key"];
    AIAccount	*account = [notification object];
    BOOL	isOnline;
    
    //Dim unavailable controls
    if(notification == nil || ([key compare:@"Online"] == 0 && account == selectedAccount)){
        if(notification == nil) account = selectedAccount;

        isOnline = [[[owner accountController] propertyForKey:@"Online" account:account] boolValue];
        [popupMenu_serviceList setEnabled:!isOnline];
    }
}

//configure the account specific options
- (void)configureAccountOptionsView
{
    NSEnumerator	*enumerator;
    NSTabViewItem	*tabViewItem;
    NSView		*accountView;
    BOOL		autoConnect;
    int			selectedTabIndex;

    //Remove any tabs
    selectedTabIndex = [tabView_auxilary indexOfTabViewItem:[tabView_auxilary selectedTabViewItem]];
    while([tabView_auxilary numberOfTabViewItems] > 1){
        [tabView_auxilary removeTabViewItem:[tabView_auxilary tabViewItemAtIndex:[tabView_auxilary numberOfTabViewItems] - 1]];
    }
    
    //Close any currently open controllers, saving changes(?)
    if(accountViewController){
        //[accountViewController saveChanges];
        [accountViewController release]; accountViewController = nil;
    }
    [view_accountDetails removeAllSubviews];

    //select the correct service in the service menu
    [popupMenu_serviceList selectItemAtIndex:[popupMenu_serviceList indexOfItemWithRepresentedObject:[selectedAccount service]]];

    //Configure the auto-connect button
    autoConnect = [[[owner accountController] propertyForKey:@"AutoConnect" account:selectedAccount] boolValue];
    [button_autoConnect setState:autoConnect];
    
    //Correctly size the sheet for the account details view
    accountViewController = [[selectedAccount accountView] retain];
    accountView = [accountViewController view];

    //Swap in the account details view
    [view_accountDetails addSubview:accountView];
    [accountView setFrameOrigin:NSMakePoint(0,([view_accountDetails frame].size.height - [accountView frame].size.height))];
    if([accountViewController conformsToProtocol:@protocol(AIAccountViewController)])
    {
        [accountViewController configureViewAfterLoad]; //allow the account subview to set itself up after the window has loaded
    }

    //Hook up the key view chain
    [popupMenu_serviceList setNextKeyView:[accountView nextKeyView]];
    NSView	*view = accountView;
    while([view nextKeyView]) view = [view nextKeyView];
    [view setNextKeyView:button_autoConnect];

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

    //Enable/disable controls
    [self accountPropertiesChanged:nil];
}

// User selected a service type from the menu
- (IBAction)selectServiceType:(id)sender
{
    id <AIServiceController>	service = [sender representedObject];

    //Switch it
    [selectedAccount autorelease];
    selectedAccount = [[[owner accountController] switchAccount:selectedAccount toService:service] retain];

    //reconfigure
    [self configureAccountOptionsView];
}

//User toggled the autoconnect preference
- (IBAction)toggleAutoConnect:(id)sender
{
    BOOL	autoConnect = [sender state];
    
    //Apply the new value
    [[owner accountController] setProperty:[NSNumber numberWithBool:autoConnect] forKey:@"AutoConnect" account:selectedAccount];
}

//Create a new account
- (IBAction)newAccount:(id)sender
{
    int		index = [tableView_accountList selectedRow] + 1;
    AIAccount	*newAccount;

    //Add the new account
    newAccount = [[owner accountController] newAccountAtIndex:index];
    [self refreshAccountList];

    //Select the new account
    [tableView_accountList selectRow:index byExtendingSelection:NO];

    //Put focus on the account fields
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

    NSBeginAlertSheet(@"Delete Account",@"Delete",@"Cancel",@"",[view_accountPreferences window], self, @selector(deleteAccountSheetDidEnd:returnCode:contextInfo:), nil, targetAccount, @"Delete the account %@?", [targetAccount accountDescription]);
}

// Finishes the delete action when the sheet is closed
- (void)deleteAccountSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    AIAccount 	*targetAccount = contextInfo;
    int		index;
    
    NSParameterAssert(targetAccount != nil); NSParameterAssert([targetAccount isKindOfClass:[AIAccount class]]);

    if(returnCode == NSAlertDefaultReturn){
        //Delete it
        index = [accountArray indexOfObject:targetAccount];
        [[owner accountController] deleteAccount:targetAccount];
    
        //If it was the last row, select the new last row (by default the selection will jump to the top, which is bad)
        if(index >= [accountArray count]){
            index = [accountArray count]-1;
            [tableView_accountList selectRow:index byExtendingSelection:NO];
        }
    }
}

//Update/Refresh our account list and table views
- (void)updateAccountList
{
    //Update the reference
    selectedAccount = nil;
    [accountArray release]; accountArray = nil;
    accountArray = [[[owner accountController] accountArray] retain];

    //Refresh the table (if the window is loaded)
    [self refreshAccountList];
}

//Refresh the table (if the window is loaded)
- (void)refreshAccountList
{
    if(tableView_accountList != nil){
        [tableView_accountList reloadData];
    }
   
    //Reconfig to the selected account
    //[self tableViewSelectionDidChange:nil];
}

// Called when the account list changes
- (void)accountListChanged:(NSNotification *)notification
{
    [self updateAccountList];

    //if there are no accounts, open the prefs and create one
    if([[[owner accountController] accountArray] count] == 0){
        //open
        //[[owner preferenceController] openPreferencesToView:preferenceView];

        //create
        [[owner accountController] newAccountAtIndex:0];
    
        //edit
        [tableView_accountList selectRow:0 byExtendingSelection:NO];
        //[self editAccount:nil];
    }
}

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
    return([[accountArray objectAtIndex:row] accountDescription]);
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    AIAccount		*account = [accountArray objectAtIndex:row];
    NSImage		*image;
    ACCOUNT_STATUS	status = STATUS_NA;

    //Get the account's status
    if([[account supportedPropertyKeys] containsObject:@"Online"]){
        status = [[[owner accountController] propertyForKey:@"Status" account:account] intValue];
    }

    image = [AIImageUtilities imageNamed:@"DefaultIcon" forClass:[self class]];

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
        return(YES);
    }else{
        return(NO);
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
        newIndex = [[owner accountController] moveAccount:tempDragAccount toIndex:row];
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
