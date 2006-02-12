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
#import "AIAccountListPreferences.h"
#import "AIContactController.h"
#import "AIStatusController.h"
#import "AIEditAccountWindowController.h"
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>
#import <AIUtilities/AITableViewAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIServiceMenu.h>
#import <Adium/AIStatusIcons.h>
#import "KFTypeSelectTableView.h"

#define	ACCOUNT_DRAG_TYPE				@"AIAccount"	    			//ID for an account drag

#define NEW_ACCOUNT_DISPLAY_TEXT		AILocalizedString(@"<New Account>", "Placeholder displayed as the name of a new account")

@interface AIAccountListPreferences (PRIVATE)
- (void)configureAccountList;
- (void)accountListChanged:(NSNotification *)notification;
@end

/*!
 * @class AIAccountListPreferences
 * @brief Shows a list of accounts and provides for management of them
 */
@implementation AIAccountListPreferences

/*!
 * @brief Preference pane properties
 */
- (PREFERENCE_CATEGORY)category{
    return AIPref_Accounts;
}
- (NSString *)label{
    return AILocalizedString(@"Accounts","Accounts preferences label");
}
- (NSString *)nibName{
    return @"AccountListPreferences";
}

/*!
 * @brief Configure the view initially
 */
- (void)viewDidLoad
{
	//Configure the account list
	[self configureAccountList];
	[self updateAccountOverview];
	
	//Build the 'add account' menu of each available service
	NSMenu	*serviceMenu = [AIServiceMenu menuOfServicesWithTarget:self 
												activeServicesOnly:NO
												   longDescription:YES
															format:AILocalizedString(@"%@",nil)];
	[serviceMenu setAutoenablesItems:YES];
	
	//Indent each item in the service menu one level
	NSEnumerator	*enumerator = [[serviceMenu itemArray] objectEnumerator];
	NSMenuItem		*menuItem;
	while ((menuItem = [enumerator nextObject])) {
		[menuItem setIndentationLevel:[menuItem indentationLevel]+1];
	}

	//Add a label to the top of the menu to clarify why we're showing this list of services
	[serviceMenu insertItemWithTitle:AILocalizedString(@"Add an account for:",nil)
							  action:NULL
					   keyEquivalent:@""
							 atIndex:0];
	
	//Assign the menu
	[button_newAccount setMenu:serviceMenu];

	//Observe status icon pack changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(statusIconsChanged:)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];
}

/*!
 * @brief Perform actions before the view closes
 */
- (void)viewWillClose
{
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium notificationCenter] removeObserver:self];
}

/*!
 * @brief Account status changed.
 *
 * Disable the service menu and user name field for connected accounts
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		if ([inModifiedKeys containsObject:@"Online"] ||
			[inModifiedKeys containsObject:@"Enabled"] ||
		   [inModifiedKeys containsObject:@"Connecting"] ||
		   [inModifiedKeys containsObject:@"Disconnecting"] ||
//		   [inModifiedKeys containsObject:@"ConnectionProgressString"] ||
//		   [inModifiedKeys containsObject:@"ConnectionProgressPercent"] ||
		   [inModifiedKeys containsObject:@"IdleSince"] ||
		   [inModifiedKeys containsObject:@"StatusState"]) {

			//Refresh this account in our list
			int accountRow = [accountArray indexOfObject:inObject];
			if (accountRow >= 0 && accountRow < [accountArray count]) {
				[tableView_accountList setNeedsDisplayInRect:[tableView_accountList rectOfRow:accountRow]];
			}
			
			//Update our account overview
			[self updateAccountOverview];
		}
	}
    
    return nil;
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
	AIService	*service = [sender representedObject];
	AIAccount	*account = [[adium accountController] createAccountWithService:service
																		   UID:[service defaultUserName]];

	[AIEditAccountWindowController editAccount:account
									  onWindow:[[self view] window]
							   notifyingTarget:self];
}

- (void)editAccount:(AIAccount *)inAccount
{
	[AIEditAccountWindowController editAccount:inAccount
									  onWindow:[[self view] window]
							   notifyingTarget:self];	
}

/*!
 * @brief Edit the currently selected account using <tt>AIEditAccountWindowController</tt>
 */
- (IBAction)editSelectedAccount:(id)sender
{
    int	selectedRow = [tableView_accountList selectedRow];
	if (selectedRow >= 0 && selectedRow < [accountArray count]) {
		[self editAccount:[accountArray objectAtIndex:selectedRow]];
    }
}

/*
 * @brief Handle a double click within our table
 *
 * Ignore double clicks on the enable/disable checkbox
 */
- (void)doubleClickInTableView:(id)sender
{
	if (!(NSPointInRect([tableView_accountList convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil],
						[tableView_accountList rectOfColumn:[tableView_accountList columnWithIdentifier:@"enabled"]]))) {
		[self editAccount:sender];
	}
}

/*!
 * @brief Editing of an account completed
 */
- (void)editAccountSheetDidEndForAccount:(AIAccount *)inAccount withSuccess:(BOOL)successful
{
	BOOL existingAccount = ([[[adium accountController] accounts] containsObject:inAccount]);
	
	if (!existingAccount && successful) {
		//New accounts need to be added to our account list once they're configured
		[[adium accountController] addAccount:inAccount];

		//Scroll the new account visible so that the user can see we added it
		[tableView_accountList scrollRowToVisible:[accountArray indexOfObject:inAccount]];
		
		//Put new accounts online by default
		[inAccount setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
	}
}

/*!
 * @brief Delete the selected account
 *
 * Prompts for confirmation first
 */
- (IBAction)deleteAccount:(id)sender
{
    int index = [tableView_accountList selectedRow];

    if (index != -1) {		
		AIAccount	*targetAccount;
		NSString    *accountFormattedUID;

		targetAccount = [accountArray objectAtIndex:index];
		accountFormattedUID = [targetAccount formattedUID];

		//Confirm before deleting
		NSBeginAlertSheet(AILocalizedString(@"Delete Account",nil),
						  AILocalizedString(@"Delete",nil),
						  AILocalizedString(@"Cancel",nil),
						  @"",[[self view] window], self, 
						  @selector(deleteAccountSheetDidEnd:returnCode:contextInfo:), nil, targetAccount, 
						  AILocalizedString(@"Delete the account %@?",nil), ([accountFormattedUID length] ? accountFormattedUID : NEW_ACCOUNT_DISPLAY_TEXT));
	}
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
    
    if (returnCode == NSAlertDefaultReturn) {
        //Delete it
        index = [accountArray indexOfObject:targetAccount];
        [[adium accountController] deleteAccount:targetAccount];
		
        //If it was the last row, select the new last row (by default the selection will jump to the top, which is bad)
        if (index >= [accountArray count]) {
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
    AIImageTextCell		*cell;
	NSRect				oldFrame, newFrame;
	
	//Setup our edit button, keeping its right side in the same location
	oldFrame = [button_editAccount frame];
	[button_editAccount setTitle:AILocalizedString(@"Edit",nil)];
	[button_editAccount sizeToFit];
	newFrame = [button_editAccount frame];
	if (newFrame.size.width < oldFrame.size.width) newFrame.size.width = oldFrame.size.width;
	newFrame.origin.x = oldFrame.origin.x + oldFrame.size.width - newFrame.size.width;
	[button_editAccount setFrame:newFrame];

	//Configure our table view
	[tableView_accountList setTarget:self];
	[tableView_accountList setDoubleAction:@selector(doubleClickInTableView:)];
	[tableView_accountList setIntercellSpacing:NSMakeSize(4,4)];

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
	accountArray = [[[adium accountController] accounts] retain];

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
	NSString	*accountOverview;
	int			accountArrayCount = [accountArray count];

	if (accountArrayCount == 0) {
		accountOverview = AILocalizedString(@"Click the + to add a new account","Instructions on how to add an account when none are present");

	} else {
		NSEnumerator	*enumerator = [accountArray objectEnumerator];
		AIAccount		*account;
		int				online = 0, enabled = 0;
		
		//Count online accounts
		while ((account = [enumerator nextObject])) {
			if ([account online]) online++;
			if ([account enabled]) enabled++;
		}
		
		if (enabled) {
			if ((accountArrayCount == enabled) ||
				(online == enabled)){
				accountOverview = [NSString stringWithFormat:AILocalizedString(@"%i accounts, %i online","Overview of total and online accounts"),
					accountArrayCount,
					online];
			} else {
				accountOverview = [NSString stringWithFormat:AILocalizedString(@"%i accounts, %i enabled, %i online","Overview of total, enabled, and online accounts"),
					accountArrayCount,
					enabled,
					online];			
			}
		} else {
			accountOverview = AILocalizedString(@"Check a box to enable an account","Instructions for enabling an account");
		}
	}

	[textField_overview setStringValue:accountOverview];
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
	return [accountArray count];
}

/*!
 * @brief Table values
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString 	*identifier = [tableColumn identifier];
	AIAccount	*account = [accountArray objectAtIndex:row];
	
	if ([identifier isEqualToString:@"service"]) {
		return [[AIServiceIcons serviceIconForObject:account
												type:AIServiceIconLarge
										   direction:AIIconNormal] imageByScalingToSize:NSMakeSize(24,24)
																			   fraction:([account enabled] ?
																						 1.0 :
																						 0.75)];

	} else if ([identifier isEqualToString:@"name"]) {
		return [[account formattedUID] length] ? [account formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT;
		
	} else if ([identifier isEqualToString:@"status"]) {
		NSString	*title;
		
		if ([account enabled]) {
			if ([[account statusObjectForKey:@"Connecting"] boolValue]) {
				title = AILocalizedString(@"Connecting",nil);
			} else if ([[account statusObjectForKey:@"Disconnecting"] boolValue]) {
				title = AILocalizedString(@"Disconnecting",nil);
			} else if ([[account statusObjectForKey:@"Online"] boolValue]) {
				title = AILocalizedString(@"Online",nil);
			} else {
				title = STATUS_DESCRIPTION_OFFLINE;
			}

		} else {
			title = AILocalizedString(@"Disabled",nil);
		}

		return title;
		
	} else if ([identifier isEqualToString:@"statusicon"]) {

		return [AIStatusIcons statusIconForListObject:account type:AIStatusIconList direction:AIIconNormal];
		
	} else if ([identifier isEqualToString:@"enabled"]) {
		return nil;

	} else if ([identifier isEqualToString:@"icon"]) {
		return [[account userIcon] imageByScalingToSize:NSMakeSize(28,28)];
		
	}

	return nil;
}

/*!
 * @brief Configure cells before display
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString 	*identifier = [tableColumn identifier];
	AIAccount	*account = [accountArray objectAtIndex:row];
	
	if ([identifier isEqualToString:@"enabled"]) {
		[cell setState:([account enabled] ? NSOnState : NSOffState)];

	} else if ([identifier isEqualToString:@"name"]) {
		[cell setEnabled:[account enabled]];

	} else if ([identifier isEqualToString:@"status"]) {
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
	if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
		[[accountArray objectAtIndex:row] setEnabled:[(NSNumber *)object boolValue]];
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
    
    return YES;
}

/*!
 * @brief Drag validate
 */
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if (op == NSTableViewDropAbove && row != -1) {
        return NSDragOperationPrivate;
    } else {
        return NSDragOperationNone;
    }
}

/*!
 * @brief Drag complete
 */
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:ACCOUNT_DRAG_TYPE]];
	
    if ([avaliableType isEqualToString:@"AIAccount"]) {
        int newIndex = [[adium accountController] moveAccount:tempDragAccount toIndex:row];
        [tableView_accountList selectRow:newIndex byExtendingSelection:NO];
		
        return YES;
    } else {
        return NO;
    }
}

/*!
 * @brief Selection change
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateControlAvailability];
}

/*!
 * @brief Set up KFTypeSelectTableView
 *
 * Only search the "name" column.
 */
- (void)configureTypeSelectTableView:(KFTypeSelectTableView *)tableView
{
    [tableView setSearchColumnIdentifiers:[NSSet setWithObject:@"name"]];
}

@end
