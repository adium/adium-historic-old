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
#import "AIAccountListWindowController.h"
#import "AIContactController.h"
#import "AIEditAccountWindowController.h"
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>

#define	ACCOUNT_DRAG_TYPE					@"AIAccount"	    			//ID for an account drag

@interface AIAccountListWindowController (PRIVATE)
- (void)configureAccountList;
- (void)accountListChanged:(NSNotification *)notification;
@end

/*!
 * @class AIAccountListWindowController
 * @brief Shows a list of accounts and provides for management of them
 */
@implementation AIAccountListWindowController

/*!
* @brief Preference pane properties
 */
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Accounts);
}
- (NSString *)label{
    return(AILocalizedString(@"Accounts","Appearance preferences label"));
}
- (NSString *)nibName{
    return(@"AccountListWindow");
}


//AIAccountListWindowController *sharedAccountWindowInstance = nil;
///*!
// * @brief Return a shared instance of AIAccountListWindowController.
// *
// * @result The shared instance, created if necessary
// */
//+ (AIAccountListWindowController *)accountListWindowController
//{
//    if(!sharedAccountWindowInstance){
//        sharedAccountWindowInstance = [[self alloc] initWithWindowNibName:@"AccountListWindow"];
//    }
//    return(sharedAccountWindowInstance);
//}
//
///*!
// * @brief Auto save name for AIWindowController
// */
//- (NSString *)adiumFrameAutosaveName
//{
//	return(@"AIAccountListWindow");
//}

/*!
 * @brief Configure the window initially
 *
 * Center the window on screen and then configure the list and menus
 */
//- (void)windowDidLoad
- (void)viewDidLoad
{
	//Center this panel
//	[[[self view] window] center];

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

	//Observe status icon pack changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(statusIconsChanged:)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];

//	[super windowDidLoad];
}

/*!
 * @brief Perform actions before the window closes
 */
//- (BOOL)windowShouldClose:(id)sender
- (void)viewWillClose;
{
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium notificationCenter] removeObserver:self];
	
	//Cleanup and close our shared instance
//	[sharedAccountWindowInstance autorelease]; sharedAccountWindowInstance = nil;
	
//	[super windowShouldClose:sender];
	
//	return(YES);
}

/*!
 * @brief Account status changed.
 *
 * Disable the service menu and user name field for connected accounts
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if([inObject isKindOfClass:[AIAccount class]]){
		if([inModifiedKeys containsObject:@"Online"] ||
		   [inModifiedKeys containsObject:@"Connecting"] ||
		   [inModifiedKeys containsObject:@"Disconnecting"] ||
		   [inModifiedKeys containsObject:@"ConnectionProgressString"] ||
		   [inModifiedKeys containsObject:@"ConnectionProgressPercent"] ||
		   [inModifiedKeys containsObject:@"IdleSince"] ||
		   [inModifiedKeys containsObject:@"StatusState"]){

			//Refresh this account in our list
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
/*!
 * @brief Create a new account
 *
 * Called when a service type is selected from the Add menu
 */
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
									  onWindow:[[self view] window]
							  isNewAccount:YES];
}

/*!
 * @brief Edit the currently selected account using <tt>AIEditAccountWindowController</tt>
 */
- (IBAction)editAccount:(id)sender
{
    int	selectedRow = [tableView_accountList selectedRow];
	if(selectedRow >= 0 && selectedRow < [accountArray count]){		
		[AIEditAccountWindowController editAccount:[accountArray objectAtIndex:selectedRow] 
										  onWindow:[[self view] window]
								  isNewAccount:NO];
    }
}

/*!
 * @brief Delete the selected account
 *
 * Prompts for confirmation first
 */
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
	
    NSBeginAlertSheet(AILocalizedString(@"Delete Account",nil),
					  AILocalizedString(@"Delete",nil),
					  AILocalizedString(@"Cancel",nil),
					  @"",[[self view] window], self, 
					  @selector(deleteAccountSheetDidEnd:returnCode:contextInfo:), nil, targetAccount, 
					  AILocalizedString(@"Delete the account %@?",nil), ([accountFormattedUID length] ? accountFormattedUID : NEW_ACCOUNT_DISPLAY_TEXT));
}

/*!
 * @brief Finish account deletion
 *
 * Called when the sheet is closed
 *
 * @param returnCode NSAlertDefaultReturn indicates the account should be deleted
 */
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
/*!
 * @brief Configure the account list table
 */
- (void)configureAccountList
{
    AIImageTextCell			*cell;
	
	//Setup our buttons
	[button_editAccount setTitle:@"Edit"];
	
	//Configure our table view
	[tableView_accountList setTarget:self];
	[tableView_accountList setDoubleAction:@selector(editAccount:)];
	[tableView_accountList setIntercellSpacing:NSMakeSize(4,4)];
    [scrollView_accountList setAutoHideScrollBar:YES];

	//Enable dragging of accounts
	[tableView_accountList registerForDraggedTypes:[NSArray arrayWithObjects:ACCOUNT_DRAG_TYPE,nil]];
	
    //Custom vertically-centered text cell for account names
    cell = [[AIVerticallyCenteredTextCell alloc] init];
    [cell setFont:[NSFont boldSystemFontOfSize:13]];
    [[tableView_accountList tableColumnWithIdentifier:@"name"] setDataCell:cell];
	[cell release];

    cell = [[AIVerticallyCenteredTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:13]];
    [cell setAlignment:NSRightTextAlignment];
    [[tableView_accountList tableColumnWithIdentifier:@"status"] setDataCell:cell];
	[cell release];
    
	//Observe changes to the account list
    [[adium notificationCenter] addObserver:self
								   selector:@selector(accountListChanged:) 
									   name:Account_ListChanged 
									 object:nil];
	[self accountListChanged:nil];
	
	//Observe accounts so we can display accurate status
    [[adium contactController] registerListObjectObserver:self];
}

/*!
 * @brief Account list changed, refresh our table
 */
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

/*!
 * @brief Status icons changed, refresh our table
 */
- (void)statusIconsChanged:(NSNotification *)notification
{
	[tableView_accountList reloadData];
}

/*!
 * @brief Update our account overview
 *
 * The overview indicates the total number of accounts and the number which are online.
 */
- (void)updateAccountOverview
{
	NSEnumerator	*enumerator = [accountArray objectEnumerator];
	AIAccount		*account;
	int				online = 0;
	
	//Count online accounts
	while(account = [enumerator nextObject]){
		if([[account statusObjectForKey:@"Online"] boolValue]) online++;
	}
	
	if([accountArray count] == 0 && online == 0){
		[textField_overview setLocalizedString:AILocalizedString(@"Click the + to add a new account","Instructions on how to add an account when none are present")];
	}else{
		[textField_overview setStringValue:[NSString stringWithFormat:AILocalizedString(@"%i accounts, %i online","Overview of total and online accounts"), [accountArray count], online]];
	}
}

/*!
 * @brief Update control availability based on list selection
 */
- (void)updateControlAvailability
{
	BOOL	selection = ([tableView_accountList selectedRow] != -1);

	[button_editAccount setEnabled:selection];
	[button_deleteAccount setEnabled:selection];
}


//Account List Table Delegate ------------------------------------------------------------------------------------------
#pragma mark Account List (Table Delegate)
/*!
 * @brief Delete the selected row
 */
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteAccount:nil];
}

/*!
 * @brief Number of rows in the table
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([accountArray count]);
}

/*!
 * @brief Table values
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString 	*identifier = [tableColumn identifier];
	AIAccount	*account = [accountArray objectAtIndex:row];
	
	if([identifier isEqualToString:@"icon"]){
		return([AIServiceIcons serviceIconForObject:account type:AIServiceIconLarge direction:AIIconNormal]);

	}else if([identifier isEqualToString:@"name"]){
		return([[account formattedUID] length] ? [account formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT);
		
	}else if([identifier isEqualToString:@"status"]){
		NSString	*title;
		
		if([[account statusObjectForKey:@"Connecting"] boolValue]){
			title = @"Connecting";
		}else if([[account statusObjectForKey:@"Disconnecting"] boolValue]){
			title = @"Disconnecting";
		}else if([[account statusObjectForKey:@"Online"] boolValue]){
			title = @"Online";
		}else{
			title = @"Offline";
		}

		return(title);
		
	}else if([identifier isEqualToString:@"statusicon"]){

		return([AIStatusIcons statusIconForListObject:account type:AIStatusIconList direction:AIIconNormal]);
		
	}else if([identifier isEqualToString:@"enabled"]){
		return(nil);
	}
	
	return(nil);
}

/*!
 * @brief Configure cells before display
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString 	*identifier = [tableColumn identifier];
	AIAccount	*account = [accountArray objectAtIndex:row];
	
	if([identifier isEqualToString:@"enabled"]){
		BOOL online = [[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue];
		[cell setState:(online ? NSOnState : NSOffState)];

	}else if([identifier isEqualToString:@"status"]){
		[cell setEnabled:([[account statusObjectForKey:@"Connecting"] boolValue] ||
						  [[account statusObjectForKey:@"Disconnecting"] boolValue] ||
						  [[account statusObjectForKey:@"Online"] boolValue])];
	}
	
}

/*!
 * @brief Handle a clicked active/inactive checkbox
 *
 * Checking the box both takes the account online and sets it to autoconnect. Unchecking it does the opposite.
 */
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if([[tableColumn identifier] isEqualToString:@"enabled"]){
		[[accountArray objectAtIndex:row] setPreference:object forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
	}
}

/*!
 * @brief Drag start
 */
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
    tempDragAccount = [accountArray objectAtIndex:[[rows objectAtIndex:0] intValue]];
	
    [pboard declareTypes:[NSArray arrayWithObject:ACCOUNT_DRAG_TYPE] owner:self];
    [pboard setString:@"Account" forType:ACCOUNT_DRAG_TYPE];
    
    return(YES);
}

/*!
 * @brief Drag validate
 */
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if(op == NSTableViewDropAbove && row != -1){
        return(NSDragOperationPrivate);
    }else{
        return(NSDragOperationNone);
    }
}

/*!
 * @brief Drag complete
 */
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

/*!
 * @brief Selection change
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateControlAvailability];
}

@end
