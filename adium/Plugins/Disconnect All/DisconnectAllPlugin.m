//
//  DisconnectAllPlugin.m
//  Adium
//
//  Created by Chris Serino on Tue Sep 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "DisconnectAllPlugin.h"

#define DISCONNECT_MENU_TITLE @"Disconnect All"

@implementation DisconnectAllPlugin

- (void)installPlugin
{
    disconnectItem = [[NSMenuItem alloc] initWithTitle:DISCONNECT_MENU_TITLE
                                                target:self
                                                action:@selector(disconnectAll:)
                                         keyEquivalent:@"D"];

    [disconnectItem setEnabled:NO];
    [[owner menuController] addMenuItem:disconnectItem toLocation:LOC_File_Accounts];
}

-(void)uninstallPlugin
{
    [[owner menuController] removeMenuItem:disconnectItem];
}

-(void)disconnectAll:(id)sender
{
    NSEnumerator *accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    AIAccount	 *account;

    while (account = [accountEnumerator nextObject]) {
        if([[account supportedPropertyKeys] containsObject:@"Online"]){
            if([[[owner accountController] propertyForKey:@"Online" account:account] boolValue]) {
                [[owner accountController] setProperty:[NSNumber numberWithBool:NO] forKey:@"Online" account:account];
            }
        }
    }
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    NSEnumerator *accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    AIAccount	 *account;

    while (account = [accountEnumerator nextObject]) {
        if([[account supportedPropertyKeys] containsObject:@"Online"]){
            if([[[owner accountController] propertyForKey:@"Online" account:account] boolValue]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
