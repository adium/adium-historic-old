//
//  SmackXMPPGatewayInteractionPlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-18.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPGatewayInteractionPlugin.h"

#import "AIAccount.h"
#import "SmackXMPPAccount.h"
#import "AIAdium.h"
#import <AIUtilities/AIStringUtilities.h>

#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"

@implementation SmackXMPPGatewayInteractionPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if((self = [super init]))
    {
        account = a;
    }
    return self;
}

- (NSArray *)menuItemsForContact:(AIListContact *)inContact
{
    if(![inContact statusObjectForKey:@"XMPPSubscriptionType"])
        return nil; // not a contact from our contact list (might be groupchat)

    NSMutableArray *menuItems = [NSMutableArray array];

    // we assume that gateways are contacts on the list that don't contain an '@' sign
    // the JEP doesn't specify it, but I can't see any other way to find them when they're
    // offline
    if([[inContact UID] rangeOfString:@"@" options:NSLiteralSearch].location == NSNotFound)
    {
        
        NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Log In","Log In (gateway)") action:@selector(logIn:) keyEquivalent:@""];
        [mitem setTarget:self];
        [mitem setRepresentedObject:inContact];
        [menuItems addObject:mitem];
        [mitem release];
        mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Log Out","Log Out (gateway)") action:@selector(logOut:) keyEquivalent:@""];
        [mitem setTarget:self];
        [mitem setRepresentedObject:inContact];
        [menuItems addObject:mitem];
        [mitem release];
    }
    
    return menuItems;
}

- (void)logIn:(NSMenuItem*)sender
{
    AIListContact *contact = [sender representedObject];
    
    SmackPresence *presence = [account getCurrentUserPresence];
    [presence setTo:[contact UID]];
    
    [[account connection] sendPacket:presence];
}

- (void)logOut:(NSMenuItem*)sender
{
    AIListContact *contact = [sender representedObject];

    SmackPresence *presence = [SmackCocoaAdapter presenceWithTypeString:@"UNAVAILABLE"];
    [presence setTo:[contact UID]];
    
    [[account connection] sendPacket:presence];
}

@end
