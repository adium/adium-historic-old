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

    [[adium menuController] addMenuItem:connectItem toLocation:LOC_File_Accounts];
    [[adium menuController] addMenuItem:disconnectItem toLocation:LOC_File_Accounts];
}

-(void)uninstallPlugin
{
    [[adium menuController] removeMenuItem:disconnectItem];
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

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    NSEnumerator *accountEnumerator = [[[adium accountController] accountArray] objectEnumerator];
    AIAccount	 *account;

    if(menuItem == disconnectItem) {
        while(account = [accountEnumerator nextObject]) {
            if([[account supportedPropertyKeys] containsObject:@"Online"]){
		return([[account statusObjectForKey:@"Online"] boolValue]);
            }
        }
        return NO;
    }else if(menuItem == connectItem) {
        while(account = [accountEnumerator nextObject]) {
            if([[account supportedPropertyKeys] containsObject:@"Online"]){
		return(![[account statusObjectForKey:@"Online"] boolValue]);
            }
        }
        return NO;
    }
    return NO;
}

@end
