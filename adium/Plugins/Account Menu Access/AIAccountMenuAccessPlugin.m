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

#import "AIAccountMenuAccessPlugin.h"

#define	ACCOUNT_CONNECT_MENU_TITLE			AILocalizedString(@"Connect:","Connect account prefix")
#define	ACCOUNT_DISCONNECT_MENU_TITLE		AILocalizedString(@"Disconnect:","Disconnect account prefix")
#define	ACCOUNT_CONNECTING_MENU_TITLE		AILocalizedString(@"Cancel Connect:","Connecting an account prefix")
#define	ACCOUNT_DISCONNECTING_MENU_TITLE	AILocalizedString(@"Disconnecting","Disconnecting an account prefix")
#define	ACCOUNT_AUTO_CONNECT_MENU_TITLE		AILocalizedString(@"Auto-Connect on Launch",nil)

#define ACCOUNT_TITLE   [NSString stringWithFormat:@"%@ (%@)",([[account formattedUID] length] ? [account formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT),[account displayServiceID]]
#define TARGET_ACCOUNT_TITLE   [NSString stringWithFormat:@"%@ (%@)",([[targetAccount formattedUID] length] ? [targetAccount formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT),[targetAccount serviceID]]

@interface AIAccountMenuAccessPlugin (PRIVATE)
- (void)buildAccountMenus;
- (void)accountListChanged:(NSNotification *)notification;
- (void)updateMenuForAccount:(AIAccount *)account;
- (void)setAutoConnect:(AIAccount *)account connected:(BOOL)autoConnect;
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
    [[adium contactController] registerListObjectObserver:self];
    
    accountMenuArray = [[NSMutableArray alloc] init];
	
	image_Online = [[NSImage imageNamed:@"Account_Online" forClass:[self class]] retain];
	image_Connecting = [[NSImage imageNamed:@"Account_Connecting" forClass:[self class]] retain];
	image_Offline = [[NSImage imageNamed:@"Account_Offline" forClass:[self class]] retain];
	
	
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
    
	[image_Online release]; image_Online = nil;
	[image_Connecting release]; image_Connecting = nil;
	[image_Offline release]; image_Offline = nil;
	
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

//
- (void)preferencesChanged:(NSNotification *)notification
{
    NSString    *group = [[notification userInfo] objectForKey:@"Group"];
    
    if([group isEqualToString:GROUP_ACCOUNT_STATUS]){
		AIAccount	*account = [notification object];
		NSString    *key = [[notification userInfo] objectForKey:@"Key"];
		
		if(account && [key isEqualToString:@"AutoConnect"]){
			[self updateMenuForAccount:account];
		}
    }
}

// Private ------------------
- (void)updateMenuForAccount:(AIAccount *)account
{
	NSMenuItem		*targetMenuItem = [self _menuItemForAccount:account];
	
    if(targetMenuItem){
        if([[account supportedPropertyKeys] containsObject:@"Online"]){
            //Update the 'connect / disconnect' menu item

			[[targetMenuItem menu] setMenuChangedMessagesEnabled:NO];		

			if([[account statusObjectForKey:@"Online"] boolValue]){
				[targetMenuItem setImage:image_Online];
				[targetMenuItem setTitle:[ACCOUNT_DISCONNECT_MENU_TITLE stringByAppendingFormat:@" %@",ACCOUNT_TITLE]];
                                [targetMenuItem setKeyEquivalent:@""];
				[targetMenuItem setEnabled:YES];
			}else if([[account statusObjectForKey:@"Connecting"] boolValue]){
				[targetMenuItem setImage:image_Connecting];
				[targetMenuItem setTitle:[ACCOUNT_CONNECTING_MENU_TITLE stringByAppendingFormat:@" %@",ACCOUNT_TITLE]];
                                [targetMenuItem setKeyEquivalent:@"."];
				[targetMenuItem setEnabled:YES];
			}else if([[account statusObjectForKey:@"Disconnecting"] boolValue]){
				[targetMenuItem setImage:image_Connecting];
				[targetMenuItem setTitle:[ACCOUNT_DISCONNECTING_MENU_TITLE stringByAppendingFormat:@" %@",ACCOUNT_TITLE]];
                                [targetMenuItem setKeyEquivalent:@""];
				[targetMenuItem setEnabled:NO];
			}else{
				[targetMenuItem setImage:image_Offline];
				[targetMenuItem setTitle:[ACCOUNT_CONNECT_MENU_TITLE stringByAppendingFormat:@" %@",ACCOUNT_TITLE]];
                                [targetMenuItem setKeyEquivalent:@""];
				[targetMenuItem setEnabled:YES];
			}

			[[targetMenuItem menu] setMenuChangedMessagesEnabled:YES];
        }        
		
    }
}

//Set an account's auto-connection
- (void)setAutoConnect:(AIAccount *)account connected:(BOOL)autoConnect
{
    [account setPreference:[NSNumber numberWithBool:autoConnect] forKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS];
}

//Togle the connection of the selected account (called by the connect/disconnnect menu item)
//MUST be called by a menu item with an account as its represented object!
- (IBAction)toggleConnection:(id)sender
{
    AIAccount   *targetAccount = [sender representedObject];
    BOOL    	online = [[targetAccount statusObjectForKey:@"Online"] boolValue];
	
    if([[sender title] isEqualToString:[ACCOUNT_CONNECTING_MENU_TITLE stringByAppendingFormat:@" %@",TARGET_ACCOUNT_TITLE]]){
        //let the user disconnect from the menu item.
        [targetAccount setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
    }else{
        [targetAccount setPreference:[NSNumber numberWithBool:!online] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
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
        [[adium menuController] removeMenuItem:menuItem];
    }
    [accountMenuArray release];
    accountMenuArray = [[NSMutableArray alloc] init];
    
    //insert a menu for each account
    enumerator = [[[adium accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){

		//Create the account's menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:ACCOUNT_TITLE
											   target:self
											   action:@selector(toggleConnection:)
										keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:[account retain]];
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

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	return(YES);
}


@end
