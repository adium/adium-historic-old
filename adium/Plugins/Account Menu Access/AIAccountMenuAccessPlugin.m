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
@end

@implementation AIAccountMenuAccessPlugin

- (void)installPlugin
{
    [[[owner accountController] accountNotificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_ListChanged object:nil];
    [[[owner accountController] accountNotificationCenter] addObserver:self selector:@selector(accountListChanged:) name:Account_PropertiesChanged object:nil];
    [[[owner accountController] accountNotificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_StatusChanged object:nil];
    
    accountMenuArray = [[NSMutableArray alloc] init];
    [self buildAccountMenus];
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
    NSMenuItem		*connectTogleItem;
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
        if([account conformsToProtocol:@protocol(AIAccount_Status)]){
            //Update the 'connect / disconnect' menu item
            connectTogleItem = [[targetMenuItem submenu] itemAtIndex:0];
            switch([(AIAccount<AIAccount_Status> *)account status]){
                case STATUS_OFFLINE:
                    [targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Offline" forClass:[self class]]];
                    [connectTogleItem setTitle:ACCOUNT_CONNECT_MENU_TITLE];
                    [connectTogleItem setEnabled:YES];
                    [connectTogleItem setTarget:account];
                    [connectTogleItem setAction:@selector(connect)];
                break;
                case STATUS_CONNECTING:
                    [targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Connecting" forClass:[self class]]];
                    [connectTogleItem setTitle:ACCOUNT_CONNECTING_MENU_TITLE];
                    [connectTogleItem setEnabled:NO];
                break;
                case STATUS_ONLINE:
                    [targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Online" forClass:[self class]]];
                    [connectTogleItem setTitle:ACCOUNT_DISCONNECT_MENU_TITLE];
                    [connectTogleItem setEnabled:YES];
                    [connectTogleItem setTarget:account];
                    [connectTogleItem setAction:@selector(disconnect)];
                break;
                case STATUS_DISCONNECTING:
                    [targetMenuItem setImage:[AIImageUtilities imageNamed:@"Account_Connecting" forClass:[self class]]];
                    [connectTogleItem setTitle:ACCOUNT_DISCONNECTING_MENU_TITLE];
                    [connectTogleItem setEnabled:NO];
                break;
                default:
                    [connectTogleItem setTitle:@"n/a"];
                    [connectTogleItem setEnabled:NO];
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
    [[[owner accountController] accountNotificationCenter] postNotificationName:Account_PropertiesChanged object:account userInfo:nil];    
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
        [subMenu addItemWithTitle:ACCOUNT_CONNECT_MENU_TITLE target:nil action:nil keyEquivalent:@""];
        [subMenu addItem:[NSMenuItem separatorItem]];
        [subMenu addItemWithTitle:ACCOUNT_AUTO_CONNECT_MENU_TITLE target:self action:@selector(toggleAutoConnect:) keyEquivalent:@"" representedObject:account];
        
        //Create the item
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
