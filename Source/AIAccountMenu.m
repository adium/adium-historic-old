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
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListObject.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>

//Menu titles
#define	ACCOUNT_CONNECT_MENU_TITLE			AILocalizedString(@"Connect: %@","Connect account prefix")
#define	ACCOUNT_DISCONNECT_MENU_TITLE		AILocalizedString(@"Disconnect: %@","Disconnect account prefix")
#define	ACCOUNT_CONNECTING_MENU_TITLE		AILocalizedString(@"Cancel: %@","Cancel current account activity prefix")
#define	ACCOUNT_DISCONNECTING_MENU_TITLE	ACCOUNT_CONNECTING_MENU_TITLE
#define	ACCOUNT_AUTO_CONNECT_MENU_TITLE		AILocalizedString(@"Auto-Connect on Launch",nil)

@interface AIAccountMenu (PRIVATE)
- (id)initWithDelegate:(id)inDelegate
	showAccountActions:(BOOL)inShowAccountActions
		showTitleVerbs:(BOOL)inShowTitleVerbs;
- (void)_createAccountMenuItems;
- (void)_destroyAccountMenuItems;
@end

@implementation AIAccountMenu

/*!
 * @brief Create a new account menu
 * @param inDelegate Delegate in charge of adding menu items
 * @param InShowAccountActions YES to show accont actions in a submenu
 * @param inShowTitleVerbs YES to show verbs in the menu titles
 */
+ (id)accountMenuWithDelegate:(id)inDelegate
		   showAccountActions:(BOOL)inShowAccountActions
			   showTitleVerbs:(BOOL)inShowTitleVerbs
{
	return([[[self alloc] initWithDelegate:inDelegate
						showAccountActions:inShowAccountActions
							showTitleVerbs:inShowTitleVerbs] autorelease]);
}

/*!
 * @brief Init
 * @param inDelegate Delegate in charge of adding menu items
 * @param InShowAccountActions YES to show accont actions in a submenu
 * @param inShowTitleVerbs YES to show verbs in the menu titles
 */
- (id)initWithDelegate:(id)inDelegate
	showAccountActions:(BOOL)inShowAccountActions
		showTitleVerbs:(BOOL)inShowTitleVerbs
{
	if((self = [super init])){
		delegate = inDelegate;
		showAccountActions = inShowAccountActions;
		showTitleVerbs = inShowTitleVerbs;
		
		[self rebuildAccountMenu];
		
		//Rebuild our account menu when accounts or icon sets change
		[[adium notificationCenter] addObserver:self
									   selector:@selector(rebuildAccountMenu)
										   name:Account_ListChanged
										 object:nil];
		
		[[adium notificationCenter] addObserver:self
									   selector:@selector(rebuildAccountMenu)
										   name:AIStatusIconSetDidChangeNotification
										 object:nil];

		[[adium notificationCenter] addObserver:self
									   selector:@selector(rebuildAccountMenu)
										   name:AIServiceIconSetDidChangeNotification
										 object:nil];

		//Observe our accouts and prepare our state menus
		[[adium contactController] registerListObjectObserver:self];
		if(!inShowAccountActions) [[adium statusController] registerStateMenuPlugin:self];
	}
	
	return(self);
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
	if(!showAccountActions) [[adium statusController] unregisterStateMenuPlugin:self];
	[self _destroyAccountMenuItems];
	
	[super dealloc];
}

/*!
 * @brief Update menu when an account's status changes
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if([inObject isKindOfClass:[AIAccount class]]){
		NSMenuItem	*menuItem = [self menuItemForAccount:(AIAccount *)inObject];

		//Append the account actions menu for online accounts
		if([inModifiedKeys containsObject:@"Online"]){
			if(showAccountActions){
				[menuItem setSubmenu:([inObject online] ? [self actionsMenuForAccount:(AIAccount *)inObject] : nil)];
			}
		}

		//Update menu items to reflect status changes
		if([inModifiedKeys containsObject:@"Online"] ||
		   [inModifiedKeys containsObject:@"Connecting"] ||
		   [inModifiedKeys containsObject:@"Disconnecting"] ||
		   [inModifiedKeys containsObject:@"IdleSince"] ||
		   [inModifiedKeys containsObject:@"StatusState"]){
	
			[self updateMenuItem:menuItem];
		}
	}
	
    return(nil);
}


//Actions --------------------------------------------------------------------------------------------------------------
#pragma mark Actions
/*!
 * @brief Toggle an account's status
 */
- (IBAction)toggleConnection:(id)sender
{
    AIAccount   *account = [sender representedObject];
    BOOL    	online = [[account statusObjectForKey:@"Online"] boolValue];
	BOOL		connecting = [[account statusObjectForKey:@"Connecting"] boolValue];
	
	//If online or connecting set the account offline, otherwise set it to online
	[account setPreference:[NSNumber numberWithBool:!(online || connecting)] 
					forKey:@"Online"
					 group:GROUP_ACCOUNT_STATUS];
}


//Building -------------------------------------------------------------------------------------------------------------
#pragma mark Building
/*!
 * @brief Completely rebuild the menu
 */
- (void)rebuildAccountMenu
{
	[self _destroyAccountMenuItems];
	[self _createAccountMenuItems];
}

/*!
 * @brief Find an existing menu item for an account
 */
- (NSMenuItem *)menuItemForAccount:(AIAccount *)account
{
	NSEnumerator	*enumerator = [menuItems objectEnumerator];
	NSMenuItem		*menuItem;
	
	while((menuItem = [enumerator nextObject])){    
		if([menuItem representedObject] == account) return(menuItem);
	}

	return(nil);
}

/*!
 * @brief Update a menu item to reflect its account's current status
 */
- (void)updateMenuItem:(NSMenuItem *)menuItem
{
	AIAccount	*account = [menuItem representedObject];
	
	if(account){
		[[menuItem menu] setMenuChangedMessagesEnabled:NO];
		[menuItem setTitle:[self titleForAccount:account]];
		[menuItem setImage:[self imageForAccount:account]];		
		[[menuItem menu] setMenuChangedMessagesEnabled:YES];
	}
}

/*!
 * @brief Returns a menu image for the account
 */
- (NSImage *)imageForAccount:(AIAccount *)account
{
	NSImage	*statusIcon, *serviceIcon;
	NSSize	statusSize, serviceSize, compositeSize;
	NSRect	compositeRect;
	
	//Get the service and status icons
	statusIcon = [AIStatusIcons statusIconForListObject:account type:AIStatusIconList direction:AIIconNormal];
	statusSize = [statusIcon size];
	serviceIcon = [AIServiceIcons serviceIconForObject:account type:AIServiceIconSmall direction:AIIconNormal];	
	serviceSize = [serviceIcon size];
	
	//Composite them side by side (since we're only allowed one image in a menu and we want to see both)
	compositeSize = NSMakeSize(statusSize.width + serviceSize.width + 1,
							   statusSize.height > serviceSize.height ? statusSize.height : serviceSize.height);
	compositeRect = NSMakeRect(0, 0, compositeSize.width, compositeSize.height);
	
	//Render the image
	NSImage	*composite = [[NSImage alloc] initWithSize:compositeSize];
	[composite lockFocus];
	[statusIcon drawInRect:compositeRect atSize:[statusIcon size] position:IMAGE_POSITION_LEFT fraction:1.0];
	[serviceIcon drawInRect:compositeRect atSize:[serviceIcon size] position:IMAGE_POSITION_RIGHT fraction:1.0];
	[composite unlockFocus];
	
	return([composite autorelease]);
}

/*!
 * @brief Returns the menu title for an account
 */
- (NSString *)titleForAccount:(AIAccount *)account
{
	NSString	*accountTitle = [account formattedUID];
	NSString	*titleFormat = nil;

	//If the account doesn't have a name, give it a generic one
	if(!accountTitle || ![accountTitle length]) accountTitle = NEW_ACCOUNT_DISPLAY_TEXT;

	//Display connecting or disconnecting status in the title
	if([[account statusObjectForKey:@"Connecting"] boolValue]){
		titleFormat = ACCOUNT_CONNECTING_MENU_TITLE;
	}else if([[account statusObjectForKey:@"Disconnecting"] boolValue]){
		titleFormat = ACCOUNT_DISCONNECTING_MENU_TITLE;
	}else if(showTitleVerbs){
		//Display 'connect' or 'disconnect' before the account name if title verbs are enabled
		titleFormat = ([account online] ? ACCOUNT_DISCONNECT_MENU_TITLE : ACCOUNT_CONNECT_MENU_TITLE);
	}
	
	return(titleFormat ? [NSString stringWithFormat:titleFormat, accountTitle] : accountTitle);
}

/*!
 * @brief Create the account menu items
 */
- (void)_createAccountMenuItems
{
	menuItems = [[NSMutableArray alloc] init];
	
    //Create a menuitem for each account
	NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
    AIAccount		*account;

    while((account = [enumerator nextObject])){
		NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@""
																					target:self
																					action:@selector(toggleConnection:)
																			 keyEquivalent:@""
																		 representedObject:account];
		[menuItems addObject:menuItem];
		[menuItem release];
		
		[self updateMenuItem:menuItem];
    }
	
	//Inform our delgate of the new items
	[delegate addAccountMenuItems:menuItems];
}

/*!
 * @brief Destroy the account menu items
 */
- (void)_destroyAccountMenuItems
{
	if([menuItems count]){
		[delegate removeAccountMenuItems:menuItems];
		[menuItems release]; menuItems = nil;
	}
}


//Account Actions ------------------------------------------------------------------------------------------------------
#pragma mark Account Actions
/*!
 * @brief Returns an action menu for the passed account
 */
- (NSMenu *)actionsMenuForAccount:(AIAccount *)inAccount
{
	NSArray	*accountActionMenuItems = [inAccount accountActionMenuItems];
	NSMenu	*actionsSubmenu = nil;
	
	//Only build a menu if we have items
	if(accountActionMenuItems && [accountActionMenuItems count]){
		actionsSubmenu = [[[NSMenu allocWithZone:[NSMenu zone]] init] autorelease];
		
		//Build a menu containing all the items
		NSEnumerator	*enumerator = [accountActionMenuItems objectEnumerator];
		NSMenuItem		*menuItem;
		while((menuItem = [enumerator nextObject])){
			[actionsSubmenu addItem:[menuItem copy]];
		}
	}
	
	return actionsSubmenu;
}	


//Account Status -------------------------------------------------------------------------------------------------------
#pragma mark Account Status
/*!
 * @brief Add the passed state menu items to each of our account menu items
 */
- (void)addStateMenuItems:(NSArray *)menuItemArray
{
	NSEnumerator		*enumerator;
	NSMenuItem			*accountMenuItem;

	if([menuItems count] > 1){
		//We'll need to add these menu items items to each of our accounts
		enumerator = [menuItems objectEnumerator];
		while((accountMenuItem = [enumerator nextObject])){    		
			AIAccount	*account = [accountMenuItem representedObject];
			NSMenu		*accountSubmenu = [[[NSMenu allocWithZone:[NSMenu zone]] init] autorelease];
			
			//Add status items if we have more than one account
			NSEnumerator	*menuItemEnumerator = [menuItemArray objectEnumerator];
			NSMenuItem		*statusMenuItem;
			
			[accountSubmenu setMenuChangedMessagesEnabled:NO];
			
			//Enumerate all the menu items we were originally passed
			while((statusMenuItem = [menuItemEnumerator nextObject])){
				AIStatus		*status;
				NSDictionary	*newRepresentedObject;
				
				//Set the represented object to indicate both the right status and the right account
				if((status = [[statusMenuItem representedObject] objectForKey:@"AIStatus"])){
					newRepresentedObject = [NSDictionary dictionaryWithObjectsAndKeys:
						status, @"AIStatus",
						account, @"AIAccount",
						nil];
				}else{
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
}

/*!
 * @brief Remove the state menu items from each of our account menu items
 */
- (void)removeStateMenuItems:(NSArray *)ignoredMenuItemArray
{
	NSEnumerator	*enumerator = [menuItems objectEnumerator];
	NSMenuItem		*menuItem;

	//We'll need to add these menu items items to each of our accounts
	while((menuItem = [enumerator nextObject])){    		
		[menuItem setSubmenu:nil];
	}
}

@end
