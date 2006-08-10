//
//  SmackJinglePlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-10.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackJinglePlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIStringUtilities.h>
#import <JavaVM/NSJavaVirtualMachine.h>
#import "SmackXMPPAccount.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackCocoaAdapter.h"


@interface SmackJingleListener : NSObject {
}

- (SmackXJingleManager*)getManager;

@end

@interface SmackCocoaAdapter (jinglePlugin)

+ (SmackJingleListener*)createJingleListenerForConnection:(SmackXMPPConnection*)conn delegate:(id)delegate;

@end

@implementation SmackCocoaAdapter (jinglePlugin)

+ (SmackJingleListener*)createJingleListenerForConnection:(SmackXMPPConnection*)conn delegate:(id)delegate
{
    return [[(id)[[self classLoader] loadClass:@"net.adium.smackBridge.JingleListener"] getInstance:conn :delegate] autorelease];
}

@end

@implementation SmackJinglePlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if((self = [super init]))
    {
        account = a;
    }
    return self;
}

- (void)dealloc
{
    [listener release];
    [super dealloc];
}

- (void)connected:(SmackXMPPConnection*)connection
{
    listener = [[SmackCocoaAdapter createJingleListenerForConnection:[account connection] delegate:self] retain];
}

- (void)disconnected:(SmackXMPPConnection*)connection
{
    [listener release];
    listener = nil;
}

- (void)setJingleSessionRequest:(SmackXJingleSessionRequest*)request
{
    NSLog(@"jingle session request!");
    
    // automatically reject for now
    [request reject];
}

- (void)establishOutgoingJingleSessionTo:(NSString*)jid
{
    // just an example
    JavaVector *payloadTypes = [SmackCocoaAdapter vector];
    
    // [payloadTypes add:bla];
    
    SmackXOutgoingJingleSession *session = [[listener getManager] createOutgoingJingleSession:jid :payloadTypes];
    
    [session close];
}

// add a menu item to the contact's context menu, so an outgoing session can be established
- (NSArray *)menuItemsForContact:(AIListContact *)inContact {
    SmackXDiscoverInfo *info = [inContact statusObjectForKey:@"XMPP:disco#info"];
    if(!info)
        return nil; // no info available, so we don't know if this account supports Jingle (we assume no)
    
    if(![info containsFeature:@"http://jabber.org/protocol/jingle"])
        return nil; // jingle not supported
    
    NSMutableArray *menuItems = [NSMutableArray array];
    
    NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Invite to Audio Chat","Invite to Audio Chat (Jingle)")
                                                   action:@selector(inviteToAudioChat:) keyEquivalent:@""];
    [mitem setTarget:self];
    [mitem setRepresentedObject:inContact];
    [menuItems addObject:mitem];
    [mitem release];
    
    return menuItems;
}

- (void)inviteToAudioChat:(NSMenuItem*)sender
{
    AIListContact *contact = [sender representedObject];

    // meta contact magic, will hopefully be fixed before 1.1 is released
    while([contact conformsToProtocol:@protocol(AIContainingObject)])
        contact = [contact preferredContact];
    if(!contact)
        return; // not online?

    [self establishOutgoingJingleSessionTo:[contact UID]];
}

@end
