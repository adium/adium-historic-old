/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define	ACCOUNT_CONNECT_MENU_TITLE		@"Connect"			//Menu item title for the connect item
#define	ACCOUNT_DISCONNECT_MENU_TITLE		@"Disconnect"			//Menu item title
#define	ACCOUNT_CONNECTING_MENU_TITLE		@"Connecting…"			//Menu item title
#define	ACCOUNT_DISCONNECTING_MENU_TITLE	@"Disconnecting…"		//Menu item title

#define	ACCOUNT_AUTO_CONNECT_MENU_TITLE		@"Auto-Connect on Launch"	//Menu item title for the auto-connect item

@interface AIAccountMenuAccessPlugin (PRIVATE)
- (void)buildAccountMenus;
- (void)accountListChanged:(NSNotification *)notification;
- (void)updateMenuForAccount:(AIAccount *)account;
- (void)toggleAutoConnect:(id)sender;
- (IBAction)toggleConnection:(id)sender;
@end

@implementation AIAccountMenuAccessPlugin

- (void)installPlugin
{
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_PropertiesChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_StatusChanged object:nil];
    
    accountMenuArray = [[NSMutableArray alloc] init];
    [self buildAccountMenus];
}

- (void)uninstallPlugin
{
    //remove account menus
}

- (void)dealloc
{
    [accountMenuArray release];
    
    [super dealloc];
}

- (void)accountListChanged:(NSNotification *)notification
{
    //Update the account menu
    [self buildAccountMenus];
}

- (void)accountStatusChanged:(NSNotification *)notification
{
    [self updateMenuForAccount:[notification object]];
}


// Private ------------------
- (void)updateMenuForAccount:(AIAccount *)account
{
    NSEnumerator	*enumerator;
    NSMenuItem		*menuItem;
    NSMenuItem		*targetMenuItem = nil;
    NSMenuItem		*connectToggleItem;
    NSMenuItem		*autoConnectItem;

    //Find the menu
    enumerator = [accountMenuArray objectEnumerator];
    while((menuItem = [enumerator nextObject])){    
        if([menuItem representedObject] == account){
            targetMenuItem = menuItem;
            break;
        }
    }

    if(targetMenuItem){
        if([[account supportedStatusKeys] containsObject:@"Online"]){
            //Update the 'connect / disconnect' menu item
            connectToggleItem = [[targetMenuItem submenu] itemAtIndex:0];
            switch([[[owner accountController] statusObjectForKey:@"Status" account:account] intValue]){
                case STATUS_OFFLINE:
                    [targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Offline" forClass:[self class]]];
                    [connectToggleItem setTitle:ACCOUNT_CONNECT_MENU_TITLE];
                    [connectToggleItem setEnabled:YES];
                break;
                case STATUS_CONNECTING:
                    [targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Connecting" forClass:[self class]]];
                    [connectToggleItem setTitle:ACCOUNT_CONNECTING_MENU_TITLE];
                    [connectToggleItem setEnabled:NO];
                break;
                case STATUS_ONLINE:
                    [targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Online" forClass:[self class]]];
                    [connectToggleItem setTitle:ACCOUNT_DISCONNECT_MENU_TITLE];
                    [connectToggleItem setEnabled:YES];
                break;
                case STATUS_DISCONNECTING:
                    [targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Connecting" forClass:[self class]]];
                    [connectToggleItem setTitle:ACCOUNT_DISCONNECTING_MENU_TITLE];
                    [connectToggleItem setEnabled:NO];
                break;
                default:
                    [connectToggleItem setTitle:@"n/a"];
                    [connectToggleItem setEnabled:NO];
                break;
            }
            
            //Auto-connect
            autoConnectItem = [[targetMenuItem submenu] itemWithTitle:ACCOUNT_AUTO_CONNECT_MENU_TITLE];
            if([[[account properties] objectForKey:@"AutoConnect"] boolValue]){
                [autoConnectItem setState:NSOnState];
            }else{
                [autoConnectItem setState:NSOffState];
            }
        }        
    }
}

- (void)toggleAutoConnect:(id)sender
{
    AIAccount	*account;
    BOOL	autoConnect;
    
    //Get the current auto connect status
    account = [sender representedObject];
    autoConnect = [[[account properties] objectForKey:@"AutoConnect"] boolValue];

    //Switch it
    [[account properties] setObject:[NSNumber numberWithBool:!autoConnect] forKey:@"AutoConnect"];
    [[owner notificationCenter] postNotificationName:Account_PropertiesChanged object:account userInfo:nil];    
}

//Togle the connection of the selected account (called by the connect/disconnnect menu item)
//MUST be called by a menu item with an account as it's represented object!
- (IBAction)toggleConnection:(id)sender
{
    AIAccount			*targetAccount = [sender representedObject];

    //Toggle the connection
    if([[targetAccount supportedStatusKeys] containsObject:@"Online"]){
        if([[[owner accountController] statusObjectForKey:@"Online" account:targetAccount] boolValue]){
            [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"Online" account:targetAccount];
        }else{
            [[owner accountController] setStatusObject:[NSNumber numberWithBool:YES] forKey:@"Online" account:targetAccount];
        }
    }
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
        [[owner menuController] removeMenuItem:menuItem];
    }
    [accountMenuArray release];
    accountMenuArray = [[NSMutableArray alloc] init];
    
    //insert a menu for each account
    enumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        NSMenu		*subMenu;
        NSMenuItem	*menuItem;
        
        //Create the submenu
        subMenu = [[[NSMenu alloc] init] autorelease];
        [subMenu setAutoenablesItems:NO];

        //Connect/Disconnect menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:ACCOUNT_CONNECT_MENU_TITLE target:self action:@selector(toggleConnection:) keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
        [subMenu addItem:menuItem];

        //Autoconnect menu item
        [subMenu addItem:[NSMenuItem separatorItem]];
        [subMenu addItemWithTitle:ACCOUNT_AUTO_CONNECT_MENU_TITLE target:self action:@selector(toggleAutoConnect:) keyEquivalent:@"" representedObject:account];

        
        //Create the submenu's owning item
        menuItem = [[[NSMenuItem alloc] initWithTitle:[account accountDescription] target:nil action:nil keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
        [menuItem setSubmenu:subMenu];
        [accountMenuArray addObject:menuItem];
        
        //Add and update the item
        [[owner menuController] addMenuItem:menuItem toLocation:LOC_File_Accounts];
        [self updateMenuForAccount:account];
    }
}

@end
