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

#import "AIAccountListWindowController.h"

#define	ACCOUNT_DRAG_TYPE					@"AIAccount"	    										//ID for an account drag
#define	ACCOUNT_CONNECT_BUTTON_TITLE		AILocalizedString(@"Connect","Connect an account")	    	//Menu item title for the connect item
#define	ACCOUNT_DISCONNECT_BUTTON_TITLE		AILocalizedString(@"Disconnect","Disconnect an account")    //Menu item title
#define	ACCOUNT_CONNECTING_BUTTON_TITLE		AILocaliedString(@"Connecting...",nil)						//Menu item title
#define	ACCOUNT_DISCONNECTING_BUTTON_TITLE	AILocalizedString(@"Disconnecting...",nil)					//Menu item title

#define ACCOUNT_LIST_WINDOW_NIB				@"AccountListWindow"

@interface AIAccountListWindowController (PRIVATE)
- (void)configureViewForAccount:(AIAccount *)inAccount;
- (void)configureViewForService:(AIService *)inService;
- (void)_addCustomViewAndTabsForController:(AIAccountViewController *)inControler;
- (void)_removeCustomViewAndTabs;
- (void)enableDisableControls;
- (void)updateAccountConnectionProgress;
- (void)configureAccountList;
- (void)accountListChanged:(NSNotification *)notification;
- (void)_configureResponderChain:(NSTimer *)inTimer;
- (void)passwordReturnedForRegister:(NSString *)inPassword context:(id)inContext;
@end

@implementation AIAccountListWindowController

AIAccountListWindowController *sharedAccountWindowInstance = nil;
+ (AIAccountListWindowController *)accountListWindowController
{
    if(!sharedAccountWindowInstance){
        sharedAccountWindowInstance = [[self alloc] initWithWindowNibName:ACCOUNT_LIST_WINDOW_NIB];
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



//Configure the preference view
- (void)windowDidLoad
{
    //init
    accountViewController = nil;
	configuredForService = nil;
	configuredForAccount = nil;
	
	//Configure controls
	NSMenu	*serviceMenu = [[adium accountController] menuOfServicesWithTarget:self 
															activeServicesOnly:NO
															   longDescription:YES
																		format:AILocalizedString(@"Add %@ Account...",nil)];
	[serviceMenu setAutoenablesItems:YES];
	[button_newAccount setMenu:serviceMenu];
    [textField_accountName setDelayInterval:1.0];
	[self configureAccountList];

	//Observe account list objects so we can enable/disable our controls for connected accounts
    [[adium contactController] registerListObjectObserver:self];
	
	//If no account are available, create one.  Called on a delay so it doesn't happen until our view
	//is visible in the preference window (And the first-responder stuff works correctly)
	if([[[adium accountController] accountArray] count] == 0){
		[self performSelector:@selector(selectServiceType:) withObject:nil afterDelay:0.0001];
	}
	
	//Center this panel
	[[self window] center];
}

//Close
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//closing
- (BOOL)windowShouldClose:(id)sender
{
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium notificationCenter] removeObserver:self];
	
	//Halt any incomplete timers
	[responderChainTimer invalidate];
	[responderChainTimer release];
	responderChainTimer = nil;
	
	//Get any final changes to the UID field
	[textField_accountName fireImmediately];
	
	//Cleanup and close our shared instance
	[configuredForAccount release]; configuredForAccount = nil;
    [accountViewController release]; accountViewController = nil;
	[sharedAccountWindowInstance autorelease]; sharedAccountWindowInstance = nil;
	
	return(YES);
}


//Configuring ---------------------------------------------------------------------------------------------
#pragma mark Configuring
//Configure the account preferences for an account
- (void)configureViewForAccount:(AIAccount *)inAccount
{
	NSData	*iconData;

	//If necessary, configure for the account's service first
	if([inAccount service] != configuredForService){
		[self configureViewForService:[inAccount service]];
	}

	//Configure for the account
	[configuredForAccount release]; configuredForAccount = [inAccount retain];
	[accountViewController configureForAccount:inAccount];
	[self enableDisableControls];
	[self updateAccountConnectionProgress];

	//Fill in the account's name and auto-connect status
	NSString	*formattedUID = [inAccount preferenceForKey:@"FormattedUID" group:GROUP_ACCOUNT_STATUS];
	[textField_accountName setStringValue:(formattedUID && [formattedUID length] ? formattedUID : [inAccount UID])];
	[button_autoConnect setState:[[inAccount preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue]];
	
	//User icon
	if(iconData = [inAccount preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS]){
		NSImage *image = [[NSImage alloc] initWithData:iconData];
		[imageView_userIcon setImage:image];
		[image release];
	}        
}

//Configure the account preferences for a service.  This determines which controls are loaded and the allowed values
- (void)configureViewForService:(AIService *)inService
{
	//Select the new service
	configuredForService = inService;
//    [popupMenu_serviceList selectItemAtIndex:[popupMenu_serviceList indexOfItemWithRepresentedObject:inService]];
	
	//Insert the custom controls for this service
	[self _removeCustomViewAndTabs];
	[self _addCustomViewAndTabsForController:[inService accountView]];
	
	//Custom username string
	NSString *userNameLabel = [inService userNameLabel];
	[textField_userNameLabel setStringValue:[(userNameLabel ? userNameLabel : @"User Name") stringByAppendingString:@":"]];
	
	//Restrict the account name field to valid characters and length
    [textField_accountName setFormatter:
		[AIStringFormatter stringFormatterAllowingCharacters:[inService allowedCharactersForAccountName]
													  length:[inService allowedLengthForAccountName]
											   caseSensitive:[inService caseSensitive]
												errorMessage:AILocalizedString(@"The characters you're entering are not valid for an account name on this service.",nil)]];
	
	//Hide/show the Register button as appropriate
	BOOL shouldShowRegisterButton = [inService canRegisterNewAccounts];
	if ([button_register respondsToSelector:@selector(setHidden:)]){
		[button_register setHidden:(!shouldShowRegisterButton)];
	}else{
		[button_register setEnabled:(!shouldShowRegisterButton)];
	}
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

	//Setup the responder chain
	[self _configureResponderChain:nil];
	
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

//Hook up the responder chain
//Must wait until our view is visible to do this, otherwise our requests to setup the chain will be ignored.
//So, this method waits until our view becomes visible, and then sets up the chain :)
- (void)_configureResponderChain:(NSTimer *)inTimer
{
	[responderChainTimer invalidate];
	[responderChainTimer release];
	responderChainTimer = nil;
	
#warning hack	if([view canDraw]){
		NSView	*accountView = [accountViewController view];
		
		//Name field goes to first control in account view
		[textField_accountName setNextKeyView:[accountView nextValidKeyView]];
		
		//Last control in account view goes to account list
		NSView	*nextView = [accountView nextKeyView];
		while([nextView nextKeyView]) nextView = [nextView nextKeyView];
		[nextView setNextKeyView:tableView_accountList];
		
		//Account list goes to service menu
//		[tableView_accountList setNextKeyView:popupMenu_serviceList];
/*	}else{
		responderChainTimer = [[NSTimer scheduledTimerWithTimeInterval:0.001
															   target:self
															 selector:@selector(_configureResponderChain:)
															 userInfo:nil
															  repeats:NO] retain]; 
	}*/
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
- (IBAction)changeUIDField:(id)sender
{
	NSString *newUID = [textField_accountName stringValue];
	if(![[configuredForAccount UID] isEqualToString:newUID])
		[[adium accountController] changeUIDOfAccount:configuredForAccount to:newUID];	
}

//
- (IBAction)toggleConnectStatus:(id)sender
{		
	//Get any final changes to the UID field
	[textField_accountName fireImmediately];

	if([[configuredForAccount statusObjectForKey:@"Connecting"] boolValue]){
		//cancel the currently connecting account - if the user's into that sort of thing.
		[configuredForAccount setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
		
	}else{
		BOOL	goOnline = (![[configuredForAccount statusObjectForKey:@"Online"] boolValue] &&
							![[configuredForAccount statusObjectForKey:@"Disconnecting"] boolValue]);
		
		//If a field doesn't send its action until the user presses enter (the password field, for example), we should save
		//immediately so the newly-inputted value is available as we try to connect
		if (goOnline){
			[accountViewController saveFieldsImmediately];
		}
		
		[configuredForAccount setPreference:[NSNumber numberWithBool:goOnline] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
	}
}

- (IBAction)registerAccount:(id)sender
{
	//If a field doesn't send its action until the user presses enter (the password field, for example), we should save
	//immediately so the newly-inputted value is available as we try to register
	[accountViewController saveFieldsImmediately];
	
	if (![configuredForAccount UID]){
		NSRunAlertPanel(AILocalizedString(@"Unable to Register",nil),
						AILocalizedString(@"Please input a username and password before clicking Register.",nil),
						AILocalizedString(@"OK",nil), nil, nil);
	}else{
		if ([configuredForAccount requiresPassword]){
			//Retrieve the user's password and then call connect
			[[adium accountController] passwordForAccount:configuredForAccount 
										  notifyingTarget:self
												 selector:@selector(passwordReturnedForRegister:context:)
												  context:nil];
		}else{
			//Connect immediately without retrieving a password
			[self passwordReturnedForRegister:nil context:nil];
		}
	}
}

//Callback after the user enters their password for registering
- (void)passwordReturnedForRegister:(NSString *)inPassword context:(id)inContext
{
	if (inPassword || ![configuredForAccount requiresPassword]){
		[configuredForAccount performRegisterWithPassword:inPassword];
	}
}

//User toggled the autoconnect preference
- (IBAction)toggleAutoConnect:(id)sender
{
	BOOL		autoConnect = [sender state];
	
	[configuredForAccount setPreference:[NSNumber numberWithBool:autoConnect]
								 forKey:@"AutoConnect"
								  group:GROUP_ACCOUNT_STATUS];
}

//User changed account icon
- (void)imageViewWithImagePicker:(ESImageViewWithImagePicker *)sender didChangeToImage:(NSImage *)image
{
    [configuredForAccount setPreference:[image PNGRepresentation] forKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS];
}
- (void)deleteInImageViewWithImagePicker:(ESImageViewWithImagePicker *)sender
{
	[configuredForAccount setPreference:nil forKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS];
}

//Disable controls for account that are connected
- (void)enableDisableControls
{
	BOOL	accountEditable = (![[configuredForAccount statusObjectForKey:@"Online"] boolValue] &&
							   ![[configuredForAccount statusObjectForKey:@"Connecting"] boolValue] &&
							   ![[configuredForAccount statusObjectForKey:@"Disconnecting"] boolValue]);
	
//	[popupMenu_serviceList setEnabled:(configuredForAccount && accountEditable)];
	[textField_accountName setEnabled:(configuredForAccount && accountEditable)];
	[button_autoConnect setEnabled:(configuredForAccount != nil)];
	[button_deleteAccount setEnabled:([accountArray count] > 1 && configuredForAccount && accountEditable)];
}

//Update status string and bar
- (void)updateAccountConnectionProgress
{
	BOOL	accountBusy = ([[configuredForAccount statusObjectForKey:@"Connecting"] boolValue] ||
						   [[configuredForAccount statusObjectForKey:@"Disconnecting"] boolValue]);

	//Update the status string and progress bar
	if(!accountBusy){
		[textField_status setStringValue:@""];
		[progress_status setDoubleValue:0.0];
		if([progress_status respondsToSelector:@selector(setHidden:)]) [progress_status setHidden:YES];

	}else{
		NSString	*status = [configuredForAccount statusObjectForKey:@"ConnectionProgressString"];
		float		progressPercent = ([[configuredForAccount statusObjectForKey:@"ConnectionProgressPercent"] floatValue]*100);
		[textField_status setStringValue:(status ? status : @"")];
		
		if ((progressPercent > 0) && (progressPercent <= 100)){
			if([progress_status respondsToSelector:@selector(setHidden:)]) [progress_status setHidden:NO];
			[progress_status setDoubleValue:progressPercent];
		}
		
	}
	
	//Force the controls to display
	//[textField_status setNeedsDisplay:YES];
	//[progress_status  setNeedsDisplay:YES];
	
	//Update the 'connect' button's title to match its action
	if([[configuredForAccount statusObjectForKey:@"Online"] boolValue]){
		[button_toggleConnect setTitle:@"Disconnect"];
	}else if([[configuredForAccount statusObjectForKey:@"Connecting"] boolValue] ||
			 [[configuredForAccount statusObjectForKey:@"Disconnecting"] boolValue]){
		[button_toggleConnect setTitle:@"Cancel"];
	}else{
		[button_toggleConnect setTitle:@"Connect"];
	}
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

			//If this account is the one we're displaying, update our control availability and progress display
			if(inObject == configuredForAccount){		
				[self enableDisableControls];
				[self updateAccountConnectionProgress];
			}			
		}
	}
    
    return(nil);
}

//We need to make sure all changes to the account have been saved before a service switch occurs.
//This code is called when the service menu is opened, and takes focus away from the first responder,
//causing it to save any outstanding changes.
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	//XXX
//	[[popupMenu_serviceList window] makeFirstResponder:popupMenu_serviceList];
		[[button_newAccount window] makeFirstResponder:button_newAccount];
	
	return(YES);
}


//Account List ---------------------------------------------------------------------------------------------------------
#pragma mark Account List
//Configure the account list table
- (void)configureAccountList
{
    AIImageTextCell			*cell;
	
    //Configure our tableView
    cell = [[AIImageTextCell alloc] init];
    [cell setFont:[NSFont systemFontOfSize:13]];
    [[tableView_accountList tableColumnWithIdentifier:@"description"] setDataCell:cell];
	[cell release];
	
    [tableView_accountList registerForDraggedTypes:[NSArray arrayWithObjects:ACCOUNT_DRAG_TYPE,nil]];
    [scrollView_accountList setAutoHideScrollBar:YES];
    
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
- (IBAction)selectServiceType:(id)sender
{
	AIService	*service = [sender representedObject];
    int			index = [tableView_accountList selectedRow] + 1;
	
    AIAccount	*newAccount;
    
    //Add the new account
    newAccount = [[adium accountController] newAccountAtIndex:index forService:service];

    //Select the new account
    [tableView_accountList selectRow:index byExtendingSelection:NO];
    
    //Select the 'Account' tab and put focus on the account fields
    [tabView_auxiliary selectTabViewItemAtIndex:0];
    [[textField_accountName window] makeFirstResponder:textField_accountName];
}

//Delete the selected account
- (IBAction)deleteAccount:(id)sender
{
    int 	index;
    AIAccount	*targetAccount;
    NSString    *accountFormattedUID;
    
    NSParameterAssert(accountArray != nil); NSParameterAssert([accountArray count] > 1);
    
    //Confirm
    index = [tableView_accountList selectedRow];
    NSParameterAssert(index >= 0 && index < [accountArray count]);
    targetAccount = [accountArray objectAtIndex:index];
    accountFormattedUID = [targetAccount formattedUID];

    NSBeginAlertSheet(@"Delete Account",@"Delete",@"Cancel",@"",[self window], self, 
					  @selector(deleteAccountSheetDidEnd:returnCode:contextInfo:), nil, targetAccount, 
					  @"Delete the account %@?", [accountFormattedUID length] ? accountFormattedUID : NEW_ACCOUNT_DISPLAY_TEXT);
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
        [[adium accountController] deleteAccount:targetAccount save:YES];
		
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
	NSString *formattedUID = [[accountArray objectAtIndex:row] formattedUID];
    return([formattedUID length] ? formattedUID : NEW_ACCOUNT_DISPLAY_TEXT);
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    AIAccount   *account = [accountArray objectAtIndex:row];
	NSString	*status = nil;
	
	//Update the 'connect' button's title to match it's action
	if([[account statusObjectForKey:@"Online"] boolValue]){
		status = @"Online";
	}else if([[account statusObjectForKey:@"Connecting"] boolValue]){
		status = @"Connecting";
	}else if([[account statusObjectForKey:@"Disconnecting"] boolValue]){
		status = @"Disconnecting";
	}
	
	[cell setImage:[AIServiceIcons serviceIconForObject:account type:AIServiceIconLarge direction:AIIconNormal]];
	[cell setSubString:(status ?
						[NSString stringWithFormat:@"%@ - %@", [[account service] shortDescription], status] :
						[[account service] shortDescription])];
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

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSResponder	*existingResponder = [[tabView window] firstResponder];
    
    //Take focus away from any controls to ensure that they register changes and save
    [[tabView window] makeFirstResponder:tabView];
	
    //Put focus back
    [[tabView window] makeFirstResponder:existingResponder];
}

#if 0
/* XXX Tiger Thoughts */
/*
NSWindow

Methods have been added to allow a window to automatically recalculate the key view loop after views have been added.
- (void)setAutorecalculatesKeyViewLoop:(BOOL)flag;
- (BOOL)autorecalculatesKeyViewLoop;
- (void)recalculateKeyViewLoop;
	If the autorecalculatesKeyViewLoop is YES, then whenever a view is added to the window, the key view loop
	is dirtied and recalculated automatically when -[NSWindow selectKeyViewFollowingView] or
-[NSWindow selectKeyViewPrecedingView] are called. If autorecalculatesKeyViewLoop is NO, then adding views
	will not dirty the key view loop and the loop will not be recalculated. You can always call explicitly
	recalculateKeyViewLoop to recalculate the loop and clear the dirty key view loop flag. The method is also 
	called if the key view loop needs to be calculated when the window is first ordered in. The loop computed
	is the same as the default one if initialFirstResponder is not set. It is based on the geometric order of 
	the views in the window.
*/
#endif
@end
