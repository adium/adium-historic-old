/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIAccountMenuAccessPlugin.h"

#define	ACCOUNT_CONNECT_MENU_TITLE		AILocalizedString(@"Connect","Connect an account")	    //Menu item title for the connect item
#define	ACCOUNT_DISCONNECT_MENU_TITLE		AILocalizedString(@"Disconnect","Disconnect an account")    //Menu item title
#define	ACCOUNT_CONNECTING_MENU_TITLE		AILocalizedString(@"Connecting…",nil)		//Menu item title
#define	ACCOUNT_DISCONNECTING_MENU_TITLE	AILocalizedString(@"Disconnecting…",nil)	//Menu item title
#define	ACCOUNT_AUTO_CONNECT_MENU_TITLE		AILocalizedString(@"Auto-Connect on Launch",nil)   //Menu item title for the auto-connect item

#define ACCOUNT_TITLE   [NSString stringWithFormat:@"%@ (%@)",[account formattedUID],[account serviceID]]

@interface AIAccountMenuAccessPlugin (PRIVATE)
- (void)buildAccountMenus;
- (void)accountListChanged:(NSNotification *)notification;
- (void)updateMenuForAccount:(AIAccount *)account;
- (void)toggleAutoConnect:(id)sender;
- (IBAction)toggleConnection:(id)sender;
- (NSMenuItem *)_menuItemForAccount:(AIAccount *)account;
@end

@implementation AIAccountMenuAccessPlugin

- (void)installPlugin
{
    //Observe account changes
    [[adium notificationCenter] addObserver:self
								   selector:@selector(accountListChanged:)
									   name:Account_ListChanged
									 object:nil];
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
		
	/*
	 [[adium notificationCenter] addObserver:self 
									selector:@selector(listObjectAttributesChanged:)
										name:ListObject_AttributesChanged 
									  object:nil];
	 */
	
    [[adium contactController] registerListObjectObserver:self];
    
    accountMenuArray = [[NSMutableArray alloc] init];
    [self buildAccountMenus];
}

- (void)uninstallPlugin
{
    //remove account menus
    NSMenuItem		*menuItem;
    NSEnumerator	*enumerator = [accountMenuArray objectEnumerator];
    while((menuItem = [enumerator nextObject])){
        [[adium menuController] removeMenuItem:menuItem];
    }
    
    [accountMenuArray release];
    
    //Stop observing/receiving notifications
    [[adium contactController] unregisterListObjectObserver:self];
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//Account list changed, update our menus
- (void)accountListChanged:(NSNotification *)notification
{
    [self buildAccountMenus];
}

//Account status changed, update our menu
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    if([inObject isKindOfClass:[AIAccount class]]){
		[self updateMenuForAccount:(AIAccount *)inObject];
    }

    //We don't change any keys
    return(nil);
}

//Redisplay the modified object (Attribute change)
/*
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
	AIListObject *inObject = [notification object];
	
	if([inObject isKindOfClass:[AIAccount class]]){
		NSMenuItem		*targetMenuItem = [self _menuItemForAccount:(AIAccount *)inObject];
		if (targetMenuItem) {
			[targetMenuItem setTitle:[inObject displayName]];
		}
	}
}
*/

//
- (void)preferencesChanged:(NSNotification *)notification
{
    NSString    *group = [[notification userInfo] objectForKey:@"Group"];
    
    if([group compare:GROUP_ACCOUNT_STATUS] == 0){
		AIAccount	*account = [notification object];
		NSString    *key = [[notification userInfo] objectForKey:@"Key"];
		
		if(account && [key compare:@"AutoConnect"] == 0){
			[self updateMenuForAccount:account];
		}
    }
}


// Private ------------------

- (void)updateMenuForAccount:(AIAccount *)account
{
    NSEnumerator	*enumerator;
    NSMenuItem		*menuItem;
    NSMenuItem		*connectToggleItem;
    NSMenuItem		*autoConnectItem;
	
	NSMenuItem		*targetMenuItem = [self _menuItemForAccount:account];
	
    if(targetMenuItem){
        if([[account supportedPropertyKeys] containsObject:@"Online"]){
            //Update the 'connect / disconnect' menu item
            connectToggleItem = (NSMenuItem *)[[targetMenuItem submenu] itemAtIndex:0];
			
			if([[account statusObjectForKey:@"Online"] boolValue]){
				[targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Online" forClass:[self class]]];
				[connectToggleItem setTitle:ACCOUNT_DISCONNECT_MENU_TITLE];
				[connectToggleItem setEnabled:YES];
			}else if([[account statusObjectForKey:@"Connecting"] boolValue]){
				[targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Connecting" forClass:[self class]]];
				[connectToggleItem setTitle:ACCOUNT_CONNECTING_MENU_TITLE];
				[connectToggleItem setEnabled:NO];
			}else if([[account statusObjectForKey:@"Disconnecting"] boolValue]){
				[targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Connecting" forClass:[self class]]];
				[connectToggleItem setTitle:ACCOUNT_DISCONNECTING_MENU_TITLE];
				[connectToggleItem setEnabled:NO];
			}else{
				[targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Offline" forClass:[self class]]];
				[connectToggleItem setTitle:ACCOUNT_CONNECT_MENU_TITLE];
				[connectToggleItem setEnabled:YES];
			}
			
            //Auto-connect
            autoConnectItem = (NSMenuItem *)[[targetMenuItem submenu] itemWithTitle:ACCOUNT_AUTO_CONNECT_MENU_TITLE];
            if([[account preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue]){
                [autoConnectItem setState:NSOnState];
            }else{
                [autoConnectItem setState:NSOffState];
            }
        }        
		
		[targetMenuItem setTitle:ACCOUNT_TITLE];
    }
}

//Toggle an account's auto-connection (called by submenu)
- (void)toggleAutoConnect:(id)sender
{
    AIAccount	*account = [sender representedObject];
    BOOL	autoConnect = [[account preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue];
	
    //Switch it
    [account setPreference:[NSNumber numberWithBool:!autoConnect] forKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS];
}

//Togle the connection of the selected account (called by the connect/disconnnect menu item)
//MUST be called by a menu item with an account as its represented object!
- (IBAction)toggleConnection:(id)sender
{
    AIAccount   *targetAccount = [sender representedObject];
    BOOL    	online = [[targetAccount statusObjectForKey:@"Online"] boolValue];
	
    [targetAccount setPreference:[NSNumber numberWithBool:!online] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
}

//Create the list of account sub menus in the file menu
- (void)buildAccountMenus
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    NSMenuItem		*menuItem;
	
    //remove the existing menu items
    enumerator = [accountMenuArray objectEnumerator];
    while((menuItem = [enumerator nextObject])){    
        [[adium menuController] removeMenuItem:menuItem];
    }
    [accountMenuArray release];
    accountMenuArray = [[NSMutableArray alloc] init];
    
    //insert a menu for each account
    enumerator = [[[adium accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        NSMenu		*subMenu;
        NSMenuItem	*menuItem;
        
        //Create the submenu
        subMenu = [[[NSMenu alloc] init] autorelease];
        [subMenu setAutoenablesItems:NO];
		
        //Connect/Disconnect menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:ACCOUNT_CONNECT_MENU_TITLE
											   target:self
											   action:@selector(toggleConnection:)
										keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
        [subMenu addItem:menuItem];
		
        //Autoconnect menu item
        [subMenu addItem:[NSMenuItem separatorItem]];
        [subMenu addItemWithTitle:ACCOUNT_AUTO_CONNECT_MENU_TITLE
						   target:self
						   action:@selector(toggleAutoConnect:)
					keyEquivalent:@""
				representedObject:account];
		
        //Create the submenu's owning item - title will be set in updateMenuForAccount
        menuItem = [[[NSMenuItem alloc] initWithTitle:ACCOUNT_TITLE
											   target:nil
											   action:nil
										keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:[account retain]];
        [menuItem setSubmenu:subMenu];
        [accountMenuArray addObject:menuItem];
        
        //Add and update the item
        [[adium menuController] addMenuItem:menuItem toLocation:LOC_File_Accounts];
        [self updateMenuForAccount:account];
    }
}


- (NSMenuItem *)_menuItemForAccount:(AIAccount *)account
{
	NSEnumerator	*enumerator;
	NSMenuItem		*menuItem;
    NSMenuItem		*targetMenuItem = nil;
	
	//Find the menu
	enumerator = [accountMenuArray objectEnumerator];
	while((menuItem = [enumerator nextObject])){    
		if([menuItem representedObject] == account){
			targetMenuItem = menuItem;
			break;
		}
	}
	
	return targetMenuItem;	
}

@end
