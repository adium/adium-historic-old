//
//  SmackCocoaAdapter.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackXMPPAccount.h"
#import "ESDebugAILog.h"

#import <JavaVM/NSJavaVirtualMachine.h>

extern CFRunLoopRef CFRunLoopGetMain(void);
/* java.lang.Object */
@interface NSObject (JavaObjectAdditions)
+ (id)getProperty:(NSString *)property;
- (NSString *)toString;
@end

@implementation SmackCocoaAdapter

#pragma mark utility functions

+ (id)staticObjectField:(NSString*)fieldname inJavaClass:(NSString*)className {
    return [NSClassFromString(@"net.adium.smackBridge.SmackBridge") getStaticFieldFromClass:fieldname :className];
}

+ (BOOL)object:(id)obj isInstanceOfJavaClass:(NSString*)className {
    return [NSClassFromString(@"net.adium.smackBridge.SmackBridge") isInstanceOfClass:obj :className];
}

#pragma mark Main Adapter

- (id)initForAccount:(SmackXMPPAccount *)inAccount {
    if((self=[super init])) {
        account = inAccount;
        [NSThread detachNewThreadSelector:@selector(runConnection:) toTarget:self withObject:inAccount];
    }
    return self;
}

- (void)runConnection:(SmackXMPPAccount*)inAccount {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    SmackConnectionConfiguration *conf = [inAccount connectionConfiguration];
    if(conf) {
        BOOL useSSL = [[inAccount preferenceForKey:@"useSSL" group:GROUP_ACCOUNT_STATUS] boolValue];
        AdiumSmackBridge *bridge = [[NSClassFromString(@"net.adium.smackBridge.SmackBridge") alloc] init];
        [bridge initSubscriptionMode];
        [bridge setDelegate:self];
        
        connection = [NSClassFromString(useSSL?@"org.jivesoftware.smack.SSLXMPPConnection":@"org.jivesoftware.smack.XMPPConnection") newWithSignature:@"(Lorg/jivesoftware/smack/ConnectionConfiguration;)",conf];
        
        [bridge registerConnection:connection];
        [bridge release];
    }
    [pool release];
}

- (SmackXMPPConnection*)connection {
    return connection;
}

- (void)dealloc {
    [connection close];
    [connection release];
    [super dealloc];
}

- (void)setConnection:(JavaBoolean*)state {
    if([state booleanValue]) {
        AILog(@"XMPP Connection established");
        [account performSelectorOnMainThread:@selector(connected:) withObject:connection waitUntilDone:NO];
    } else {
        AILog(@"XMPP Connection closed.");
        [account performSelectorOnMainThread:@selector(disconnected:) withObject:connection waitUntilDone:NO];
    }
}

- (void)setConnectionError:(NSString*)error {
    AILog(@"XMPP Connection Error: %@",error);
    [account performSelectorOnMainThread:@selector(connectionError:) withObject:error waitUntilDone:NO];
}

- (void)setNewMessagePacket:(SmackPacket*)packet {
    [account performSelectorOnMainThread:@selector(receiveMessagePacket:) withObject:packet waitUntilDone:NO];
}
- (void)setNewPresencePacket:(SmackPacket*)packet {
    [account performSelectorOnMainThread:@selector(receivePresencePacket:) withObject:packet waitUntilDone:NO];
}
- (void)setNewIQPacket:(SmackPacket*)packet {
    [account performSelectorOnMainThread:@selector(receiveIQPacket:) withObject:packet waitUntilDone:NO];
}

#pragma mark Bridged Object Creation

+ (SmackConnectionConfiguration*)connectionConfigurationWithHost:(NSString*)host port:(int)port service:(NSString*)service {
    return [[NSClassFromString(@"org.jivesoftware.smack.ConnectionConfiguration") newWithSignature:@"(Ljava/lang/String;ILjava/lang/String;)",host,port,service] autorelease];
}

+ (SmackPresence*)presenceWithType:(SmackPresenceType*)type {
    return [[NSClassFromString(@"org.jivesoftware.smack.packet.Presence") newWithSignature:@"(Lorg/jivesoftware/smack/packet/Presence$Type;)",type] autorelease];
}

+ (SmackPresence*)presenceWithTypeString:(NSString*)type {
    return [self presenceWithType:[SmackCocoaAdapter staticObjectField:type inJavaClass:@"org.jivesoftware.smack.packet.Presence$Type"]];
}

+ (SmackPresence*)presenceWithType:(SmackPresenceType*)type status:(NSString*)status priority:(int)priority mode:(SmackPresenceMode*)mode {
    return [[NSClassFromString(@"org.jivesoftware.smack.packet.Presence") newWithSignature:@"(Lorg/jivesoftware/smack/packet/Presence$Type;Ljava/lang/String;ILorg/jivesoftware/smack/packet/Presence$Mode;)",type,status,priority,mode] autorelease];
}

+ (SmackPresence*)presenceWithTypeString:(NSString*)type status:(NSString*)status priority:(int)priority modeString:(NSString*)mode {
    return [self presenceWithType:[SmackCocoaAdapter staticObjectField:type inJavaClass:@"org.jivesoftware.smack.packet.Presence$Type"] status:status priority:priority mode:[SmackCocoaAdapter staticObjectField:mode inJavaClass:@"org.jivesoftware.smack.packet.Presence$Mode"]];
}

+ (SmackMessage*)messageTo:(NSString*)to type:(SmackMessageType*)type {
    return [[NSClassFromString(@"org.jivesoftware.smack.packet.Message") newWithSignature:@"(Ljava/lang/String;Lorg/jivesoftware/smack/packet/Message$Type;)",to,type] autorelease];
}

+ (SmackMessage*)messageTo:(NSString*)to typeString:(NSString*)type {
    return [self messageTo:to type:[SmackCocoaAdapter staticObjectField:type inJavaClass:@"org.jivesoftware.smack.packet.Message$Type"]];
}

+ (SmackXXHTMLExtension*)XHTMLExtension {
    return [[[NSClassFromString(@"org.jivesoftware.smackx.packet.XHTMLExtension") alloc] init] autorelease];
}

+ (SmackIQ*)IQ {
    return [[[NSClassFromString(@"org.jivesoftware.smack.packet.IQ") alloc] init] autorelease];
}

+ (SmackIQType*)IQType:(NSString*)type {
    return [self staticObjectField:type inJavaClass:@"org.jivesoftware.smack.packet.IQ$Type"];
}

+ (SmackXMPPError*)XMPPErrorWithCode:(int)code {
    return [[NSClassFromString(@"org.jivesoftware.smack.packet.XMPPError") newWithSignature:@"(I)",code] autorelease];
}

+ (SmackXMPPError*)XMPPErrorWithCode:(int)code message:(NSString*)message {
    return [[NSClassFromString(@"org.jivesoftware.smack.packet.XMPPError") newWithSignature:@"(ILjava/lang/String;)",code,message] autorelease];
}

@end
