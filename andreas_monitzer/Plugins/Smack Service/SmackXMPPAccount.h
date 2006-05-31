//
//  SmackXMPPAccount.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAccount.h"

@class SmackCocoaAdapter, SmackConnectionConfiguration, SmackXMPPConnection, SmackMessage, SmackPresence, SmackIQ;

@interface SmackXMPPAccount : AIAccount {
    SmackCocoaAdapter *smackAdapter;
    SmackXMPPConnection *connection;
    
    NSMutableDictionary *chatdata; // stores additional data for our chats
}

- (NSString*)hostName;
- (SmackConnectionConfiguration*)connectionConfiguration;

- (void)connected:(SmackXMPPConnection*)conn;
- (void)disconnected:(SmackXMPPConnection*)conn;
- (void)connectionError:(NSString*)error;
- (void)receiveMessagePacket:(SmackMessage*)packet;
- (void)receivePresencePacket:(SmackPresence*)packet;
- (void)receiveIQPacket:(SmackIQ*)packet;

@end
