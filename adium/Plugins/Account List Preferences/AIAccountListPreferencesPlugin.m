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
#import "AIAccountListEditSheetController.h"


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
@end

@implementation AIAccountListPreferencesPlugin

// init the account view controller
- (void)installPlugin
{
    //init
    accountArray = [[[owner accountController] accountArray] retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Accounts_Connections withDelegate:self label:ACCOUNT_PREFERENCE_TITLE]];
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
    [[owner notificationCenter] removeObserver:self];
}

//Configure our preference view
- (void)configureView
{
    //Configure our tableView
    [[tableView_accountList tableColumnWithIdentifier:@"icon"] setDataCell:[[[NSImageCell alloc] init] autorelease]];
    [tableView_accountList registerForDraggedTypes:[NSArray arrayWithObjects:ACCOUNT_DRAG_TYPE,nil]];

    //Install our observers
    [[owner notificationCenter] addObserver:self
                                   selector:@selector(refreshAccountList)
                                       name:Account_PropertiesChanged
                                     object:nil];
    [[owner notificationCenter] addObserver:self
                                   selector:@selector(refreshAccountList)
                                       name:Account_StatusChanged
                                     object:nil];
    [[owner notificationCenter] addObserver:self
                                   selector:@selector(accountListChanged:)
                                       name:Account_ListChanged
                                     object:nil];

    //Refresh our view
    [self updateAccountList];
}

- (void)uninstallPlugin
{

}

- (void)dealloc
{
    [accountArray release];

    [super dealloc];
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

//Create a new account
- (IBAction)newAccount:(id)sender
{
    int		index = [tableView_accountList selectedRow] + 1;
    AIAccount	*newAccount;

    //Add the new account
    newAccount = [[owner accountController] newAccountAtIndex:index];
    [self refreshAccountList];

    //Select and edit the new account
    [tableView_accountList selectRow:index byExtendingSelection:NO];
    [self editAccountCreatingNew:YES];
}

//Edit an account
- (IBAction)editAccount:(id)sender
{
    [self editAccountCreatingNew:NO];
}

//Togle the connection of the selected account
- (IBAction)toggleConnection:(id)sender
{
    int 			index;
    AIAccount			*targetAccount;

    NSParameterAssert(accountArray != nil); NSParameterAssert([accountArray count] > 0);

    //Confirm
    index = [tableView_accountList selectedRow];
    NSParameterAssert(index >= 0 && index < [accountArray count]);
    targetAccount = [accountArray objectAtIndex:index];
    
    //Toggle the connection
    if([[targetAccount supportedStatusKeys] containsObject:@"Online"]){
        if([[[owner accountController] statusObjectForKey:@"Online" account:targetAccount] boolValue]){
            [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:targetAccount];
        }else{
            [[owner accountController] setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" account:targetAccount];
        }
    }
}

//Selects the account, and starts editing it. Makes sure that we don't delete it when we hit cancel if its not a new account!
-(void)editAccountCreatingNew:(BOOL)newo
{
    AIAccount		*selectedAccount;
    int			selectedRow;

    selectedRow = [tableView_accountList selectedRow];
    if(selectedRow >= 0 && selectedRow < [accountArray count]){
        selectedAccount = [accountArray objectAtIndex:selectedRow];
        
        [AIAccountListEditSheetController showAccountListEditSheetForAccount:selectedAccount onWindow:[view_accountPreferences window] owner:owner deleteOnCancel:newo];
    }
}


// Private ---------------------------------------------------------------------------
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
    [self tableViewSelectionDidChange:nil];
}

// Called when the account list changes
- (void)accountListChanged:(NSNotification *)notification
{
    [self updateAccountList];

    //if there are no accounts, open the prefs and create one
    if([[[owner accountController] accountArray] count] == 0){
        //open
#warning        [[owner preferenceController] openPreferencesToView:preferenceView];
    
        //create
        [[owner accountController] newAccountAtIndex:0];
    
        //edit
        [tableView_accountList selectRow:0 byExtendingSelection:NO];
        [self editAccount:nil];
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
    NSString	*identifier = [tableColumn identifier];
    AIAccount	*account = [accountArray objectAtIndex:row];

    if([identifier compare:@"icon"] == 0 ){
        NSImage		*image;
        ACCOUNT_STATUS	status = STATUS_NA;

        //Get the account's status
        if([[account supportedStatusKeys] containsObject:@"Online"]){
            status = [[[owner accountController] statusObjectForKey:@"Status" account:account] intValue];
        }
    
        switch(status){
            case STATUS_NA:
                image = [AIImageUtilities imageNamed:@"Account_Online" forClass:[self class]];
            break;
            case STATUS_OFFLINE:
                image = [AIImageUtilities imageNamed:@"Account_Offline" forClass:[self class]];
            break;
            case STATUS_CONNECTING:
                image = [AIImageUtilities imageNamed:@"Account_Connecting" forClass:[self class]];
            break;
            case STATUS_ONLINE:
                image = [AIImageUtilities imageNamed:@"Account_Online" forClass:[self class]];
            break;
            case STATUS_DISCONNECTING:
                image = [AIImageUtilities imageNamed:@"Account_Connecting" forClass:[self class]];
            break;
            default:
                image = nil;
            break;
        }
    
        return(image);

    }else if([identifier compare:@"description"] == 0 ){
        return([[accountArray objectAtIndex:row] accountDescription]);

    }else if([identifier compare:@"status"] == 0 ){
        NSString	*string;
        NSColor		*color;
        BOOL		selected;
        ACCOUNT_STATUS	status = STATUS_NA;

        //The 'white' when selected text is new in 10.2
        selected = ([tableView selectedRow] == row && [[tableView window] firstResponder] == tableView && [[tableView window] isKeyWindow]);

        //Get the account's status
        if([[account supportedStatusKeys] containsObject:@"Online"]){
            status = [[[owner accountController] statusObjectForKey:@"Status" account:account] intValue];
        }
        
        //Return the correct string
        switch(status){
            case STATUS_NA:
                string = @"n/a";
                if(!selected) color = [NSColor blackColor];
                else color = [NSColor whiteColor];
            break;
            case STATUS_OFFLINE:
                string = @"Offline";
                if(!selected) color = [NSColor colorWithCalibratedRed:0.15 green:0.0 blue:0.0 alpha:1.0];
                else color = [NSColor colorWithCalibratedRed:1.0 green:0.85 blue:0.85 alpha:1.0];
            break;
            case STATUS_CONNECTING:
                string = @"Connecting…";
                if(!selected) color = [NSColor colorWithCalibratedRed:0.15 green:0.15 blue:0.0 alpha:1.0];
                else color = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.85 alpha:1.0];
            break;
            case STATUS_ONLINE:
                string = @"Online";
                if(!selected) color = [NSColor colorWithCalibratedRed:0.0 green:0.15 blue:0.0 alpha:1.0];
                else color = [NSColor colorWithCalibratedRed:0.85 green:1.0 blue:0.85 alpha:1.0];
            break;
            case STATUS_DISCONNECTING:
                string = @"Disconnecting…";
                if(!selected) color = [NSColor colorWithCalibratedRed:0.15 green:0.15 blue:0.0 alpha:1.0];
                else color = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:0.85 alpha:1.0];
            break;
            default:
                string = @"Unknown";
                if(!selected) color = [NSColor blackColor];
                else color = [NSColor whiteColor];
            break;
        }
        
        return([[[NSAttributedString alloc] initWithString:string attributes:[NSDictionary dictionaryWithObjectsAndKeys:color,NSForegroundColorAttributeName,nil]] autorelease]);
    }else if([identifier compare:@"autoconnect"] == 0){
        if([[[account properties] objectForKey:@"AutoConnect"] boolValue]){
            return(@"Yes");
        }else{
            return(@"No");
        }

    }else{
        return(@"");
    }
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
        AIAccount	*account = [accountArray objectAtIndex:selectedRow];

        [button_editAccount setEnabled:YES];
        if([accountArray count] > 1){
            [button_deleteAccount setEnabled:YES];
        }else{
            [button_deleteAccount setEnabled:NO];
        }

        if([[account supportedStatusKeys] containsObject:@"Online"]){
            switch([[[owner accountController] statusObjectForKey:@"Status" account:account] intValue]){
                case STATUS_OFFLINE:
                    [button_toggleAccount setTitle:ACCOUNT_CONNECT_BUTTON_TITLE];
                    [button_toggleAccount setEnabled:YES];
                break;
                case STATUS_CONNECTING:
                    [button_toggleAccount setTitle:ACCOUNT_CONNECTING_BUTTON_TITLE];
                    [button_toggleAccount setEnabled:NO];
                break;
                case STATUS_ONLINE:
                    [button_toggleAccount setTitle:ACCOUNT_DISCONNECT_BUTTON_TITLE];
                    [button_toggleAccount setEnabled:YES];
                break;
                case STATUS_DISCONNECTING:
                    [button_toggleAccount setTitle:ACCOUNT_DISCONNECTING_BUTTON_TITLE];
                    [button_toggleAccount setEnabled:NO];
                break;
                default:
                    [button_toggleAccount setTitle:@"n/a"];
                    [button_toggleAccount setEnabled:NO];
                break;
            }
        }else{
            [button_toggleAccount setTitle:ACCOUNT_CONNECT_BUTTON_TITLE];
            [button_toggleAccount setEnabled:NO];
        }
    }else{
        [button_editAccount setEnabled:NO];
        [button_deleteAccount setEnabled:NO];
        [button_toggleAccount setTitle:ACCOUNT_CONNECT_BUTTON_TITLE];
        [button_toggleAccount setEnabled:NO];
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

@end
