/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIAccountListWindowController.h"
#import "AIEditAccountWindowController.h"

#define	ACCOUNT_DRAG_TYPE					@"AIAccount"	    			//ID for an account drag

@interface AIAccountListWindowController (PRIVATE)
- (void)configureAccountList;
- (void)accountListChanged:(NSNotification *)notification;
@end

@implementation AIAccountListWindowController

AIAccountListWindowController *sharedAccountWindowInstance = nil;
+ (AIAccountListWindowController *)accountListWindowController
{
    if(!sharedAccountWindowInstance){
        sharedAccountWindowInstance = [[self alloc] initWithWindowNibName:@"AccountListWindow"];
    }
    return(sharedAccountWindowInstance);
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];

    return(self);
}

//Dealloc
- (void)dealloc
{    
    [super dealloc];
}

- (NSString *)adiumFrameAutosaveName
{
	return(@"AIAccountListWindow");
}

//Configure
- (void)windowDidLoad
{
	//Center this panel
	[[self window] center];

	//Configure the account list
	[self configureAccountList];
	[self updateAccountOverview];
	
	//Build the 'add account' menu
	NSMenu	*serviceMenu = [[adium accountController] menuOfServicesWithTarget:self 
															activeServicesOnly:NO
															   longDescription:YES
																		format:AILocalizedString(@"%@",nil)];
	[serviceMenu setAutoenablesItems:YES];
	[button_newAccount setMenu:serviceMenu];

	//Observe accounts so we can display accurate status
    [[adium contactController] registerListObjectObserver:self];
}

//Close
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Closing
- (BOOL)windowShouldClose:(id)sender
{
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium notificationCenter] removeObserver:self];
	
	//Cleanup and close our shared instance
	[sharedAccountWindowInstance autorelease]; sharedAccountWindowInstance = nil;
	
	return(YES);
}

//Account status changed.  Disable the service menu and user name field for connected accounts
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if([inObject isKindOfClass:[AIAccount class]]){
		if([inModifiedKeys containsObject:@"Online"] ||
		   [inModifiedKeys containsObject:@"Connecting"] ||
		   [inModifiedKeys containsObject:@"Disconnecting"] ||
		   [inModifiedKeys containsObject:@"ConnectionProgressString"] ||
		   [inModifiedKeys containsObject:@"ConnectionProgressPercent"]){
			
			//Refresh this account in our list if its status has changed
			int accountRow = [accountArray indexOfObject:inObject];
			if(accountRow >= 0 && accountRow < [accountArray count]){
				[tableView_accountList setNeedsDisplayInRect:[tableView_accountList rectOfRow:accountRow]];
			}
			
			//Update our account overview
			[self updateAccountOverview];
		}
	}
    
    return(nil);
}


//Actions --------------------------------------------------------------------------------------------------------------
#pragma mark Actions
//Create a new account
- (IBAction)selectServiceType:(id)sender
{
    AIAccount	*account;
	int			accountRow;
	
	//Create the new account.  Our list will automatically update in response to the account being created
	account = [[adium accountController] newAccountAtIndex:-1 forService:[sender representedObject]];

	//And then, we can select and edit the new account
	accountRow = [accountArray indexOfObject:account];
	[tableView_accountList selectRow:accountRow byExtendingSelection:NO];
	[tableView_accountList scrollRowToVisible:accountRow];

	[AIEditAccountWindowController editAccount:account
									  onWindow:[self window]
							  deleteIfCanceled:YES];
	
	[self editAccount:nil];
}

//Edit the selected account
- (IBAction)editAccount:(id)sender
{
    int	selectedRow = [tableView_accountList selectedRow];
	if(selectedRow >= 0 && selectedRow < [accountArray count]){		
		[AIEditAccountWindowController editAccount:[accountArray objectAtIndex:selectedRow] 
										  onWindow:[self window]
								  deleteIfCanceled:NO];
    }
}

//Delete the selected account
- (IBAction)deleteAccount:(id)sender
{
    int 		index = [tableView_accountList selectedRow];
    AIAccount	*targetAccount;
    NSString    *accountFormattedUID;
    
    NSParameterAssert(accountArray != nil);
	NSParameterAssert(index >= 0 && index < [accountArray count]);

    //Confirm
    targetAccount = [accountArray objectAtIndex:index];
    accountFormattedUID = [targetAccount formattedUID];
	
    NSBeginAlertSheet(@"Delete Account",@"Delete",@"Cancel",@"",[self window], self, 
					  @selector(deleteAccountSheetDidEnd:returnCode:contextInfo:), nil, targetAccount, 
					  @"Delete the account %@?", [accountFormattedUID length] ? accountFormattedUID : NEW_ACCOUNT_DISPLAY_TEXT);
}

//Finish account deletion (when the sheet is closed)
- (void)deleteAccountSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    AIAccount 	*targetAccount = contextInfo;
    int			index;
    
    NSParameterAssert(targetAccount != nil);
	NSParameterAssert([targetAccount isKindOfClass:[AIAccount class]]);
    
    if(returnCode == NSAlertDefaultReturn){
        //Delete it
        index = [accountArray indexOfObject:targetAccount];
        [[adium accountController] deleteAccount:targetAccount save:YES];
		
        //If it was the last row, select the new last row (by default the selection will jump to the top, which is bad)
        if(index >= [accountArray count]){
            index = [accountArray count]-1;
            [tableView_accountList selectRow:index byExtendingSelection:NO];
        }
    }
}


//Account List ---------------------------------------------------------------------------------------------------------
#pragma mark Account List
//Configure the account list table
- (void)configureAccountList
{
    AIImageTextCell			*cell;
	
	//Setup our buttons
	[button_editAccount setTitle:@"Edit"];
	
	//Configure our table view
	[tableView_accountList setDoubleAction:@selector(editAccount:)];
	[tableView_accountList setIntercellSpacing:NSMakeSize(4,4)];
    [scrollView_accountList setAutoHideScrollBar:YES];

	//Enable dragging of accounts
	[tableView_accountList registerForDraggedTypes:[NSArray arrayWithObjects:ACCOUNT_DRAG_TYPE,nil]];
	
    //Custom vertically-centered text cell for account names
    cell = [[AIVerticallyCenteredTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:13]];
    [[tableView_accountList tableColumnWithIdentifier:@"name"] setDataCell:cell];
	[cell release];
    
	//Observer changes to the account list
    [[adium notificationCenter] addObserver:self
								   selector:@selector(accountListChanged:) 
									   name:Account_ListChanged 
									 object:nil];
	[self accountListChanged:nil];
}

//Account list changed, refresh our table
- (void)accountListChanged:(NSNotification *)notification
{
    //Update our list of accounts
    [accountArray release];
	accountArray = [[[adium accountController] accountArray] retain];
	
	//Refresh the account table
	[tableView_accountList reloadData];
	[self updateControlAvailability];
	[self updateAccountOverview];
}

//Update our account overview
- (void)updateAccountOverview
{
	NSEnumerator	*enumerator = [accountArray objectEnumerator];
	AIAccount		*account;
	int				online = 0;
	
	//Count online accounts
	while(account = [enumerator nextObject]){
		if([[account statusObjectForKey:@"Online"] boolValue]) online++;
	}
	
	[textField_overview setStringValue:[NSString stringWithFormat:@"%i accounts, %i online", [accountArray count], online]];
}

//Update control availability based on list selection
- (void)updateControlAvailability
{
	BOOL	selection = ([tableView_accountList selectedRow] != -1);

	[button_editAccount setEnabled:selection];
	[button_deleteAccount setEnabled:selection];
}


//Account List Table Delegate ------------------------------------------------------------------------------------------
#pragma mark Account List (Table Delegate)
//Delete the selected row
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteAccount:nil];
}

//Number of rows
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([accountArray count]);
}

//Table values
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString 	*identifier = [tableColumn identifier];
	AIAccount	*account = [accountArray objectAtIndex:row];
	
	if([identifier isEqualToString:@"icon"]){
		return([AIServiceIcons serviceIconForObject:account type:AIServiceIconLarge direction:AIIconNormal]);

	}else if([identifier isEqualToString:@"name"]){
		return([[account formattedUID] length] ? [account formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT);
		
	}else if([identifier isEqualToString:@"statusicon"]){
		return([AIStatusIcons statusIconForListObject:account type:AIStatusIconList direction:AIIconNormal]);
		
	}else if([identifier isEqualToString:@"enabled"]){
		return([account preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS]);
	}
	
	return(nil);
}

//Clicked checkbox
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if([[tableColumn identifier] isEqualToString:@"enabled"]){
		[[accountArray objectAtIndex:row] setPreference:object forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
		[[accountArray objectAtIndex:row] setPreference:object forKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS];
	}
}

//Drag start
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    tempDragAccount = [accountArray objectAtIndex:[[rows objectAtIndex:0] intValue]];
	
    [pboard declareTypes:[NSArray arrayWithObject:ACCOUNT_DRAG_TYPE] owner:self];
    [pboard setString:@"Account" forType:ACCOUNT_DRAG_TYPE];
    
    return(YES);
}

//Drag validate
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if(op == NSTableViewDropAbove && row != -1){
        return(NSDragOperationPrivate);
    }else{
        return(NSDragOperationNone);
    }
}

//Drag complete
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ACCOUNT_DRAG_TYPE]];
	
    if([avaliableType isEqualToString:@"AIAccount"]){
        int	newIndex;
        
        //Select the moved account
        newIndex = [[adium accountController] moveAccount:tempDragAccount toIndex:row];
        [tableView_accountList selectRow:newIndex byExtendingSelection:NO];
		
        return(YES);
    }else{
        return(NO);
    }
}

//Selection change
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateControlAvailability];
}

@end
