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

#import <Adium/AIAccountControllerProtocol.h>
#import "AIAccountListPreferences.h"
#import <Adium/AIContactControllerProtocol.h>
#import "AIStatusController.h"
#import "AIEditAccountWindowController.h"
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>
#import <AIUtilities/AITableViewAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIAccountMenu.h>
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIServiceMenu.h>
#import <Adium/AIStatusIcons.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import "KFTypeSelectTableView.h"

#define MINIMUM_ROW_HEIGHT				34
#define MINIMUM_CELL_SPACING			 4

#define	ACCOUNT_DRAG_TYPE				@"AIAccount"	    			//ID for an account drag

#define NEW_ACCOUNT_DISPLAY_TEXT		AILocalizedString(@"<New Account>", "Placeholder displayed as the name of a new account")

@interface AIAccountListPreferences (PRIVATE)
- (void)configureAccountList;
- (void)accountListChanged:(NSNotification *)notification;

- (void)calculateHeightForRow:(int)row;
- (void)calculateAllHeights;

- (void)updateReconnectTime:(NSTimer *)timer;
@end

@implementation NSTableView (rightClickMenu)

// Override the menuForEvent so we can generate one.
- (NSMenu *)menuForEvent: (NSEvent *)event
{
	int row = [self rowAtPoint:[self convertPoint:[event locationInWindow] toView:nil]];
	// Select the row.
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	// Return our delegate's menu for this row.
	return [(AIAccountListPreferences *)[self dataSource] menuForRow:row];
}

@end

/*!
 * @class AIAccountListPreferences
 * @brief Shows a list of accounts and provides for management of them
 */
@implementation AIAccountListPreferences

/*!
 * @brief Preference pane properties
 */
- (NSString *)paneIdentifier
{
	return @"Accounts";
}
- (NSString *)paneName{
    return AILocalizedString(@"Accounts","Accounts preferences label");
}
- (NSString *)nibName{
    return @"AccountListPreferences";
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"pref-accounts" forClass:[self class]];
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
	
	//Set ourselves up for Account Menus
	accountMenu = [[AIAccountMenu accountMenuWithDelegate:self
											  submenuType:AIAccountOptionsSubmenu
										   showTitleVerbs:NO] retain];

	//Observe status icon pack changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(iconPackDidChange:)
									   name:AIStatusIconSetDidChangeNotification
									 object:nil];
	
	//Observe service icon pack changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(iconPackDidChange:)
									   name:AIServiceIconSetDidChangeNotification
									 object:nil];
	
	// Start updating the reconnect time if an account is already reconnecting.	
	[self updateReconnectTime:nil];
}

/*!
 * @brief Perform actions before the view closes
 */
- (void)viewWillClose
{
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium notificationCenter] removeObserver:self];
	
	[accountArray release]; accountArray = nil;
	[requiredHeightDict release]; requiredHeightDict = nil;
	[accountMenu release]; accountMenu = nil;
	
	// Cancel our auto-refreshing reconnect countdown.
	[reconnectTimeUpdater invalidate];
	[reconnectTimeUpdater release]; reconnectTimeUpdater = nil;
}

- (void)dealloc
{
	[accountArray release];
	[super dealloc];
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
		   [inModifiedKeys containsObject:@"Waiting to Reconnect"] ||
		   [inModifiedKeys containsObject:@"Disconnecting"] ||
		   [inModifiedKeys containsObject:@"ConnectionProgressString"] ||
		   [inModifiedKeys containsObject:@"ConnectionProgressPercent"] ||
		   [inModifiedKeys containsObject:@"IdleSince"] ||
		   [inModifiedKeys containsObject:@"StatusState"]) {

			//Refresh this account in our list
			int accountRow = [accountArray indexOfObject:inObject];
			if (accountRow >= 0 && accountRow < [accountArray count]) {
				[tableView_accountList setNeedsDisplayInRect:[tableView_accountList rectOfRow:accountRow]];
				// Update the height of the row.
				[self calculateHeightForRow:accountRow];
				[tableView_accountList noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:accountRow]];

				// If necessary, update our reconnection display time.
				if (!reconnectTimeUpdater) {
					[self updateReconnectTime:nil];
				}
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

/*!
 * @brief Handle a double click within our table
 *
 * Ignore double clicks on the enable/disable checkbox
 */
- (void)doubleClickInTableView:(id)sender
{
	if (!(NSPointInRect([tableView_accountList convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil],
						[tableView_accountList rectOfColumn:[tableView_accountList columnWithIdentifier:@"enabled"]]))) {
		[self editSelectedAccount:sender];
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

    if (index >= 0 && index < [accountArray count])
		[[[adium accountController] deleteAccount:[accountArray objectAtIndex:index]] beginSheetModalForWindow:[[self view] window]];
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
	[button_editAccount setTitle:AILocalizedStringFromTable(@"Edit", @"Buttons", "Verb 'edit' on a button")];
	[button_editAccount sizeToFit];
	newFrame = [button_editAccount frame];
	if (newFrame.size.width < oldFrame.size.width) newFrame.size.width = oldFrame.size.width;
	newFrame.origin.x = oldFrame.origin.x + oldFrame.size.width - newFrame.size.width;
	[button_editAccount setFrame:newFrame];

	//Configure our table view
	[tableView_accountList setTarget:self];
	[tableView_accountList setDoubleAction:@selector(doubleClickInTableView:)];
	[tableView_accountList setIntercellSpacing:NSMakeSize(MINIMUM_CELL_SPACING, MINIMUM_CELL_SPACING)];

	//Enable dragging of accounts
	[tableView_accountList registerForDraggedTypes:[NSArray arrayWithObjects:ACCOUNT_DRAG_TYPE,nil]];
	
    //Custom vertically-centered text cell for account names
    cell = [[AIImageTextCell alloc] init];
    [cell setFont:[NSFont boldSystemFontOfSize:13]];
    [[tableView_accountList tableColumnWithIdentifier:@"name"] setDataCell:cell];
	[cell setLineBreakMode:NSLineBreakByWordWrapping];
	[cell release];

    cell = [[AIImageTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:13]];
    [cell setAlignment:NSRightTextAlignment];
    [[tableView_accountList tableColumnWithIdentifier:@"status"] setDataCell:cell];
	[cell release];
    
	[tableView_accountList sizeToFit];

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
	[self calculateAllHeights];
}


/*!
 * @brief AIAccountMenu deligate method
 */
- (void)accountMenu:(AIAccountMenu *)inAccountMenu didRebuildMenuItems:(NSArray *)menuItems {
	return;
}

/*!
* @brief AIAccountMenu deligate method -- this allows disabled items to have menus.
 */
- (BOOL)accountMenu:(AIAccountMenu *)inAccountMenu shouldIncludeAccount:(AIAccount *)inAccount
{
	return YES;
}

/*!
* @brief Returns the status menu associated with a particular row
 */
- (NSMenu *)menuForRow:(int)row
{
	if (row >= 0 && row < [accountArray count]) {
		return [[accountMenu menuItemForAccount:[accountArray objectAtIndex:row]] submenu];
	}
	
	return nil;
}

/*!
 * @brief Updates reconnecting time where necessary.
 */
- (void)updateReconnectTime:(NSTimer *)timer
{
	int				accountRow;
	BOOL			moreUpdatesNeeded = NO;

	for (accountRow = 0; accountRow < [accountArray count]; accountRow++) {
		if ([[accountArray objectAtIndex:accountRow] statusObjectForKey:@"Waiting to Reconnect"] != nil) {
			[tableView_accountList setNeedsDisplayInRect:[tableView_accountList rectOfRow:accountRow]];
			moreUpdatesNeeded = YES;
		}
	}

	if (moreUpdatesNeeded && reconnectTimeUpdater == nil) {
		reconnectTimeUpdater = [[NSTimer scheduledTimerWithTimeInterval:1.0
																 target:self 
															   selector:@selector(updateReconnectTime:) 
															   userInfo:nil
																repeats:YES] retain];
	} else if (!moreUpdatesNeeded && reconnectTimeUpdater != nil) {
		[reconnectTimeUpdater invalidate];
		[reconnectTimeUpdater release]; reconnectTimeUpdater = nil;
	}
}

/*!
 * @brief Status icons changed, refresh our table
 */
- (void)iconPackDidChange:(NSNotification *)notification
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

/*!
* @brief Returns the status string associated with the account
 *
 * Returns a connection status if connecting, or an error if disconnected with an error
 */
- (NSString *)statusMessageForAccount:(AIAccount *)account
{
	NSString *statusMessage = nil;
	
	if ([account statusObjectForKey:@"ConnectionProgressString"] && [[account statusObjectForKey:@"Connecting"] boolValue]) {
		// Connection status if we're currently connecting, with the percent at the end
		statusMessage = [[account statusObjectForKey:@"ConnectionProgressString"] stringByAppendingFormat:@" (%2.f%%)", [[account statusObjectForKey:@"ConnectionProgressPercent"] floatValue]*100.0];
	} else if ([account lastDisconnectionError] && ![[account statusObjectForKey:@"Online"] boolValue] && ![[account statusObjectForKey:@"Connecting"] boolValue]) {
		// If there's an error and we're not online and not connecting
		NSMutableString *returnedMessage = [[[account lastDisconnectionError] mutableCopy] autorelease];
		
		// Replace the LibPurple error prefixes
		[returnedMessage replaceOccurrencesOfString:@"Could not establish a connection with the server:\n"
										 withString:@""
											options:NSLiteralSearch
											  range:NSMakeRange(0, [returnedMessage length])];
		[returnedMessage replaceOccurrencesOfString:@"Connection error from Notification server:\n"
										 withString:@""
											options:NSLiteralSearch
											  range:NSMakeRange(0, [returnedMessage length])];

		// Remove newlines from the error message, replace them with spaces
		[returnedMessage replaceOccurrencesOfString:@"\n"
										 withString:@" "
											options:NSLiteralSearch
											  range:NSMakeRange(0, [returnedMessage length])];
		
		statusMessage = [NSString stringWithFormat:@"%@: %@", AILocalizedString(@"Error", "Prefix to error messages in the Account List."), returnedMessage];
	}
	
	return statusMessage;
}

/*!
* @brief Calculates the height of a given row and stores it
 */
- (void)calculateHeightForRow:(int)row
{	
	// Make sure this is a valid row.
	if (row < 0 || row >= [accountArray count]) {
		return;
	}
	
	AIAccount		*account = [accountArray objectAtIndex:row];
	float			necessaryHeight = MINIMUM_ROW_HEIGHT;
	
	// If there's a status message, let's try size to fit it.
	if ([self statusMessageForAccount:account]) {
		NSTableColumn		*tableColumn = [tableView_accountList tableColumnWithIdentifier:@"name"];
		
		[self tableView:tableView_accountList willDisplayCell:[tableColumn dataCell] forTableColumn:tableColumn row:row];
		
		// Main string (account name)
		NSDictionary		*mainStringAttributes	= [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:13], NSFontAttributeName, nil];
		NSAttributedString	*mainTitle = [[NSAttributedString alloc] initWithString:([[account formattedUID] length] ? [account formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT)
																		 attributes:mainStringAttributes];
		
		// Substring (the status message)
		NSDictionary		*subStringAttributes	= [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:10], NSFontAttributeName, nil];
		NSAttributedString	*subStringTitle = [[NSAttributedString alloc] initWithString:[self statusMessageForAccount:account]
																			  attributes:subStringAttributes];
		
		// Both heights combined, with spacing in-between
		float combinedHeight = [mainTitle heightWithWidth:[tableColumn width]] + [subStringTitle heightWithWidth:[tableColumn width]] + MINIMUM_CELL_SPACING;
		
		// Make sure we're not down-sizing
		if (combinedHeight > necessaryHeight) {
			necessaryHeight = combinedHeight;
		}
		
		[subStringTitle release];
		[mainTitle release];
	}
	
	// Cache the height value
	[requiredHeightDict setObject:[NSNumber numberWithFloat:necessaryHeight]
						   forKey:[NSNumber numberWithInt:row]];
}

/*!
* @brief Calculates the height of all rows
 */
- (void)calculateAllHeights
{
	int accountNumber;

	[requiredHeightDict release]; requiredHeightDict = [[NSMutableDictionary alloc] init];

	for (accountNumber = 0; accountNumber < [accountArray count]; accountNumber++) {
		[self calculateHeightForRow:accountNumber];
	}
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
	if (row < 0 || row >= [accountArray count]) {
		return nil;
	}
	
	NSString 	*identifier = [tableColumn identifier];
	AIAccount	*account = [accountArray objectAtIndex:row];
	
	if ([identifier isEqualToString:@"service"]) {
		return [[AIServiceIcons serviceIconForObject:account
												type:AIServiceIconLarge
										   direction:AIIconNormal] imageByScalingToSize:NSMakeSize(MINIMUM_ROW_HEIGHT-2, MINIMUM_ROW_HEIGHT-2)
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
			} else if ([account statusObjectForKey:@"Waiting to Reconnect"]) {
				title = AILocalizedString(@"Reconnecting", @"Used when the account will perform an automatic reconnection after a certain period of time.");
			} else {
				title = [[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_OFFLINE];
			}

		} else {
			title = AILocalizedString(@"Disabled",nil);
		}

		return title;
		
	} else if ([identifier isEqualToString:@"statusicon"]) {

		return [AIStatusIcons statusIconForListObject:account type:AIStatusIconList direction:AIIconNormal];
		
	} else if ([identifier isEqualToString:@"enabled"]) {
		return nil;

	}

	return nil;
}
/*!
 * @brief Configure the height of each account for error messages if necessary
 */
- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row
{
	// We should probably have this value cached.
	float necessaryHeight = MINIMUM_ROW_HEIGHT;
	
	NSNumber *cachedHeight = [requiredHeightDict objectForKey:[NSNumber numberWithInt:row]];
	if (cachedHeight) {
		necessaryHeight = [cachedHeight floatValue];
	}
	
	return necessaryHeight;
}

/*!
 * @brief Configure cells before display
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	// Make sure this row actually exists
	if (row < 0 || row >= [accountArray count]) {
		return;
	}

	NSString 	*identifier = [tableColumn identifier];
	AIAccount	*account = [accountArray objectAtIndex:row];
	
	if ([identifier isEqualToString:@"enabled"]) {
		[cell setState:([account enabled] ? NSOnState : NSOffState)];

	} else if ([identifier isEqualToString:@"name"]) {
		[cell setEnabled:[account enabled]];

		// Update the subString with our current status message (if it exists);
		[cell setSubString:[self statusMessageForAccount:account]];
		
	} else if ([identifier isEqualToString:@"status"]) {
		if ([account enabled] && ![[account statusObjectForKey:@"Connecting"] boolValue] && [account statusObjectForKey:@"Waiting to Reconnect"]) {
			NSString *format = [NSDateFormatter stringForTimeInterval:[[account statusObjectForKey:@"Waiting to Reconnect"] timeIntervalSinceNow]
													   showingSeconds:YES
														  abbreviated:YES
														 approximated:NO];
			
			[cell setSubString:[NSString stringWithFormat:AILocalizedString(@"...in %@", @"The amount of time until a reconnect occurs. %@ is the formatted time remaining."), format]];
		} else {
			[cell setSubString:nil];
		}
		
		[cell setEnabled:([[account statusObjectForKey:@"Connecting"] boolValue] ||
						  [account statusObjectForKey:@"Waiting to Reconnect"] ||
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
	if (row >= 0 && row < [accountArray count] && [[tableColumn identifier] isEqualToString:@"enabled"]) {
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
