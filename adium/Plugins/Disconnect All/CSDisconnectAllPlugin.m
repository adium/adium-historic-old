//
//  CSDisconnectAllPlugin.m
//  Adium
//
//  Created by Chris Serino on Tue Sep 30 2003.
//  Copyright (c) 2003 The Adium Group. All rights reserved.
//

#import "CSDisconnectAllPlugin.h"

#define CONNECT_MENU_TITLE      AILocalizedString(@"Connect All","Connect all accounts")
#define DISCONNECT_MENU_TITLE   AILocalizedString(@"Disconnect All","Disconnect all accounts")
#define CANCEL_MENU_TITLE       AILocalizedString(@"Cancel All","Cancel all logins")

@implementation CSDisconnectAllPlugin

- (void)installPlugin
{
    disconnectItem = [[[NSMenuItem alloc] initWithTitle:DISCONNECT_MENU_TITLE
												 target:self
												 action:@selector(disconnectAll:)
										  keyEquivalent:@"K"] autorelease];
    
    connectItem = [[[NSMenuItem alloc] initWithTitle:CONNECT_MENU_TITLE
                                              target:self
                                              action:@selector(connectAll:)
                                       keyEquivalent:@"k"] autorelease];
    [connectItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    
    
    cancelConnectItem = [[[NSMenuItem alloc] initWithTitle:CANCEL_MENU_TITLE
                                                    target:self
                                                    action:@selector(cancelAll:)
                                             keyEquivalent:@"."] autorelease];
    [cancelConnectItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
	
    [[adium menuController] addMenuItem:connectItem toLocation:LOC_File_Accounts];
    [[adium menuController] addMenuItem:disconnectItem toLocation:LOC_File_Accounts];
    [[adium menuController] addMenuItem:cancelConnectItem toLocation:LOC_File_Accounts];
}

-(void)uninstallPlugin
{
    [[adium menuController] removeMenuItem:disconnectItem];
    [[adium menuController] removeMenuItem:connectItem];
    [[adium menuController] removeMenuItem:cancelConnectItem];
}

-(void)disconnectAll:(id)sender
{
    //disconnects all the accounts
    [[adium accountController] disconnectAllAccounts];
}

-(void)connectAll:(id)sender
{
    //connects all the accounts
    [[adium accountController] connectAllAccounts];
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
	
    if(menuItem == disconnectItem) {
        while(account = [accountEnumerator nextObject]) {
			
			//Enable it as soon as we find an account which is online
            if([[account supportedPropertyKeys] containsObject:@"Online"] && [[account statusObjectForKey:@"Online"] boolValue]){
				return YES;
            }
        }
    }else if(menuItem == connectItem) {
        while(account = [accountEnumerator nextObject]) {
			
			//Enable it as soon as we find an account which is offline
            if([[account supportedPropertyKeys] containsObject:@"Online"] && ![[account statusObjectForKey:@"Online"] boolValue]){
				return YES;
            }
        }
    }else if(menuItem == cancelConnectItem) {
        while(account = [accountEnumerator nextObject]) {
        
                        //Enable it as soon as we find an account which is connecting
            if([[account supportedPropertyKeys] containsObject:@"Online"] && [[account statusObjectForKey:@"Connecting"] boolValue]){
                                return YES;
            }
        }
    }
    return NO;
}

@end
