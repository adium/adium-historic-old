//
//  CSDisconnectAllPlugin.m
//  Adium
//
//  Created by Chris Serino on Tue Sep 30 2003.
//  Copyright (c) 2003 The Adium Group. All rights reserved.
//

#import "CSDisconnectAllPlugin.h"

#define CONNECT_MENU_TITLE @"Connect All"
#define DISCONNECT_MENU_TITLE @"Disconnect All"

@implementation CSDisconnectAllPlugin

- (void)installPlugin
{
    disconnectItem = [[[NSMenuItem alloc] initWithTitle:DISCONNECT_MENU_TITLE
                                                target:self
                                                action:@selector(disconnectAll:)
                                         keyEquivalent:@"k"] autorelease];
    [disconnectItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    
    connectItem = [[[NSMenuItem alloc] initWithTitle:CONNECT_MENU_TITLE
                                              target:self
                                              action:@selector(connectAll:)
                                       keyEquivalent:@"K"] autorelease];

    [[owner menuController] addMenuItem:connectItem toLocation:LOC_File_Accounts];
    [[owner menuController] addMenuItem:disconnectItem toLocation:LOC_File_Accounts];
}

-(void)uninstallPlugin
{
    [[owner menuController] removeMenuItem:disconnectItem];
}

-(void)disconnectAll:(id)sender
{
    //disconnects all the accounts
    [[owner accountController] disconnectAllAccounts];
}

-(void)connectAll:(id)sender
{
    //connects all the accounts
    [[owner accountController] connectAllAccounts];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    NSEnumerator *accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    AIAccount	 *account;

    if (menuItem == disconnectItem) {
        while (account = [accountEnumerator nextObject]) {
            if([[account supportedPropertyKeys] containsObject:@"Online"]){
                if([[[owner accountController] propertyForKey:@"Online" account:account] boolValue]) {
                    return YES;
                }
            }
        }
        return NO;
    } else if (menuItem == connectItem) {
        while (account = [accountEnumerator nextObject]) {
            if([[account supportedPropertyKeys] containsObject:@"Online"]){
                if(![[[owner accountController] propertyForKey:@"Online" account:account] boolValue]) {
                    return YES;
                }
            }
        }
        return NO;
    }
    return NO;
}

@end
