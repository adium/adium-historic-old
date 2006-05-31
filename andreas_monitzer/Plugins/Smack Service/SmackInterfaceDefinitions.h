//
//  SmackInterfaceDefinitions.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-29.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

@interface SmackConnectionConfiguration : NSObject {
}

- (NSString*)getHost;
- (int)getPort;
- (NSString*)getServiceName;
- (NSString*)getTruststorePassword;
- (NSString*)getTruststorePath;
- (NSString*)getTruststoreType;
- (BOOL)isCompressionEnabled;
- (BOOL)isDebuggerEnabled;
- (BOOL)isExpiredCertificatesCheckEnabled;
- (BOOL)isNotMatchingDomainCheckEnabled;
- (BOOL)isSASLAuthenticationEnabled;
- (BOOL)isSelfSignedCertificateEnabled;
- (BOOL)isTLSEnabled;
- (BOOL)isVerifyChainEnabled;
- (BOOL)isVerifyRootCAEnabled;

- (void)setCompressionEnabled:(BOOL)compressionEnabled;
- (void)setDebuggerEnabled:(BOOL)debuggerEnabled;
- (void)setExpiredCertificatesCheckEnabled:(BOOL)expiredCertificatesCheckEnabled;
- (void)setNotMatchingDomainCheckEnabled:(BOOL)notMatchingDomainCheckEnabled;
- (void)setSASLAuthenticationEnabled:(BOOL)saslAuthenticationEnabled;
- (void)setSelfSignedCertificateEnabled:(BOOL)selfSignedCertificateEnabled;
- (void)setTLSEnabled:(BOOL)tlsEnabled;
- (void)setTruststorePassword:(NSString*)truststorePassword;
- (void)setTruststorePath:(NSString*)truststorePath;
- (void)setTruststoreType:(NSString*)truststoreType;
- (void)setVerifyChainEnabled:(BOOL)verifyChainEnabled;
- (void)setVerifyRootCAEnabled:(BOOL)verifyRootCAEnabled;

@end

@interface SmackMessageType : NSObject {
}

+ (SmackMessageType*)fromString:(NSString*)type;
- (NSString*)toString;

@end

@class SmackMessage;

@interface SmackChat : NSObject {
}

- (SmackMessage*)createMessage;
- (NSString*)getParticipant;
- (NSString*)getThreadID;
- (SmackMessage*)nextMessage;
- (SmackMessage*)nextMessage:(long)timeout;
- (SmackMessage*)pollMessage;
- (void)sendMessage:(SmackMessage*)message;
//- (void)sendMessage:(NSString*)message; // I wonder which one gets called there

@end

@interface JavaBoolean : NSObject {
}

- (BOOL)booleanValue;

@end

@interface JavaIterator : NSObject {
}

- (BOOL)hasNext;
- (id)next;
- (void)remove;

@end

@interface JavaCollection : NSObject {
}

- (BOOL)contains:(id)o;
- (BOOL)equals:(id)o;
- (int)hashCode;
- (BOOL)isEmpty;
- (JavaIterator*)iterator;
- (int)size;

@end

@interface JavaSet : NSObject {
}

- (BOOL)contains:(id)o;
- (BOOL)equals:(id)o;
- (int)hashCode;
- (BOOL)isEmpty;
- (JavaIterator*)iterator;
- (int)size;

@end

@interface JavaMapEntry : NSObject {
}

- (BOOL)equals:(id)o;
- (id)getKey;
- (id)getValue;
- (int)hashCode;

@end

@interface JavaMap : NSObject {
}

- (BOOL)containsKey:(id)key;
- (BOOL)containsValue:(id)value;
- (BOOL)equals:(id)o;
- (id)get:(id)object;
- (int)hashCode;
- (BOOL)isEmpty;
- (id)put:(id)key :(id)value;
- (void)putAll:(JavaMap*)t;
- (id)remove:(id)key;
- (int)size;
- (JavaSet*)entrySet;
- (JavaSet*)keySet;
- (JavaCollection*)values;

@end

@interface JavaList : NSObject {
}

- (BOOL)contains:(id)o;
- (BOOL)equals:(id)o;
- (id)get:(int)index;
- (int)indexOf:(id)o;
- (BOOL)isEmpty;
- (JavaIterator*)iterator;
- (int)lastIndexOf:(id)o;
- (int)size;

@end

@interface SmackAccountManager : NSObject {
}

- (void)changePassword:(NSString*)newPassword;
- (void)createAccount:(NSString*)username :(NSString*)password;
- (void)createAccount:(NSString*)username :(NSString*)password :(JavaMap*)attributes;
- (void)deleteAccount;
- (NSString*)getAccountAttribute:(NSString*)name;
- (JavaIterator*)getAccountAttributes;
- (NSString*)getAccountInstructions;
- (BOOL)supportsAccountCreation;

@end

@interface SmackRosterPacketItemStatus : NSObject {
}

+ (SmackRosterPacketItemStatus*)fromString:(NSString*)type;
- (NSString*)toString;

@end

@interface SmackRosterPacketItemType : NSObject {
}

+ (SmackRosterPacketItemType*)fromString:(NSString*)type;
- (NSString*)toString;

@end

@interface SmackRosterEntry : NSObject {
}

- (BOOL)equals:(id)object;
- (JavaIterator*)getGroups;
- (NSString*)getName;
- (SmackRosterPacketItemStatus*)getStatus;
- (SmackRosterPacketItemType*)getType;
- (NSString*)getUser;
- (void)setName:(NSString*)name;
- (NSString*)toString;

@end

@interface SmackRosterGroup : NSObject {
}

- (void)addEntry:(SmackRosterEntry*)entry;
- (BOOL)contains:(SmackRosterEntry*)entry;
//- (BOOL)contains:(NSString*)user;
- (JavaIterator*)getEntries;
- (SmackRosterEntry*)getEntry:(NSString*)user;
- (int)getEntryCount;
- (NSString*)getName;
- (void)removeEntry:(SmackRosterEntry*)entry;
- (void)setName:(NSString*)name;

@end

@interface SmackPresenceMode : NSObject {
}

+ (SmackPresenceMode*)fromString:(NSString*)type;
- (NSString*)toString;

@end

@interface SmackPresenceType : NSObject {
}

+ (SmackPresenceType*)fromString:(NSString*)type;
- (NSString*)toString;

@end

@class SmackXMPPError;
@protocol SmackPacketExtension;

@interface SmackPacket : NSObject {
}

- (void)addExtension:(id<SmackPacketExtension,NSObject>)extension;
- (void)deleteProperty:(NSString*)name;
- (SmackXMPPError*)getError;
- (id<SmackPacketExtension,NSObject>)getExtension:(NSString*)elementName :(NSString*)namespace;
- (JavaIterator*)getExtensions;
- (NSString*)getFrom;
- (NSString*)getPacketID;
- (id)getProperty:(NSString*)name;
- (JavaIterator*)getPropertyNames;
- (NSString*)getTo;
- (void)removeExtension:(id<SmackPacketExtension,NSObject>)extension;

- (void)setError:(SmackXMPPError*)error;
- (void)setFrom:(NSString*)from;
- (void)setPacketID:(NSString*)packetID;
- (void)setProperty:(NSString*)name :(id)value; // some collisions!
- (void)setTo:(NSString*)to;
- (NSString*)toXML;

@end

@interface SmackMessage : SmackPacket {
}

- (NSString*)getBody;
- (NSString*)getSubject;
- (NSString*)getThread;
- (SmackMessageType*)getType;
- (void)setBody:(NSString*)body;
- (void)setSubject:(NSString*)subject;
- (void)setThread:(NSString*)thread;
- (void)setType:(SmackMessageType*)type;
- (NSString*)toXML;

@end

//#define NewSmackMessage(to,type) [NSClassFromString(@"org.jivesoftware.smack.packet.Message") newWithSignature:@"(Ljava/lang/String;Lorg/jivesoftware/smack/packet/Message$Type;)",to,[NSClassFromString(@"org.jivesoftware.smack.packet.Message.Type") fromString:type]]
#define NewSmackMessage(to,type) [NSClassFromString(@"org.jivesoftware.smack.packet.Message") newWithSignature:@"(Ljava/lang/String;Lorg/jivesoftware/smack/packet/Message$Type;)",to,type]

@interface SmackPresence : SmackPacket {
}

- (SmackPresenceMode*)getMode;
- (int)getPriority;
- (NSString*)getStatus;
- (SmackPresenceType*)getType;
- (void)setMode:(SmackPresenceMode*)mode;
- (void)setPriority:(int)priority;
- (void)setStatus:(NSString*)status;
- (void)setType:(SmackPresenceType*)type;
- (NSString*)toString;
- (NSString*)toXML;

@end

@interface SmackIQType : NSObject {
}

+ (SmackIQType*)fromString:(NSString*)type;
- (NSString*)toString;

@end

@interface SmackIQ : SmackPacket {
}

- (NSString*)getChildElementXML;
- (SmackIQType*)getType;
- (void)setType:(SmackIQType*)type;
- (NSString*)toXML;

@end

@interface SmackRoster : NSObject {
}

- (BOOL)contains:(NSString*)user;
- (void)createEntry:(NSString*)user :(NSString*)name :(id)groups; // last param is String[]
- (SmackRosterGroup*)createGroup:(NSString*)name;
- (int)getDefaultSubscriptionMode;
- (JavaIterator*)getEntries;
- (SmackRosterEntry*)getEntry:(NSString*)user;
- (int)getEntryCount;
- (SmackRosterGroup*)getGroup:(NSString*)name;
- (int)getGroupCount;
- (JavaIterator*)getGroups;
- (SmackPresence*)getPresence:(NSString*)user;
- (SmackPresence*)getPresenceResource:(NSString*)userResource;
- (JavaIterator*)getPresences:(NSString*)user;
- (int)getSubscriptionMode;
- (JavaIterator*)getUnfiledEntries;
- (int)getUnfiledEntryCount;
- (void)reload;
- (void)removeEntry:(SmackRosterEntry*)entry;
+ (void)setDefaultSubscriptionMode:(int)subscriptionMode;
- (void)setSubscriptionMode:(int)subscriptionMode;

@end

@interface SmackSASLAuthentication : NSObject {
}

- (NSString*)authenticate:(NSString*)username :(NSString*)password :(NSString*)resource;
- (NSString*)authentcateAnonymously;
+ (JavaList*)getRegisterSASLMechanisms;
- (BOOL)hasAnonymousAuthentication;
- (BOOL)hasNonAnonymousAuthentication;
- (BOOL)isAuthenticated;
- (void)send:(NSString*)stanza;

@end

@protocol SmackPacketExtension

- (NSString*)getElementName;
- (NSString*)getNamespace;
- (NSString*)toXML;

@end

@interface SmackXMPPError : NSObject {
}

- (int)getCode;
- (NSString*)getMessage;
- (NSString*)toString;
- (NSString*)toXML;

@end

@interface SmackXMPPConnection : NSObject {
}

- (void)close;
- (SmackChat*)createChat:(NSString*)participant;
- (SmackAccountManager*)getAccountManager;
- (SmackRoster*)getRoster;
- (SmackSASLAuthentication*)getSASLAuthentication;
- (NSString*)getServiceName;
- (NSString*)getUser;
- (BOOL)isAnonymous;
- (BOOL)isAuthenticated;
- (BOOL)isConnected;
- (BOOL)isSecureConnection;
- (BOOL)isUsingCompression;
- (BOOL)isUsingTLS;
- (BOOL)login:(NSString*)username :(NSString*)password;
- (BOOL)login:(NSString*)username :(NSString*)password :(NSString*)resource;
- (BOOL)login:(NSString*)username :(NSString*)password :(NSString*)resource :(BOOL)sendPresence;
- (void)loginAnonymously;
- (void)sendPacket:(SmackPacket*)packet;

@end

@interface SmackConfiguration : NSObject {
}

+ (NSString*)getVersion;

@end

@protocol AdiumSmackBridgeDelegate

- (void)setConnection:(JavaBoolean*)state;
- (void)setConnectionError:(NSString*)error;
- (void)setNewMessagePacket:(SmackPacket*)packet;
- (void)setNewPresencePacket:(SmackPacket*)packet;
- (void)setNewIQPacket:(SmackPacket*)packet;

@end

@interface AdiumSmackBridge : NSObject {
}

- (void)setDelegate:(id<AdiumSmackBridgeDelegate>)delegate;
- (id<AdiumSmackBridgeDelegate>)delegate;
- (void)registerConnection:(SmackXMPPConnection*)conn;

@end

#pragma mark Extensions

@interface SmackXXHTMLExtension : NSObject <SmackPacketExtension> {
}

- (void)addBody:(NSString*)body;
- (JavaIterator*)getBodies;
- (int)getBodyCount;
- (NSString*)getElementName;
- (NSString*)getNamespace;
- (NSString*)toXML;

@end
