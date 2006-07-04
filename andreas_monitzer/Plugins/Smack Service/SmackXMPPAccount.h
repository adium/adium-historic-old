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
    
    NSMutableDictionary *roster;
    
    NSArray *plugins;
}

- (AIListContact *)contactWithJID:(NSString *)inJID create:(BOOL)create;
- (AIListContact *)contactWithJID:(NSString *)inJID;
- (NSString*)hostName;
- (SmackConnectionConfiguration*)connectionConfiguration;
- (SmackXMPPConnection*)connection;

- (void)connected:(SmackXMPPConnection*)conn;
- (void)disconnected:(SmackXMPPConnection*)conn;
- (void)connectionError:(NSString*)error;
- (void)receiveMessagePacket:(SmackMessage*)packet;
- (void)receivePresencePacket:(SmackPresence*)packet;
- (void)receiveIQPacket:(SmackIQ*)packet;

- (void)setListContact:(AIListContact *)listContact toAlias:(NSString *)inAlias;
- (void)addListContact:(AIListContact *)listContact;
- (void)removeListContact:(AIListContact*)listContact;

- (BOOL)silentAndDelayed;
- (AIService*)service;

@end

/*
 * These notifications are posted when a new packet has been received from the server.
 * The userdict contains the packet with the key @"SmackXMPPPacket", the object is the SmackXMPPAccount.
 */
#define SmackXMPPMessagePacketReceivedNotification @"SmackXMPPMessagePacketReceivedNotification"
#define SmackXMPPPresencePacketReceivedNotification @"SmackXMPPPresencePacketReceivedNotification"
#define SmackXMPPIQPacketReceivedNotification @"SmackXMPPIQPacketReceivedNotification"

// this notification is sent by the account when the local user tries sending a message in a chat
#define SmackXMPPMessageSentNotification @"SmackXMPPMessageSentNotification"

#define SmackXMPPPacket @"SmackXMPPPacket"
#define AIMessageObjectKey @"AIMessageObjectKey"

@interface NSString (JIDAdditions)

- (NSString*)jidUsername;
- (NSString*)jidHost;
- (NSString*)jidResource;
- (NSString*)jidUserHost;

@end
