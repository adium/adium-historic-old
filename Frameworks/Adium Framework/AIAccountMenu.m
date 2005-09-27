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
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIAccount.h>

//Menu titles
#define	ACCOUNT_CONNECT_MENU_TITLE			AILocalizedStringFromTable(@"Connect: %@", @"AdiumFramework", "Connect account prefix")
#define	ACCOUNT_DISCONNECT_MENU_TITLE		AILocalizedStringFromTable(@"Disconnect: %@", @"AdiumFramework", "Disconnect account prefix")
#define	ACCOUNT_CONNECTING_MENU_TITLE		AILocalizedStringFromTable(@"Cancel: %@", @"AdiumFramework", "Cancel current account activity prefix")
#define	ACCOUNT_DISCONNECTING_MENU_TITLE	ACCOUNT_CONNECTING_MENU_TITLE
#define	ACCOUNT_AUTO_CONNECT_MENU_TITLE		AILocalizedStringFromTable(@"Auto-Connect on Launch", @"AdiumFramework", nil)

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
		if (submenuType == AIAccountStatusSubmenu) [[adium statusController] registerStateMenuPlugin:self];

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
	if (submenuType == AIAccountStatusSubmenu) [[adium statusController] unregisterStateMenuPlugin:self];
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
	NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount		*account;
	
	//Add a menuitem for each account the delegate allows (or all accounts if it doesn't specify)
	while ((account = [enumerator nextObject])) {
		if (!delegateRespondsToShouldIncludeAccount || [delegate accountMenu:self shouldIncludeAccount:account]) {
			NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@""
																						target:self
																						action:@selector(selectAccountMenuItem:)
																				 keyEquivalent:@""
																			 representedObject:account];
			[self _updateMenuItem:menuItem];
			[menuItemArray addObject:menuItem];
			[menuItem release];
		}
	}
	
	//Update our status submenus once this method exists
	if (submenuType == AIAccountStatusSubmenu) {
		[[adium statusController] performSelector:@selector(rebuildAllStateMenusForPlugin:)
									   withObject:self
									   afterDelay:0.0001];
	}
	
	return menuItemArray;
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
	
	//Display connecting or disconnecting status in the title
	if ([[account statusObjectForKey:@"Connecting"] boolValue]) {
		titleFormat = ACCOUNT_CONNECTING_MENU_TITLE;
	} else if ([[account statusObjectForKey:@"Disconnecting"] boolValue]) {
		titleFormat = ACCOUNT_DISCONNECTING_MENU_TITLE;
	} else if (showTitleVerbs) {
		//Display 'connect' or 'disconnect' before the account name if title verbs are enabled
		titleFormat = ([account online] ? ACCOUNT_DISCONNECT_MENU_TITLE : ACCOUNT_CONNECT_MENU_TITLE);
	}
	
	return titleFormat ? [NSString stringWithFormat:titleFormat, accountTitle] : accountTitle;
}

/*!
 * @brief Update menu when an account's status changes
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		NSMenuItem	*menuItem = [self menuItemForAccount:(AIAccount *)inObject];
		
		//Append the account actions menu for online accounts
		if (menuItem && submenuType == AIAccountOptionsSubmenu) {
			if ([inModifiedKeys containsObject:@"Online"]) {
				[menuItem setSubmenu:([inObject online] ? [self actionsMenuForAccount:(AIAccount *)inObject] : nil)];
			}
		}
		
		//Update menu items to reflect status changes
		if ([inModifiedKeys containsObject:@"Online"] ||
		   [inModifiedKeys containsObject:@"Connecting"] ||
		   [inModifiedKeys containsObject:@"Disconnecting"] ||
		   [inModifiedKeys containsObject:@"IdleSince"] ||
		   [inModifiedKeys containsObject:@"StatusState"]) {
			
			//Update the changed menu item (or rebuild the entire menu if this item should be removed or added)
			if (delegateRespondsToShouldIncludeAccount &&
			   ([delegate accountMenu:self shouldIncludeAccount:(AIAccount *)inObject] != (menuItem == nil))) {
				[self rebuildMenu];
			} else {
				[self _updateMenuItem:menuItem];
			}
		}
	}
	
    return nil;
}


//Account Action Submenu -----------------------------------------------------------------------------------------------
#pragma mark Account Action Submenu
/*!
 * @brief Returns an action menu for the passed account
 */
- (NSMenu *)actionsMenuForAccount:(AIAccount *)inAccount
{
	NSArray	*accountActionMenuItems = [inAccount accountActionMenuItems];
	NSMenu	*actionsSubmenu = nil;
	
	//Only build a menu if we have items
	if (accountActionMenuItems && [accountActionMenuItems count]) {
		actionsSubmenu = [[[NSMenu allocWithZone:[NSMenu zone]] init] autorelease];
		
		//Build a menu containing all the items
		NSEnumerator	*enumerator = [accountActionMenuItems objectEnumerator];
		NSMenuItem		*menuItem;
		while ((menuItem = [enumerator nextObject])) {
			[actionsSubmenu addItem:[menuItem copy]];
		}
	}
	
	return actionsSubmenu;
}	


//Account Status Submenu -----------------------------------------------------------------------------------------------
#pragma mark Account Status Submenu
/*!
 * @brief Add the passed state menu items to each of our account menu items
 */
- (void)addStateMenuItems:(NSArray *)menuItemArray
{
	NSEnumerator		*enumerator;
	NSMenuItem			*accountMenuItem;

	//We'll need to add these menu items items to each of our accounts
	enumerator = [[self menuItems] objectEnumerator];
	while ((accountMenuItem = [enumerator nextObject])) {    		
		AIAccount	*account = [accountMenuItem representedObject];
		NSMenu		*accountSubmenu = [[[NSMenu allocWithZone:[NSMenu zone]] init] autorelease];
		
		//Add status items if we have more than one account
		NSEnumerator	*menuItemEnumerator = [menuItemArray objectEnumerator];
		NSMenuItem		*statusMenuItem;
		
		[accountSubmenu setMenuChangedMessagesEnabled:NO];
		
		//Enumerate all the menu items we were originally passed
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
				newRepresentedObject = [NSDictionary dictionaryWithObject:account
																   forKey:@"AIAccount"];
			}
			
			//Create a copy of the item for this account and add it to our status menu
			NSMenuItem *newItem = [statusMenuItem copy];
			[newItem setRepresentedObject:newRepresentedObject];
			[accountSubmenu addItem:newItem];
			[newItem release];
		}
		
		[accountSubmenu setMenuChangedMessagesEnabled:YES];
		
		//Add the status menu to our account menu item
		[accountMenuItem setSubmenu:accountSubmenu];		
	}
}

/*!
 * @brief Remove the state menu items from each of our account menu items
 */
- (void)removeStateMenuItems:(NSArray *)ignoredMenuItemArray
{
	NSEnumerator	*enumerator = [[self menuItems] objectEnumerator];
	NSMenuItem		*menuItem;

	//We'll need to add these menu items items to each of our accounts
	while ((menuItem = [enumerator nextObject])) {    		
		[menuItem setSubmenu:nil];
	}
}

@end
