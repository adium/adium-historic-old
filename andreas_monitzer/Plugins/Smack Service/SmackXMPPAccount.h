//
//  SmackXMPPAccount.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAccount.h"

@class SmackCocoaAdapter, SmackConnectionConfiguration, SmackXMPPConnection, SmackPacket;

@interface SmackXMPPAccount : AIAccount {
    SmackCocoaAdapter *smackAdapter;
    SmackXMPPConnection *connection;
}

- (NSString*)hostName;
- (SmackConnectionConfiguration*)connectionConfiguration;

- (void)connected:(SmackXMPPConnection*)conn;
- (void)disconnected:(SmackXMPPConnection*)conn;
- (void)connectionError:(NSString*)error;
- (void)receivePacket:(SmackPacket*)packet;

@end
