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
#import "AIAccountMenu.h"
#import "AIContactController.h"
#import "AIStatusController.h"
#import "AIStatusMenu.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIAccount.h>

//Menu titles
#define	ACCOUNT_CONNECT_ACTION_MENU_TITLE			AILocalizedStringFromTable(@"Connect: %@", @"AdiumFramework", "Connect account prefix")
#define	ACCOUNT_DISCONNECT_ACTION_MENU_TITLE		AILocalizedStringFromTable(@"Disconnect: %@", @"AdiumFramework", "Disconnect account prefix")
#define	ACCOUNT_CONNECTING_ACTION_MENU_TITLE		AILocalizedStringFromTable(@"Cancel: %@", @"AdiumFramework", "Cancel current account activity prefix")
#define	ACCOUNT_DISCONNECTING_ACTION_MENU_TITLE		ACCOUNT_CONNECTING_ACTION_MENU_TITLE
#define ACCOUNT_ENABLE_ACTION_MENU_TITLE			AILocalizedStringFromTable(@"Enable %@", @"AdiumFramework", "Enable account prefix")

#define ACCOUNT_CONNECT_PARENS_MENU_TITLE			AILocalizedStringFromTable(@"%@ (Connecting)", @"AdiumFramework", "Account Name (Connecting) - shown for an account while it is connecting")

#define NEW_ACCOUNT_DISPLAY_TEXT			AILocalizedStringFromTable(@"<New Account>", @"AdiumFramework", "Placeholder displayed as the name of a new account")

@interface AIAccountMenu (PRIVATE)
- (id)initWithDelegate:(id)inDelegate
		   submenuType:(AIAccountSubmenuType)inSubmenuType
		showTitleVerbs:(BOOL)inShowTitleVerbs;
- (void)_updateMenuItem:(NSMenuItem *)menuItem;
- (NSString *)_titleForAccount:(AIAccount *)account;
- (NSMenu *)actionsMenuForAccount:(AIAccount *)inAccount;
- (void)addStateMenuItems:(NSArray *)menuItemArray;
- (void)removeStateMenuItems:(NSArray *)ignoredMenuItemArray;
@end

@implementation AIAccountMenu

/*!
 * @brief Create a new account menu
 * @param inDelegate Delegate in charge of adding menu items
 * @param InShowAccountActions YES to show accont actions in a submenu
 * @param inShowTitleVerbs YES to show verbs in the menu titles
 */
+ (id)accountMenuWithDelegate:(id)inDelegate
				  submenuType:(AIAccountSubmenuType)inSubmenuType
			   showTitleVerbs:(BOOL)inShowTitleVerbs
{
	return [[[self alloc] initWithDelegate:inDelegate
							   submenuType:inSubmenuType
							showTitleVerbs:inShowTitleVerbs] autorelease];
}

/*!
 * @brief Init
 * @param inDelegate Delegate in charge of adding menu items
 * @param InShowAccountActions YES to show accont actions in a submenu
 * @param inShowTitleVerbs YES to show verbs in the menu titles
 */
- (id)initWithDelegate:(id)inDelegate
		   submenuType:(AIAccountSubmenuType)inSubmenuType
		showTitleVerbs:(BOOL)inShowTitleVerbs
{
	if ((self = [super init])) {
		submenuType = inSubmenuType;
		showTitleVerbs = inShowTitleVerbs;

		[self setDelegate:inDelegate];
		
		//Rebuild our account menu when accounts or icon sets change
		[[adium notificationCenter] addObserver:self
									   selector:@selector(rebuildMenu)
										   name:Account_ListChanged
										 object:nil];

		//Observe our accouts and prepare our state menus
		[[adium contactController] registerListObjectObserver:self];

		if (submenuType == AIAccountStatusSubmenu) {
			statusMenu = [[AIStatusMenu statusMenuWithDelegate:self] retain];
		}

		//Rebuild our menu now
		[self rebuildMenu];
	}
	
	return self;
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
	if (submenuType == AIAccountStatusSubmenu) {
		[statusMenu release]; statusMenu = nil;
	}
	
	[[adium contactController] unregisterListObjectObserver:self];
	[[adium notificationCenter] removeObserver:self];

	delegate = nil;

	[super dealloc];
}

/*!
 * @brief Returns the existing menu item for a specific account
 *
 * @param account AIAccount whose menu item to return
 * @return NSMenuItem instance for the account
 */
- (NSMenuItem *)menuItemForAccount:(AIAccount *)account
{
	return [self menuItemWithRepresentedObject:account];
}


//Delegate -------------------------------------------------------------------------------------------------------------
#pragma mark Delegate
/*!
 * @brief Set our account menu delegate
 */
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
	
	//Ensure the the delegate implements all required selectors and remember which optional selectors it supports.
	NSParameterAssert([delegate respondsToSelector:@selector(accountMenu:didRebuildMenuItems:)]);
	delegateRespondsToDidSelectAccount = [delegate respondsToSelector:@selector(accountMenu:didSelectAccount:)];
	delegateRespondsToShouldIncludeAccount = [delegate respondsToSelector:@selector(accountMenu:shouldIncludeAccount:)];
	
	includeDisabledAccountsMenu = ([delegate respondsToSelector:@selector(accountMenuShouldIncludeDisabledAccountsMenu:)] &&
								   [delegate accountMenuShouldIncludeDisabledAccountsMenu:self ]);
}
- (id)delegate
{
	return delegate;
}

/*!
 * @brief Inform our delegate when the menu is rebuilt
 */
- (void)rebuildMenu
{
	[super rebuildMenu];
	[delegate accountMenu:self didRebuildMenuItems:[self menuItems]];
}	

/*
 * @brief Inform our delegate of menu selections
 */
- (void)selectAccountMenuItem:(NSMenuItem *)menuItem
{
	if(delegateRespondsToDidSelectAccount){
		[delegate accountMenu:self didSelectAccount:[menuItem representedObject]];
	}
}


//Account Menu ---------------------------------------------------------------------------------------------------------
#pragma mark Account Menu
/*!
 * @brief Build our account menu items
 */
- (NSArray *)buildMenuItems
{
	NSMutableArray	*menuItemArray = [NSMutableArray array];
	NSArray			*accounts = [[adium accountController] accounts];
	NSEnumerator	*enumerator;
	AIAccount		*account;
	
	//Add a menuitem for each enabled account the delegate allows (or all enabled accounts if it doesn't specify)
	enumerator = [accounts objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if ([account enabled] &&
			(!delegateRespondsToShouldIncludeAccount || [delegate accountMenu:self shouldIncludeAccount:account])) {
			NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@""
																						target:self
																						action:@selector(selectAccountMenuItem:)
																				 keyEquivalent:@""
																			 representedObject:account];
			[self _updateMenuItem:menuItem];
			if (submenuType == AIAccountOptionsSubmenu) {
				[menuItem setSubmenu:[self actionsMenuForAccount:account]];
			}
			[menuItemArray addObject:menuItem];
			[menuItem release];
		}
	}
	
	if (includeDisabledAccountsMenu) {
		NSMenu			*disabledAccountMenu = [[NSMenu alloc] init];

		enumerator = [accounts objectEnumerator];
		while ((account = [enumerator nextObject])) {
			if (![account enabled] &&
				(!delegateRespondsToShouldIncludeAccount || [delegate accountMenu:self shouldIncludeAccount:account])) {
				NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@""
																							target:self
																							action:@selector(toggleAccountEnabled:)
																					 keyEquivalent:@""
																				 representedObject:account];
				[self _updateMenuItem:menuItem];
				[disabledAccountMenu addItem:menuItem];
				[menuItem release];
			}
		}

		if ([disabledAccountMenu numberOfItems]) {
			[menuItemArray addObject:[NSMenuItem separatorItem]];

			NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Disabled Accounts", nil)
																						target:self
																						action:@selector(dummyAction:)
																				 keyEquivalent:@""
																			 representedObject:nil];
			[menuItemArray addObject:menuItem];
			[menuItem setSubmenu:disabledAccountMenu];
			[menuItem release];
		}
		
		[disabledAccountMenu release];
	}

	//Update our status submenus once this method returns so that our menuItemArray is set
	if (submenuType == AIAccountStatusSubmenu) {
		[statusMenu performSelector:@selector(rebuildMenu)
						 withObject:nil
						 afterDelay:0];
	}
	
	return menuItemArray;
}

/*!
* @brief Returns a menu image for the account
 */
- (NSImage *)imageForListObject:(AIListObject *)listObject
{
	if ([listObject isKindOfClass:[AIAccount class]] &&
		![(AIAccount *)listObject enabled]) {
		return [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconSmall direction:AIIconNormal];	

	} else {
		return [super imageForListObject:listObject];
	}
}

/*!
* @brief Update a menu item to reflect its account's current status
 */
- (void)_updateMenuItem:(NSMenuItem *)menuItem
{
	AIAccount	*account = [menuItem representedObject];
	
	if (account) {
		[[menuItem menu] setMenuChangedMessagesEnabled:NO];
		[menuItem setTitle:[self _titleForAccount:account]];
		[menuItem setImage:[self imageForListObject:account]];		
		[[menuItem menu] setMenuChangedMessagesEnabled:YES];
	}
}

/*!
* @brief Returns the menu title for an account
 */
- (NSString *)_titleForAccount:(AIAccount *)account
{
	NSString	*accountTitle = [account formattedUID];
	NSString	*titleFormat = nil;
	
	//If the account doesn't have a name, give it a generic one
	if (!accountTitle || ![accountTitle length]) accountTitle = NEW_ACCOUNT_DISPLAY_TEXT;
	
	if ([account enabled]) {
		if (showTitleVerbs) {
			if ([[account statusObjectForKey:@"Connecting"] boolValue]) {
				titleFormat = ACCOUNT_CONNECTING_ACTION_MENU_TITLE;
			} else if ([[account statusObjectForKey:@"Disconnecting"] boolValue]) {
				titleFormat = ACCOUNT_DISCONNECTING_ACTION_MENU_TITLE;
			} else {
				//Display 'connect' or 'disconnect' before the account name
				titleFormat = ([account online] ? ACCOUNT_DISCONNECT_ACTION_MENU_TITLE : ACCOUNT_CONNECT_ACTION_MENU_TITLE);
			}
			
		} else {
			if ([[account statusObjectForKey:@"Connecting"] boolValue]) {
				titleFormat = ACCOUNT_CONNECT_PARENS_MENU_TITLE;
			}
		}
	} else {
		if (showTitleVerbs) {
			titleFormat = ACCOUNT_ENABLE_ACTION_MENU_TITLE;
		}
	}
		
	return (titleFormat ? [NSString stringWithFormat:titleFormat, accountTitle] : accountTitle);
}

/*!
 * @brief Update menu when an account's status changes
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		NSMenuItem	*menuItem = [[self menuItemForAccount:(AIAccount *)inObject] retain];
		BOOL		rebuilt = NO;
		
		if ([inModifiedKeys containsObject:@"Enabled"]) {
			//Rebuild the menu when the enabled state changes
			[self rebuildMenu];
			rebuilt = YES;

		} else if ([inModifiedKeys containsObject:@"Online"] ||
				   [inModifiedKeys containsObject:@"Connecting"] ||
				   [inModifiedKeys containsObject:@"Disconnecting"] ||
				   [inModifiedKeys containsObject:@"IdleSince"] ||
				   [inModifiedKeys containsObject:@"StatusState"]) {
			//Update menu items to reflect status changes

			//Update the changed menu item (or rebuild the entire menu if this item should be removed or added)
			if (delegateRespondsToShouldIncludeAccount &&
			   ([delegate accountMenu:self shouldIncludeAccount:(AIAccount *)inObject] != (menuItem == nil))) {
				[self rebuildMenu];
				rebuilt = YES;

			} else {
				[self _updateMenuItem:menuItem];
			}
		}

		if ((submenuType == AIAccountOptionsSubmenu) && [inModifiedKeys containsObject:@"Online"]) {
			if (rebuilt) menuItem = [self menuItemForAccount:(AIAccount *)inObject];

			//Append the account actions menu
			if (menuItem && [(AIAccount *)inObject enabled]) {
				[menuItem setSubmenu:[self actionsMenuForAccount:(AIAccount *)inObject]];
			}
		}
	}

    return nil;
}


//Account Action Submenu -----------------------------------------------------------------------------------------------
#pragma mark Account Action Submenu
/*!
 * @brief Returns an action menu for the passed account
 *
 * If the account is online, it is queried for account actions.
 * If it is offline, this menu has only "Edit Account" and "Disable."
 */
- (NSMenu *)actionsMenuForAccount:(AIAccount *)inAccount
{
	NSArray		*accountActionMenuItems = ([inAccount online] ? [inAccount accountActionMenuItems] : nil);
	NSMenu		*actionsSubmenu = [[[NSMenu allocWithZone:[NSMenu zone]] init] autorelease];
	NSMenuItem	*menuItem;

	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Edit Account", nil)
																	target:self
																	action:@selector(editAccount:)
															 keyEquivalent:@""
														 representedObject:inAccount];
	[actionsSubmenu addItem:menuItem];
	[menuItem release];

	[actionsSubmenu addItem:[NSMenuItem separatorItem]];

	//Only build a menu if we have items
	if (accountActionMenuItems && [accountActionMenuItems count]) {
		//Build a menu containing all the items
		NSEnumerator	*enumerator = [accountActionMenuItems objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			NSMenuItem	*newMenuItem = [menuItem copy];
			[actionsSubmenu addItem:newMenuItem];
			[newMenuItem release];
		}

		//Separate the actions from our final menu items which apply to all accounts
		[actionsSubmenu addItem:[NSMenuItem separatorItem]];
	}
	
	menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Disable", nil)
																	target:self
																	action:@selector(toggleAccountEnabled:)
															 keyEquivalent:@""
														 representedObject:inAccount];
	[actionsSubmenu addItem:menuItem];
	[menuItem release];
	
	return actionsSubmenu;
}	

/*
 * @brief Edit an account
 *
 * @param sender An NSMenuItem whose representedObject is an AIAccount
 */
- (void)editAccount:(id)sender
{
	[[adium notificationCenter] postNotificationName:@"AIEditAccount"
											  object:[sender representedObject]];
}

/*
 * @brief Disable an account
 *
 * @param sender An NSMenuItem whose representedObject is an AIAccount
 */
- (void)toggleAccountEnabled:(id)sender
{
	AIAccount	*account = [sender representedObject];
	[account setEnabled:![account enabled]];
}

//Account Status Submenu -----------------------------------------------------------------------------------------------
#pragma mark Account Status Submenu
NSMenu *statusMenuForAccountMenuItem(NSArray *menuItemArray, NSMenuItem *accountMenuItem, BOOL addOriginalItems, id self)
{
	AIAccount			*account = [accountMenuItem representedObject];
	NSMenu				*accountSubmenu = [[NSMenu allocWithZone:[NSMenu zone]] init];
	NSEnumerator		*menuItemEnumerator;
	NSMenuItem			*statusMenuItem;
	
	[accountSubmenu setMenuChangedMessagesEnabled:NO];
	
	//Enumerate all the menu items we were originally passed
	menuItemEnumerator = [menuItemArray objectEnumerator];
	while ((statusMenuItem = [menuItemEnumerator nextObject])) {
		AIStatus		*status;
		NSDictionary	*newRepresentedObject;
		
		//Set the represented object to indicate both the right status and the right account
		if ((status = [[statusMenuItem representedObject] objectForKey:@"AIStatus"])) {
			newRepresentedObject = [NSDictionary dictionaryWithObjectsAndKeys:
				status, @"AIStatus",
				account, @"AIAccount",
				nil];
		} else {
			//Custom status items don't have an associated AIStatus.
			newRepresentedObject = [NSDictionary dictionaryWithObject:account
															   forKey:@"AIAccount"];
		}
		
		if (addOriginalItems) {
			//The last time, we can use the original menu item rather than creating a copy
			[statusMenuItem setRepresentedObject:newRepresentedObject];
			[accountSubmenu addItem:statusMenuItem];
			
		} else {
			//Create a copy of the item for this account and add it to our status menu
			NSMenuItem *newItem = [statusMenuItem copy];
			[newItem setRepresentedObject:newRepresentedObject];
			[accountSubmenu addItem:newItem];
			[newItem release];				
		}
	}
	
	if ([account enabled]) {
		NSMenuItem	*disableItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Disable", nil)
																						target:self
																						action:@selector(toggleAccountEnabled:)
																				 keyEquivalent:@""
																			 representedObject:account];
		[accountSubmenu addItem:[NSMenuItem separatorItem]];
		[accountSubmenu addItem:disableItem];
		[disableItem release];
	}
	
	[accountSubmenu setMenuChangedMessagesEnabled:YES];
	
	return [accountSubmenu autorelease];
}

/*!
 * @brief Add the passed state menu items to each of our account menu items
 */
- (void)statusMenu:(AIStatusMenu *)inStatusMenu didRebuildStatusMenuItems:(NSArray *)menuItemArray
{
	NSMutableArray		*newMenuItems = [NSMutableArray array];
	NSArray				*accountMenuItems = [self menuItems];
	unsigned int		accountMenuItemsCount = [accountMenuItems count];
	unsigned int		i;
	
	//Add status items only if we have more than one account
	if (accountMenuItemsCount <= 1) return;

	for (i = 0; i < accountMenuItemsCount; i++) {
		/* Add the original items the last time; all other times, add copies of the items.
		 * An NSMenuItem can only be in one menu, so we have to make copies for all but one; without this specifier, we'd create one more copy
		 * than necessary, which is	inefficient.
		 */
		BOOL		addOriginalItems = (i == (accountMenuItemsCount - 1));
		NSMenuItem	*menuItem = [accountMenuItems objectAtIndex:i];
		NSMenu		*accountSubmenu = nil;

		if ([[menuItem representedObject] isKindOfClass:[AIAccount class]]) {
			//The menu item is for an AIAccount directly.  Get its status menu
			accountSubmenu = statusMenuForAccountMenuItem(menuItemArray, menuItem, addOriginalItems, self);
			
			if (!addOriginalItems) {
				[newMenuItems addObjectsFromArray:[accountSubmenu itemArray]];
			}
			
			//Add the status menu to our account menu item
			[menuItem setSubmenu:accountSubmenu];
			
		} else {
			//The menu item is not for an AIAccount directly. If it has a submenu of AIAccount-representing NSMenuItems, handle those.
			NSMenu			*thisItemSubmenu;

			if ((thisItemSubmenu = [menuItem submenu])) {
				unsigned int	thisItemSubmenuCount = [thisItemSubmenu numberOfItems];
				unsigned int	j;
				
				for (j = 0; j < thisItemSubmenuCount; j++) {
					menuItem = [thisItemSubmenu itemAtIndex:j];

					if ([[menuItem representedObject] isKindOfClass:[AIAccount class]]) {
						BOOL		reallyAddOriginalItems = (addOriginalItems && (j == (thisItemSubmenuCount - 1)));
						accountSubmenu = statusMenuForAccountMenuItem(menuItemArray, menuItem, reallyAddOriginalItems, self);
						
						if (!reallyAddOriginalItems) {
							[newMenuItems addObjectsFromArray:[accountSubmenu itemArray]];
						}
						
						//Add the status menu to our account menu item
						[menuItem setSubmenu:accountSubmenu];
					}
				}
			}
		}
	}
	
	/* Let the statusMenu know about the menuItems we created based on the menuItemArray
	 * we were passed. This will allow it to manage the proper checkboxes.
	 */
	 [statusMenu delegateCreatedMenuItems:newMenuItems];
}

- (void)dummyAction:(id)sender
{
}

@end
