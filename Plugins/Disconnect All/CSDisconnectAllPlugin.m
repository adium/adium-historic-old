//
//  CSDisconnectAllPlugin.m
//  Adium
//
//  Created by Chris Serino on Tue Sep 30 2003.
//  Copyright (c) 2003-2005 The Adium Group. All rights reserved.
//

#import "CSDisconnectAllPlugin.h"

#define CONNECT_MENU_TITLE      AILocalizedString(@"Connect All","Connect all accounts")
#define DISCONNECT_MENU_TITLE   AILocalizedString(@"Disconnect All","Disconnect all accounts")
#define CANCEL_MENU_TITLE       AILocalizedString(@"Cancel All","Cancel all logins")

@implementation CSDisconnectAllPlugin

- (void)installPlugin
{
    disconnectItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:DISCONNECT_MENU_TITLE
																		   target:self
																		   action:@selector(disconnectAll:)
																	keyEquivalent:@"K"] autorelease];
    
    disconnectDockItem = [[NSMenuItem alloc] initWithTitle:DISCONNECT_MENU_TITLE
													target:self
													action:@selector(disconnectAll:)
											 keyEquivalent:@""];
    
    connectDockItem = [[NSMenuItem alloc] initWithTitle:CONNECT_MENU_TITLE
												 target:self
												 action:@selector(connectAll:)
										  keyEquivalent:@""];
	
    connectItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:CONNECT_MENU_TITLE
																		target:self
																		action:@selector(connectAll:)
																 keyEquivalent:@"k"] autorelease];
    [connectItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
	
	[[adium menuController] addMenuItem:connectDockItem toLocation:LOC_Dock_Status];
	[[adium menuController] addMenuItem:disconnectDockItem toLocation:LOC_Dock_Status];
    
    cancelConnectItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:CANCEL_MENU_TITLE
																			  target:self
																			  action:@selector(cancelAll:)
																	   keyEquivalent:@"."] autorelease];
	[[adium menuController] removeMenuItem:connectDockItem];
	[[adium menuController] removeMenuItem:disconnectDockItem];
    [cancelConnectItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
	
    [[adium menuController] addMenuItem:connectItem toLocation:LOC_File_Accounts];
    [[adium menuController] addMenuItem:disconnectItem toLocation:LOC_File_Accounts];
    [[adium menuController] addMenuItem:cancelConnectItem toLocation:LOC_File_Accounts];
	
	[[adium menuController] addMenuItem:connectDockItem toLocation:LOC_Dock_Status];
	[[adium menuController] addMenuItem:disconnectDockItem toLocation:LOC_Dock_Status];
}

-(void)uninstallPlugin
{
	//Menu Items
    [[adium menuController] removeMenuItem:disconnectItem];
    [[adium menuController] removeMenuItem:connectItem];
    [[adium menuController] removeMenuItem:cancelConnectItem];
	
	//Dock Items
	[[adium menuController] removeMenuItem:connectDockItem];
	[[adium menuController] removeMenuItem:disconnectDockItem];
}

-(void)disconnectAll:(id)sender
{
    //disconnects all the accounts
    [[adium accountController] performSelector:@selector(disconnectAllAccounts) 
									withObject:nil
									afterDelay:0.0001];
}

-(void)connectAll:(id)sender
{
    //connects all the accounts
    [[adium accountController] performSelector:@selector(connectAllAccounts) 
									withObject:nil
									afterDelay:0.0001];
}

-(void)cancelAll:(id)sender
{
    //cancels all logins
    NSEnumerator    *enumerator = [[[adium accountController] accountArray] objectEnumerator];
    AIAccount       *account;
    
    while(account = [enumerator nextObject]) {
        if([[account supportedPropertyKeys] containsObject:@"Online"] && [[account statusObjectForKey:@"Connecting"] boolValue]) {
            [account setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
            [account  disconnect];
        }
    }
            
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    NSEnumerator *accountEnumerator = [[[adium accountController] accountArray] objectEnumerator];
    AIAccount	 *account;
	
    if(menuItem == disconnectItem || menuItem == disconnectDockItem) {
        while(account = [accountEnumerator nextObject]) {
			
			//Enable it as soon as we find an account which is online
            if([[account statusObjectForKey:@"Online"] boolValue]){
				return YES;
            }
        }
    }else if(menuItem == connectItem || menuItem == connectDockItem) {
        while(account = [accountEnumerator nextObject]) {
			
			//Enable it as soon as we find an account which is offline
            if([[account supportedPropertyKeys] containsObject:@"Online"] && ![[account statusObjectForKey:@"Online"] boolValue]){
				return YES;
            }
        }
    }else if(menuItem == cancelConnectItem) {
        while(account = [accountEnumerator nextObject]) {
			
			//Enable it as soon as we find an account which is connecting
            if([[account statusObjectForKey:@"Connecting"] boolValue]){
				return YES;
            }
        }
    }
    return NO;
}

@end
