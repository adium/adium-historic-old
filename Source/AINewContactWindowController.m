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
#import "AIContactController.h"
#import "AINewContactWindowController.h"
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AILocalizationTextField.h>
#import <Adium/AIService.h>

#define ADD_CONTACT_PROMPT_NIB	@"AddContact"

@interface AINewContactWindowController (PRIVATE)
- (void)buildContactTypeMenu;
- (void)buildGroupMenu;
- (void)_buildGroupMenu:(NSMenu *)menu forGroup:(AIListGroup *)group level:(int)level;
- (void)validateEnteredName;
- (void)updateAccountList;
- (void)configureNameAndService;
- (void)configureForCurrentServiceType;
- (void)setContactName:(NSString *)contact;
- (void)setService:(AIService *)inService;
- (void)selectGroup:(id)sender;
- (void)selectFirstValidServiceType;
- (void)selectServiceType:(id)sender;
- (void)updateContactNameLabel;
@end

/*!
 * @class AINewContactWindowController
 * @brief Window controller for adding a new contact
 */
@implementation AINewContactWindowController

/*!
 * @brief Prompt for adding a new contact.
 *
 * @param parentWindow Window on which to show the prompt as a sheet. Pass nil for a panel prompt. 
 * @param inName Initial value for the contact name field
 * @param inService <tt>AIService</tt> for determining the initial service type selection
 */
+ (void)promptForNewContactOnWindow:(NSWindow *)parentWindow name:(NSString *)inName service:(AIService *)inService
{
	AINewContactWindowController	*newContactWindow;
	
	newContactWindow = [[self alloc] initWithWindowNibName:ADD_CONTACT_PROMPT_NIB];
	[newContactWindow setContactName:inName];
	[newContactWindow setService:inService];
	
	if(parentWindow){
		[parentWindow makeKeyAndOrderFront:nil];
		
		[NSApp beginSheet:[newContactWindow window]
		   modalForWindow:parentWindow
			modalDelegate:newContactWindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	}else{
		[newContactWindow showWindow:nil];
		[[newContactWindow window] makeKeyAndOrderFront:nil];
	}
	
}

/*!
 * @brief Initialize
 */
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];

	return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[accounts release];
	[contactName release];
	[service release];
	
    [super dealloc];
}

/*!
 * @brief Setup the window before it is displayed
 */
- (void)windowDidLoad
{
	[textField_type setLocalizedString:AILocalizedString(@"Contact Type:","Contact type service dropdown label in Add Contact")];
	[textField_alias setLocalizedString:AILocalizedString(@"Alias:",nil)];
	[textField_inGroup setLocalizedString:AILocalizedString(@"In Group:",nil)];
	[textField_addToAccounts setLocalizedString:AILocalizedString(@"Add to Accounts:",nil)];

	[button_add setLocalizedString:AILocalizedString(@"Add",nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel",nil)];

	originalContactNameLabelFrame = [textField_contactNameLabel frame];
	
	[self buildContactTypeMenu];
	[self buildGroupMenu];

	[self configureNameAndService];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(accountListChanged:)
									   name:Account_ListChanged
									 object:nil];

	[[adium contactController] registerListObjectObserver:self];

	[[self window] center];
}

/*!
 * @brief Window is closing
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium notificationCenter] removeObserver:self];
}

/*!
 * @brief Called as the user list edit sheet closes, dismisses the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

/*!
 * @brief Cancel
 */
- (IBAction)cancel:(id)sender
{
	if([[self window] isSheet]){
		[NSApp endSheet:[self window]];
	}else{
		[self closeWindow:nil];
	}
}

/*!
 * @brief Perform the addition of the contact
 */
- (IBAction)addContact:(id)sender
{
	NSString		*UID = [service filterUID:[textField_contactName stringValue] removeIgnoredCharacters:YES];
	NSEnumerator	*enumerator = [accounts objectEnumerator];
	AIListGroup		*group ;
	AIAccount		*account;
	NSString		*alias;
	NSMutableArray	*contactArray = [NSMutableArray array];
	
	alias = [textField_contactAlias stringValue];
	if([alias length] == 0) alias = nil; 

	group = ([popUp_targetGroup numberOfItems] ?
			[[popUp_targetGroup selectedItem] representedObject] : 
			nil);
	
	while(account = [enumerator nextObject]){
		if([account contactListEditable] &&
		   [[account preferenceForKey:KEY_ADD_CONTACT_TO group:PREF_GROUP_ADD_CONTACT] boolValue]){
			AIListContact	*contact = [[adium contactController] contactWithService:service
																			 account:account
																				 UID:UID];
			if(alias) [contact setDisplayName:alias];
			
			[contactArray addObject:contact];
		}
	}

	[[adium contactController] addContacts:contactArray
								   toGroup:group];

	if([[self window] isSheet]){
		[NSApp endSheet:[self window]];
	}else{
		[self closeWindow:nil];
	}
}


//Service Type ---------------------------------------------------------------------------------------------------------
#pragma mark Service Type
/*!
 * @brief Build and configure the menu of contact service types
 */
- (void)buildContactTypeMenu
{
	NSMenuItem	*selectedItem;
	
	[popUp_contactType setMenu:[[adium accountController] menuOfServicesWithTarget:self 
																activeServicesOnly:YES
																   longDescription:NO
																			format:nil]];
	
	//- (BOOL)validateMenuItem:(NSMenuItem *)menuItem below will automatically manage the enabling/disabling 
	//when we call update.
	[[popUp_contactType menu] update];
	
	//If there is no selection or the current selection is now disabled, select the first valid service type
	if (!service ||
		!(selectedItem = (NSMenuItem *)[popUp_contactType selectedItem]) ||
		(![selectedItem isEnabled])){
		[self selectFirstValidServiceType];
	}else{
		//Otherwise, just perform needed configuration for the current selection
		[self configureForCurrentServiceType];
	}
}

/*!
 * @brief Select the first valid service type
 *
 * 'valid' in this context means that an account on the appropriate service is online.
 */
- (void)selectFirstValidServiceType
{
	NSEnumerator		*enumerator;
	
	enumerator = [[popUp_contactType itemArray] objectEnumerator];
	NSMenuItem			*menuItem;
	while(menuItem = [enumerator nextObject]) {
		if([menuItem isEnabled]) {
			[popUp_contactType selectItem:menuItem];
			break;
		}
	}
	
	[self selectServiceType:nil];
}

/*
 * Validate a menu item
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSEnumerator	*enumerator;
	AIAccount		*account;
	
	enumerator = [[[adium accountController] accountsWithServiceClassOfService:[menuItem representedObject]] objectEnumerator];
	while(account = [enumerator nextObject]){
		if([account contactListEditable]){
			return YES;
		}
	}
	return NO;
}

/*!
 * @brief Service type was selected from the menu
 */
- (void)selectServiceType:(id)sender
{	
	service = [[popUp_contactType selectedItem] representedObject];

	[self configureForCurrentServiceType];
}

/*!
 * @brief Configure for the current service type
 */
- (void)configureForCurrentServiceType
{
	[self updateContactNameLabel];
	[self updateAccountList];
	[self validateEnteredName];
}

//Add to Group ---------------------------------------------------------------------------------------------------------
#pragma mark Add to Group
/*!
 * @brief Build the menu of available destination groups
 */
- (void)buildGroupMenu
{
	AIListObject	*selectedObject;
	AIListGroup		*group;
	
	//Rebuild the menu
	[popUp_targetGroup setMenu:[[adium contactController] menuOfAllGroupsInGroup:nil withTarget:self]];

	//Select the group of the currently selected object on the contact list
	selectedObject = [[adium contactController] selectedListObject];

	if(selectedObject != nil) {
		//Find the first containing object which is an AIListGroup, starting with the selected object itself
		group = (AIListGroup*)selectedObject;
		while (group && ![group isKindOfClass:[AIListGroup class]]){
			group = (AIListGroup*)[group containingObject];
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
/*!
 * @brief Fill in the name field if we came from a tab
 */
- (void)configureNameAndService
{
	if(contactName) {
		[textField_contactName setStringValue:contactName];
	}
	
	if(service){
		NSMenuItem		*item;
		NSEnumerator	*enumerator = [[popUp_contactType itemArray] objectEnumerator];
		
		while (item = [enumerator nextObject]){
			if([item representedObject] == service){
				[popUp_contactType selectItem:item];
				break;
			}
		}
	}
	
	[self configureForCurrentServiceType];
}

/*!
 * @brief Set the contact name
 *
 * This does not perform subsequent validation.
 */
- (void)setContactName:(NSString *)contact
{
    if(contactName != contact){
	   [contactName release];
	   contactName = [contact retain];
	}
}

/*
 * Set the service
 *
 * This does not perform subsequent validation.
 */
- (void)setService:(AIService *)inService
{
    if(service != inService){
        [service release];
        service = [inService retain];
    }
}

/*!
 * @brief Entered name is changing; validate it.
 */
- (void)controlTextDidChange:(NSNotification *)notification
{
	if([notification object] == textField_contactName){
		[self validateEnteredName];
	}
}

/*!
 * @brief Validate the entered name, enabling the add button if it is valid
 */
- (void)validateEnteredName
{
	NSString	*name = [textField_contactName stringValue];
	BOOL		enabled = YES;
	
	if([name length] != 0 && [name length] <= [service allowedLengthForUIDs]){
		BOOL		caseSensitive = [service caseSensitive];
		NSScanner	*scanner = [NSScanner scannerWithString:(caseSensitive ? name : [name lowercaseString])];
		NSString	*validSegment = nil;
		
		[scanner scanCharactersFromSet:[service allowedCharactersForUIDs] intoString:&validSegment];
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
			if([account contactListEditable] &&
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
/*!
 * @brief Update the accounts list
 */
- (void)updateAccountList
{	
	NSEnumerator	*enumerator;
	AIAccount		*account;
	NSNumber		*addTo;
	
	[accounts release];
	accounts = [[[adium accountController] accountsWithServiceClassOfService:service] retain];
	
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

/*!
 * @brief The account list changed
 */
- (void)accountListChanged:(NSNotification *)notification
{
	//Attempt to retain the current contact type selection
	id representedObject = [[popUp_contactType selectedItem] representedObject];
	[self buildContactTypeMenu];
	
	int index = [popUp_contactType indexOfItemWithRepresentedObject:representedObject];
	if (index != NSNotFound){
		[popUp_contactType selectItemAtIndex:index];
	}
	
	[self updateAccountList];
}

/*!
 * @brief Update when account connectivity changes
 *
 * If the selected service is still valid, just reload the accounts table view to update it.
 * If it is no longer valid (the last account on this service just signed off), select the first valid one.
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]] && [inModifiedKeys containsObject:@"Online"]){
		if([self validateMenuItem:[popUp_contactType selectedItem]]){
			//If the current selection in the contact type menu is still valid (an account is still online), reload the accounts data
			[tableView_accounts reloadData];
		}else{
			//If it is not, switch to the first valid contact type and update accordingly
			[self selectFirstValidServiceType];
		}
	}
	
	return nil;
}

/*!
 * @brief Update the contact name label
 *
 * The label is customized for the selected service as well as localized.
 * Updating the label may resize the window to fit.
 */
- (void)updateContactNameLabel
{
	NSRect          oldFrame;
	NSRect          newFrame;
	
	oldFrame = [textField_contactNameLabel frame];

	//If the old frame is smaller than our original frame, treat the old frame as that original frame
	//for resizing and positioning purposes
	if(oldFrame.size.width < originalContactNameLabelFrame.size.width){
			oldFrame = originalContactNameLabelFrame;
	}
	
	NSString	*userNameLabel = (service ? [service userNameLabel] : nil);

	//Set to the userNameLabel, using a default value if we have no userNameLabel, then sizeToFit
	[textField_contactNameLabel setStringValue:[(userNameLabel ? userNameLabel : AILocalizedString(@"Contact ID",nil)) stringByAppendingString:@":"]];
	[textField_contactNameLabel sizeToFit];
	newFrame = [textField_contactNameLabel frame];

	//Enforce a minimum width of the original contact name label frame width
	if(newFrame.size.width < originalContactNameLabelFrame.size.width){
		newFrame.size.width = originalContactNameLabelFrame.size.width;
	}

	//Only use integral widths to keep alignment correct;
	//round up as an extra pixel of whitespace never hurt anybody
	newFrame.size.width = round(newFrame.size.width + 0.5);

	//Keep the right edge in the same place at all times
	newFrame.origin.x = oldFrame.origin.x + oldFrame.size.width - newFrame.size.width;

	[textField_contactNameLabel setFrame:newFrame];	
	[textField_contactNameLabel setNeedsDisplay:YES];

	//Resize the window to fit the contactNameLabel if the current origin is not correct; the resut
	if(newFrame.origin.x < 17){
		NSRect	windowFrame = [[self window] frame];
		float	difference = 17 - newFrame.origin.x;

		windowFrame.origin.x -= difference;
		windowFrame.size.width += difference;
		[[self window] setFrame:windowFrame display:YES animate:YES];

	}else if(oldFrame.origin.x <= 17){
		NSRect	windowFrame = [[self window] frame];
		float	difference = oldFrame.origin.x - newFrame.origin.x;
		
		if(newFrame.origin.x + difference < originalContactNameLabelFrame.origin.x){
			difference = originalContactNameLabelFrame.origin.x - newFrame.origin.x;
		}
		
		windowFrame.origin.x -= difference;
		windowFrame.size.width += difference;
		[[self window] setFrame:windowFrame display:YES animate:YES];

	}else{
		//Display to remove any artifacts from the frame changing
		[[self window] display];
	}
}

/*!
 * @brief Rows in the accounts table view
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return([accounts count]);
}

/*!
 * @brief Object value for columns in the accounts table view
 */
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

/*!
 * @brief Will display cell
 *
 * Enable/disable account checkbox as appropriate
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	[cell setEnabled:[[accounts objectAtIndex:row] contactListEditable]];
}

/*!
 * @brief Set the enabled/disabled state for an account in the account list
 */
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

/* 
 * @brief Selection is changing
 *
 * Adam: I don't want the table to display its selection.
 * Returning NO from 'shouldSelectRow' would work, but if we do that the checkbox cells stop working.
 * The best solution I've come up with so far is to just force a deselect here :( .
 */
- (void)tableViewSelectionIsChanging:(NSNotification *)notification{
	[tableView_accounts deselectAll:nil];
}

/* 
 * @brief Selection is changing
 *
 * Adam: I don't want the table to display its selection.
 * Returning NO from 'shouldSelectRow' would work, but if we do that the checkbox cells stop working.
 * The best solution I've come up with so far is to just force a deselect here :( .
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification{
	[tableView_accounts deselectAll:nil];
}

/*!
 * @brief Empty selector called by the group popUp menu
 */
- (void)selectGroup:(id)sender
{
}

@end

