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
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AINewContactWindowController.h"
#import "AINewGroupWindowController.h"
#import "OWABSearchWindowController.h"
#import "ESAddressBookIntegrationPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AILocalizationTextField.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIServiceMenu.h>
#import <AddressBook/ABPerson.h>

#define ADD_CONTACT_PROMPT_NIB	@"AddContact"
#define DEFAULT_GROUP_NAME		AILocalizedString(@"Contacts",nil)

@interface AINewContactWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName contactName:(NSString *)inName service:(AIService *)inService  account:(AIAccount *)inAccount;
- (void)buildGroupMenu;
- (void)buildContactTypeMenu;
- (void)configureForCurrentServiceType;
- (void)ensureValidContactTypeSelection;
- (void)updateAccountList;
- (void)_setServiceType:(AIService *)inService;
- (void)selectServiceType:(id)sender;

- (void)configureControlDimming;
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
 * @param inAccount If non-nil, the one AIAccount which should be initially enabled for adding this contact
 */
+ (void)promptForNewContactOnWindow:(NSWindow *)parentWindow name:(NSString *)inName service:(AIService *)inService account:(AIAccount *)inAccount
{
	AINewContactWindowController	*newContactWindow;
	
	newContactWindow = [[self alloc] initWithWindowNibName:ADD_CONTACT_PROMPT_NIB contactName:inName service:inService account:inAccount];
	
	if (parentWindow) {
		[parentWindow makeKeyAndOrderFront:nil];
		
		[NSApp beginSheet:[newContactWindow window]
		   modalForWindow:parentWindow
			modalDelegate:newContactWindow
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	} else {
		[newContactWindow showWindow:nil];
		[[newContactWindow window] makeKeyAndOrderFront:nil];
	}
	
}

/*!
 * @brief Initialize
 */
- (id)initWithWindowNibName:(NSString *)windowNibName contactName:(NSString *)inName service:(AIService *)inService account:(AIAccount *)inAccount
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
		service = [inService retain];
		initialAccount = [inAccount retain];
		contactName = [inName retain];
		person = nil;
	}
	
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
	[initialAccount release];
	[person release];
	[checkedAccounts release];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

/*!
 * @brief Setup the window before it is displayed
 */
- (void)windowDidLoad
{
	[[self window] center];

	//Localized Strings
	[[self window] setTitle:AILocalizedString(@"Add Contact",nil)];
	[textField_type setLocalizedString:AILocalizedString(@"Contact Type:","Contact type service dropdown label in Add Contact")];
	[textField_alias setLocalizedString:AILocalizedString(@"Alias:",nil)];
	[textField_inGroup setLocalizedString:AILocalizedString(@"In Group:",nil)];
	[textField_addToAccounts setLocalizedString:AILocalizedString(@"On Accounts:",nil)];
	
	[textField_searchInAB setAlwaysMoveRightAnchoredWindow:YES];
	[textField_searchInAB setLocalizedString:AILocalizedString(@"Search In Address Book",nil)];

	[button_add setLocalizedString:AILocalizedString(@"Add",nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel",nil)];

	//Configure the rest of the window
	[self buildGroupMenu];
	[self buildContactTypeMenu];
	[self configureForCurrentServiceType];
	if (contactName) [textField_contactName setStringValue:contactName];	
	
	//Observe account list and status changes
	[[adium notificationCenter] addObserver:self
								   selector:@selector(accountListChanged:)
									   name:Account_ListChanged
									 object:nil];
	[[adium contactController] registerListObjectObserver:self];
	
	[self configureControlDimming];
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
	[self closeWindow:nil];
}

/*!
 * @brief Perform the addition of the contact
 */
- (IBAction)addContact:(id)sender
{
	NSString		*UID = [service normalizeUID:[textField_contactName stringValue] removeIgnoredCharacters:YES];
	NSString		*alias = [textField_contactAlias stringValue];
	NSEnumerator	*enumerator;
	AIListGroup		*group;
	AIAccount		*account;
	NSMutableArray	*contactArray = [NSMutableArray array];
	
	//Group
	group = ([popUp_targetGroup numberOfItems] ?
			[[popUp_targetGroup selectedItem] representedObject] : 
			nil);
	
	if (!group) group = [[adium contactController] groupWithUID:DEFAULT_GROUP_NAME];
	
	AILogWithSignature(@"checkedAccounts is %@", checkedAccounts);

	//Add contact to our accounts
	enumerator = [accounts objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if ([account contactListEditable] && [checkedAccounts containsObject:account]) {
			AILogWithSignature(@"Accont %@ was checked per its preference; we'll add %@ to it", account, UID);
			AIListContact	*contact = [[adium contactController] contactWithService:service
																			 account:account
																				 UID:UID];
			
			if (contact) {
				if (alias && [alias length]) [contact setDisplayName:alias];
				[contactArray addObject:contact];
				
				//Remember the ABPerson's unique ID associated with this contact
				if (person)
					[contact setAddressBookPerson:person];

				//Force this contact to show up on the user's list for a little bit, even if it is offline
				//Otherwise they have no good feedback that a contact was added at all.
				[contact setValue:[NSNumber numberWithBool:YES] forProperty:@"New Object" notify:YES];
				[contact setValue:[NSNumber numberWithBool:NO] forProperty:@"New Object" afterDelay:10.0];
			}
		}
	}

	//Add them to our local group
	AILogWithSignature(@"Adding %@ to %@", contactArray, group);
	if ([contactArray count]) {
		[[adium contactController] addContacts:contactArray toGroup:group];
		
		[self closeWindow:nil];
	} else {
		NSBeep();
	}
}

/*!
 * @brief Display a sheet for searching a person within the AB database.
 */
- (IBAction)searchInAB:(id)sender
{
	OWABSearchWindowController *abSearchWindow;
	abSearchWindow = [[OWABSearchWindowController promptForNewPersonSearchOnWindow:[self window]
																	initialService:service] retain];
	[abSearchWindow setDelegate:self];
}

/*!
 * @brief Callback from OWABSearchWindowController
 */
- (void)absearchWindowControllerDidSelectPerson:(OWABSearchWindowController *)controller
{
	ABPerson *selectedPerson = [controller selectedPerson];
	
	if (selectedPerson) {
		NSString *selectedScreenName = [controller selectedScreenName];
		NSString *selectedName = [controller selectedName];
		AIService *selectedService = [controller selectedService];
		
		if (selectedScreenName)
			[textField_contactName setStringValue:[service normalizeUID:selectedScreenName removeIgnoredCharacters:YES]];
		
		if (selectedName)
			[textField_contactAlias setStringValue:selectedName];
		
		if (selectedService) {
			[popUp_contactType selectItemWithTitle:[selectedService shortDescription]];
			[self selectServiceType:nil];
		}
		
		[person release];
		person = [selectedPerson retain];
		
		[self configureControlDimming];
	}
	
	//Clean up
	[controller release];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == textField_contactName) {
		[self configureControlDimming];
	}
}

//Service Type ---------------------------------------------------------------------------------------------------------
#pragma mark Service Type
/*!
 * @brief Build and configure the menu of contact service types
 */
- (void)buildContactTypeMenu
{
	//Rebuild the menu
	[popUp_contactType setMenu:[AIServiceMenu menuOfServicesWithTarget:self
													activeServicesOnly:YES
													   longDescription:NO
																format:nil]];
	
	//Ensure our selection is still valid
	[self ensureValidContactTypeSelection];
}

/*!
 * @brief Ensures that the selected contact type is valid, selecting another if it isn't
 */
- (void)ensureValidContactTypeSelection
{
	int			serviceIndex = -1;
	
	//Force our menu to update.. it needs to be correctly validated for the code below to work
	[[popUp_contactType menu] update];

	//Find the menu item for our current service
	if (service) serviceIndex = [popUp_contactType indexOfItemWithRepresentedObject:service];		

	//If our service is not available we'll have to pick another one
	if (service && (serviceIndex == -1 || ![[popUp_contactType itemAtIndex:serviceIndex] isEnabled])) {
		[self _setServiceType:nil];
	}

	//If we don't have a service, pick the first available one
	if (!service) {
		[self _setServiceType:[[[popUp_contactType menu] firstEnabledMenuItem] representedObject]];
	}

	//Update our menu and window for the current service
	[popUp_contactType selectItemWithRepresentedObject:service];
	[self configureForCurrentServiceType];
}

/*!
 * @brief Configure any service-dependent controls in our window for the current service
 */
- (void)configureForCurrentServiceType
{
	NSString	*userNameLabel = [service contactUserNameLabel];
	
	//Update the service icon
	[imageView_service setImage:[AIServiceIcons serviceIconForService:service
																 type:AIServiceIconLarge
															direction:AIIconNormal]];
	[textField_contactNameLabel setLocalizedString:[(userNameLabel ? userNameLabel :
													 AILocalizedString(@"Contact ID",nil)) stringByAppendingString:AILocalizedString(@":", "Colon which will be appended after a label such as 'User Name', before an input field")]];

	//And the list of accounts
	[self updateAccountList];
}

/*!
 * @brief User selected a new service type
 */
- (void)selectServiceType:(id)sender
{	
	[self _setServiceType:[[popUp_contactType selectedItem] representedObject]];
	[self configureForCurrentServiceType];
}

/*!
 * @brief Set the current service type
 */
- (void)_setServiceType:(AIService *)inService
{
	if (inService != service) {
		[service release];
		service = [inService retain];
	}
}

/*
 * Validate a menu item
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSEnumerator	*enumerator = [[[adium accountController] accountsCompatibleWithService:[menuItem representedObject]] objectEnumerator];
	AIAccount		*account;
	
	while ((account = [enumerator nextObject])) {
		if ([account contactListEditable]) return YES;
	}
	
	return NO;
}

/*!
 * @brief Update our contact type menu when user accounts change
 */
- (void)accountListChanged:(NSNotification *)notification
{
	[self buildContactTypeMenu];
}

/*!
 * @brief Update our contact type when account availability changes
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		[self ensureValidContactTypeSelection];
	}

	return nil;
}


//Add to Group ---------------------------------------------------------------------------------------------------------
#pragma mark Add to Group
/*!
 * @brief Build the menu of available destination groups
 */
- (void)buildGroupMenu
{
	AIListObject	*selectedObject;
	NSMenu			*menu;
	//Rebuild the menu
	menu = [[adium contactController] menuOfAllGroupsInGroup:nil withTarget:self];

	//Add a default group name to the menu if there are no groups listed
	if ([menu numberOfItems] == 0) {
		[menu addItemWithTitle:DEFAULT_GROUP_NAME
						target:self
						action:@selector(selectGroup:)
				 keyEquivalent:@""];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:[AILocalizedString(@"New Group",nil) stringByAppendingEllipsis]
					target:self
					action:@selector(newGroup:)
			 keyEquivalent:@""];
	
	//Select the group of the currently selected object on the contact list
	selectedObject = [[adium interfaceController] selectedListObject];
	while (selectedObject && ![selectedObject isKindOfClass:[AIListGroup class]]) {
		selectedObject = [selectedObject containingObject];
	}

	[popUp_targetGroup setMenu:menu];

	//If there was no selected group, just select the first item
	if (selectedObject) {
		if (![popUp_targetGroup selectItemWithRepresentedObject:selectedObject]) {
			[popUp_targetGroup selectItemAtIndex:0];			
		}

	} else {
		[popUp_targetGroup selectItemAtIndex:0];
	}
}

/*!
 * @brief Prompt the user to add a new group immediately
 */
- (void)newGroup:(id)sender
{
	AINewGroupWindowController	*newGroupWindowController;
	
	newGroupWindowController = [AINewGroupWindowController promptForNewGroupOnWindow:[self window]];

	//Observe for the New Group window to close
	[[adium notificationCenter] addObserver:self
								   selector:@selector(newGroupDidEnd:) 
									   name:@"NewGroupWindowControllerDidEnd"
									 object:[newGroupWindowController window]];	
}

- (void)newGroupDidEnd:(NSNotification *)inNotification
{
	NSWindow	*window = [inNotification object];

	if ([[window windowController] isKindOfClass:[AINewGroupWindowController class]]) {
		NSString	*newGroupUID = [[window windowController] newGroupUID];
		AIListGroup *group = [[adium contactController] existingGroupWithUID:newGroupUID];

		//Rebuild the group menu
		[self buildGroupMenu];
		
		/* Select the new group if it exists; otherwise select the first group (so we don't still have New Group... selected).
		 * If the user cancelled, group will be nil since the group doesn't exist.
		 */
		if (![popUp_targetGroup selectItemWithRepresentedObject:group]) {
			[popUp_targetGroup selectItemAtIndex:0];			
		}
		
		[[self window] performSelector:@selector(makeKeyAndOrderFront:)
							withObject:self
							afterDelay:0];
	}

	//Stop observing
	[[adium notificationCenter] removeObserver:self
										  name:@"NewGroupWindowControllerDidEnd" 
										object:window];
}

//Add to Accounts ------------------------------------------------------------------------------------------------------
#pragma mark Add to Accounts
/*!
 * @brief Update the accounts list
 */
- (void)updateAccountList
{	
	[accounts release];
	accounts = [[[adium accountController] accountsCompatibleWithService:service] retain];
	
	[checkedAccounts release];
	checkedAccounts = [[NSMutableSet alloc] init];

	if (initialAccount && [accounts containsObject:initialAccount]) {
		//Select accounts by default
		[checkedAccounts addObject:initialAccount];

	} else if ([[accounts valueForKeyPath:@"@sum.online"] intValue] == 1) {
		//Only one online account; it should be checked
		NSEnumerator	*enumerator;
		AIAccount		*anAccount;
		
		enumerator = [accounts objectEnumerator];
		while ((anAccount = [enumerator nextObject])) {
			if ([anAccount online]) {
				[checkedAccounts addObject:anAccount];
				break;
			}
		}
		
	} else {
		//More than one online account; follow our 'add contact to' preferences
		NSEnumerator	*enumerator;
		AIAccount		*anAccount;

		enumerator = [accounts objectEnumerator];
		while ((anAccount = [enumerator nextObject])) {
			if ([[anAccount preferenceForKey:KEY_ADD_CONTACT_TO group:PREF_GROUP_ADD_CONTACT] boolValue])
				[checkedAccounts addObject:anAccount];
		}
	}

	[tableView_accounts reloadData];
}

- (void)configureControlDimming
{
	BOOL		shouldEnable = NO;
	
	if (([[textField_contactName stringValue] length] > 0)) {
		NSEnumerator *enumerator = [checkedAccounts objectEnumerator];
		AIAccount	 *account;
		while (!shouldEnable && (account = [enumerator nextObject]))
			if ([account contactListEditable]) shouldEnable = YES;
	}

	[button_add setEnabled:shouldEnable];
}

/*!
 * @brief Rows in the accounts table view
 */
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [accounts count];
}

/*!
 * @brief Object value for columns in the accounts table view
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString	*identifier = [tableColumn identifier];
	
	if ([identifier isEqualToString:@"check"]) {
		return ([[accounts objectAtIndex:row] contactListEditable] ?
				[NSNumber numberWithBool:[checkedAccounts containsObject:[accounts objectAtIndex:row]]] :
				[NSNumber numberWithBool:NO]);
	
	} else if ([identifier isEqualToString:@"account"]) {
		return [[accounts objectAtIndex:row] explicitFormattedUID];
		
	} else {
		return @"";

	}
}

/*!
 * @brief Will display cell
 *
 * Enable/disable account checkbox as appropriate
 */
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString	*identifier = [tableColumn identifier];
	
	if ([identifier isEqualToString:@"check"]) {
		[cell setEnabled:[[accounts objectAtIndex:row] contactListEditable]];
	}
}

/*!
 * @brief Set the enabled/disabled state for an account in the account list
 */
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString	*identifier = [tableColumn identifier];

	if ([identifier isEqualToString:@"check"]) {
		[[accounts objectAtIndex:row] setPreference:[NSNumber numberWithBool:[object boolValue]] 
											 forKey:KEY_ADD_CONTACT_TO 
											  group:PREF_GROUP_ADD_CONTACT];
		if ([object boolValue]) {
			[checkedAccounts addObject:[accounts objectAtIndex:row]];
		} else {
			[checkedAccounts removeObject:[accounts objectAtIndex:row]];			
		}
		
		[self configureControlDimming];
	}
}

/*!
 * @brief Empty selector called by the group popUp menu
 */
- (void)selectGroup:(id)sender
{

}

@end
