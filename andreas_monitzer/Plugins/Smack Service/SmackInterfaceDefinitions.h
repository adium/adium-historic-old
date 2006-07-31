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

- (SmackMessageType*)fromString:(NSString*)type;
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

@interface JavaVector : NSObject {
}

- (BOOL)add:(id)o;
- (void)add:(int)index :(id)element;
- (void)addElement:(id)obj;
- (void)clear;
- (id)clone;
- (BOOL)contains:(id)elem;
- (id)elementAt:(int)index;
- (id)get:(int)index;
- (void)removeElementAt:(int)index;
- (id)set:(int)index :(id)element;
- (int)size;
- (id)toArray; // returns Object[]
- (NSString*)toString;

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

- (void)clear;
- (BOOL)containsKey:(id)key;
- (BOOL)containsValue:(id)value;
- (JavaSet*)entrySet;
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

@interface JavaDate : NSObject {
}

// Returns the number of milliseconds since January 1, 1970, 00:00:00 GMT represented by this Date object.
- (long)getTime;

@end

@interface JavaFile : NSObject {
}

- (NSString*)getPath;
- (NSString*)getName;
- (NSString*)getAbsoluteFile;
- (NSString*)getAbsolutePath;

@end

@interface JavaClass : NSObject {
}

- (BOOL)equals:(id)obj;

@end

@interface JavaMethod : NSObject {
}

- (NSString*)getName;
- (id)invoke:(id)obj :(id)args; // second is String[]
- (NSString*)toString;
- (JavaClass*)getReturnType;

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

- (SmackRosterPacketItemStatus*)fromString:(NSString*)type;
- (NSString*)toString;

@end

@interface SmackRosterPacketItemType : NSObject {
}

- (SmackRosterPacketItemType*)fromString:(NSString*)type;
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

@interface SmackRosterPacketItem : NSObject {
}

- (void)addGroupName:(NSString*)groupName;
- (JavaIterator*)getGroupNames;
- (SmackRosterPacketItemStatus*)getItemsStatus;
- (SmackRosterPacketItemType*)getItemType;
- (NSString*)getName;
- (NSString*)getUser;
- (void)removeGroupName:(NSString*)groupName;
- (void)setItemType:(SmackRosterPacketItemType*)itemType;
- (void)setName:(NSString*)name;
- (NSString*)toXML;

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

- (SmackPresenceMode*)fromString:(NSString*)type;
- (NSString*)toString;

@end

@interface SmackPresenceType : NSObject {
}

- (SmackPresenceType*)fromString:(NSString*)type;
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

- (SmackIQType*)fromString:(NSString*)type;
- (NSString*)toString;

@end

@interface SmackIQ : SmackPacket {
}

- (NSString*)getChildElementXML;
- (SmackIQType*)getType;
- (void)setType:(SmackIQType*)type;
- (NSString*)toXML;

@end

@interface SmackRegister : SmackIQ {
}

- (JavaMap*)getAttributes;
- (NSString*)getChildElementXML;
- (NSString*)getInstructions;
- (void)setAttributes:(JavaMap*)atttributes;
- (void)setInstructions:(NSString*)instructions;

@end

@interface SmackRosterPacket : SmackIQ {
}

- (void)addRosterItem:(SmackRosterPacketItem*)item;
- (NSString*)getChildElementXML;
- (int)getRosterItemCount;
- (JavaIterator*)getRosterItems;

@end

@interface SmackRoster : NSObject {
}

- (void)addRosterListener:(id)rosterListener;
- (void)removeRosterListener:(id)rosterListener;
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
- (void)setDefaultSubscriptionMode:(int)subscriptionMode;
- (void)setSubscriptionMode:(int)subscriptionMode;

@end

@interface SmackRegistration : SmackIQ {
}

- (JavaMap*)getAttributes;
- (NSString*)getChildElementXML;
- (NSString*)getInstructions;
- (void)setAttributes:(JavaMap*)attributes;
- (void)setInstructions:(NSString*)instructions;

@end

@interface SmackSASLAuthentication : NSObject {
}

- (NSString*)authenticate:(NSString*)username :(NSString*)password :(NSString*)resource;
- (NSString*)authentcateAnonymously;
- (JavaList*)getRegisterSASLMechanisms;
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

@interface SmackXDelayInformation : NSObject <SmackPacketExtension> {
}

- (JavaDate*)getStamp;
- (NSString*)getFrom;
- (NSString*)getReason;

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
- (SmackRoster*)initializeRoster;
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

@interface SmackXOccupant : NSObject {
}

- (NSString*)getAffiliation;
- (NSString*)getJid;
- (NSString*)getNick;
- (NSString*)getRole;

@end

@interface SmackXFormFieldOption : NSObject {
}

- (NSString*)getLabel;
- (NSString*)getValue;
- (NSString*)toString;
- (NSString*)toXML;

@end

@interface SmackXFormField : NSObject {
}

- (NSString*)getDescription;
- (NSString*)getLabel;
- (JavaIterator*)getOptions;
- (NSString*)getType;
- (JavaIterator*)getValues;
- (NSString*)getVariable;
- (BOOL)isRequired;

- (void)resetValues;
- (void)addValue:(NSString*)value;

- (void)setLabel:(NSString*)label;
- (void)setType:(NSString*)type;

- (NSString*)toXML;

@end

@interface SmackXDataFormItem : NSObject {
}

- (JavaIterator*)getFields;
- (NSString*)toXML;

@end

@interface SmackXDataFormReportedData : NSObject {
}

- (JavaIterator*)getFields;
- (NSString*)toXML;

@end

@interface SmackXDataForm : NSObject <SmackPacketExtension> {
}

- (void)addField:(SmackXFormField*)field;
- (void)addInstruction:(NSString*)instruction;
- (void)addItem:(SmackXDataFormItem*)item;
- (NSString*)getElementName;
- (JavaIterator*)getFields;
- (JavaIterator*)getInstructions;
- (JavaIterator*)getIterms;
- (NSString*)getNamespace;
- (SmackXDataFormReportedData*)getReportedData;
- (NSString*)getTitle;
- (NSString*)getType;
- (void)setInstructions:(JavaList*)instructions;
- (void)setReportedData:(SmackXDataFormReportedData*)reportedData;
- (void)setTitle:(NSString*)title;
- (NSString*)toXML;

@end

@interface SmackXForm : NSObject {
}

- (SmackXFormField*)getField:(NSString*)variable;
- (JavaIterator*)getFields;
- (NSString*)getInstructions;
- (NSString*)getTitle;
- (NSString*)getType;
- (void)setAnswer:(NSString*)variable :(NSNumber*)value;
- (SmackXDataForm*)getDataFormToSend;
- (SmackXForm*)createAnswerForm;
- (void)addField:(SmackXFormField*)field;
- (void)setInstructions:(NSString*)instructions;
- (void)setTitle:(NSString*)title;

@end

@interface SmackXDiscoverItem : NSObject {
}

- (NSString*)getAction;
- (NSString*)getEntityID;
- (NSString*)getName;
- (NSString*)getNode;
- (void)setAction:(NSString*)action;
- (void)setName:(NSString*)name;
- (void)setNode:(NSString*)node;
- (NSString*)toXML;

@end

@interface SmackXDiscoverItems : SmackIQ {
}

- (void)addItem:(SmackXDiscoverItem*)item;
- (NSString*)getChildElementXML;
- (JavaIterator*)getItems;
- (NSString*)getNode;
- (void)setNode:(NSString*)node;

@end

@interface SmackXDiscoverInfoIdentity : NSObject {
}

- (NSString*)getCategory;
- (NSString*)getName;
- (NSString*)getType;
- (void)setType:(NSString*)type;
- (NSString*)toXML;

@end

@interface SmackXDiscoverInfo : SmackIQ {
}

- (void)addFeature:(NSString*)feature;
- (void)addIdentity:(SmackXDiscoverInfoIdentity*)identity;
- (BOOL)containsFeature:(NSString*)feature;
- (JavaIterator*)getIdentities;
- (NSString*)getNode;
- (void)setNode:(NSString*)node;

@end

@interface SmackXDiscussionHistory : NSObject {
}

- (int)getMaxChars;
- (int)getMaxStanzas;
- (int)getSeconds;
- (JavaDate*)getSince;
- (void)setMaxChars:(int)maxChars;
- (void)setMaxStanzas:(int)maxStanzas;
- (void)setSeconds:(int)seconds;
- (void)setSince:(JavaDate*)since;

@end

@interface SmackXMultiUserChat : NSObject {
}

- (void)banUser:(NSString*)jid :(NSString*)reason;
- (void)banUsers:(JavaCollection*)jids;

- (void)changeAvailabilityStatus:(NSString*)status :(SmackPresenceMode*)mode;
- (void)changeNickname:(NSString*)nickname;
- (void)changeSubject:(NSString*)subject;

- (void)create:(NSString*)nickname;
- (SmackMessage*)createMessage;
- (SmackChat*)createPrivateChat:(NSString*)occupant;

- (void)destroy:(NSString*)reason :(NSString*)alternateJID;

- (JavaCollection*)getAdmins;
- (JavaCollection*)getMembers;
- (JavaCollection*)getModerators;
- (NSString*)getNickname;
- (SmackXOccupant*)getOccupant:(NSString*)user;
- (SmackPresence*)getOccupantPresence:(NSString*)user;
- (JavaIterator*)getOccupants;
- (int)getOccupantsCount;
- (JavaCollection*)getOutcasts;
- (JavaCollection*)getOwners;
- (JavaCollection*)getParticipants;
- (NSString*)getReservedNickname;
- (NSString*)getRoom;
- (NSString*)getSubject;

- (void)grantAdmin:(NSString*)jid;
- (void)revokeAdmin:(NSString*)jid;

- (void)grantMembership:(NSString*)jid;
- (void)revokeMembership:(NSString*)jid;

- (void)grantOwnership:(NSString*)jid;
- (void)revokeOwnership:(NSString*)jid;

- (void)grantModerator:(NSString*)nickname;
- (void)revokeModerator:(NSString*)nickname;

- (void)grantVoice:(NSString*)nickname;
- (void)revokeVoice:(NSString*)nickname;

- (void)kickParticipant:(NSString*)nickname :(NSString*)reason;

- (void)invite:(SmackMessage*)message :(NSString*)user :(NSString*)reason;
- (void)invite:(NSString*)user :(NSString*)reason;

- (BOOL)isJoined;
- (void)join:(NSString*)nickname;
- (void)join:(NSString*)nickname :(NSString*)password;
- (void)join:(NSString*)nickname :(NSString*)password :(SmackXDiscussionHistory*)history :(long)timeout;
- (void)leave;

- (SmackMessage*)nextMessage;
- (SmackMessage*)nextMessage:(long)timeout;
- (SmackMessage*)pollMessage;
- (void)sendMessage:(SmackMessage*)message;

- (SmackXForm*)getConfigurationForm;
- (void)sendConfigurationForm:(SmackXForm*)form;

- (SmackXForm*)getRegistrationForm;
- (void)sendRegistrationForm:(SmackXForm*)form;

@end

@interface SmackXFileTransferStatus : NSObject {
}

- (NSString*)toString;

@end

@interface SmackXFileTransferError : NSObject {
}

- (NSString*)getMessage;
- (NSString*)toString;

@end

@interface SmackXFileTransfer: NSObject {
}

- (void)cancel;
- (long)getAmountWritten;
- (SmackXFileTransferError*)getError;
//- (JavaException*)getException;
- (NSString*)getFileName;
- (NSString*)getFilePath;
- (long)getFileSize;
- (NSString*)getPeer;
- (double)getProgress;
- (SmackXFileTransferStatus*)getStatus;
- (BOOL)isDone;

@end

@interface SmackXOutgoingFileTransfer : SmackXFileTransfer {
}

- (long)getBytesSent;
- (void)sendFile:(JavaFile*)file :(NSString*)description;
- (void)sendFile:(NSString*)filename :(long)fileSize :(NSString*)description;

@end

@interface SmackXIncomingFileTransfer : SmackXFileTransfer {
}

- (void)receiveFile:(JavaFile*)file;

@end

@interface SmackXFileTransferRequest : NSObject {
}

- (SmackXIncomingFileTransfer*)accept;
- (NSString*)getDescription;
- (NSString*)getFileName;
- (long)getFileSize;
- (NSString*)getMimeType;
- (NSString*)getRequestor;
- (NSString*)getStreamID;
- (void)reject;

@end

@interface SmackXServiceDiscoveryManager : NSObject {
}

- (void)addFeature:(NSString*)feature;
- (BOOL)canPublishItems:(NSString*)entityID;
- (SmackXDiscoverInfo*)discoverInfo:(NSString*)entityID;
- (SmackXDiscoverInfo*)discoverInfo:(NSString*)entityID :(NSString*)node;
- (SmackXDiscoverItems*)discoverItems:(NSString*)entityID;
- (SmackXDiscoverItems*)discoverItems:(NSString*)entityID :(NSString*)node;
- (JavaIterator*)getFeatures;
+ (NSString*)getIdentityName;
+ (NSString*)getIdentityType;
+ (SmackXServiceDiscoveryManager*)getInstanceFor:(SmackXMPPConnection*)connection;
- (BOOL)includesFeature:(NSString*)feature;
- (void)publishItems:(NSString*)entityID :(SmackXDiscoverItems*)discoverItems;
- (void)publishItems:(NSString*)entityID :(NSString*)node :(SmackXDiscoverItems*)discoverItems;
- (void)removeFeature:(NSString*)feature;
- (void)removeNodeInformationProvider:(NSString*)node;
+ (void)setIdentityName:(NSString*)name;
+ (void)setIdentityType:(NSString*)type;

@end

@interface SmackXVCard : SmackIQ {
}

- (BOOL)equals:(id)o;
- (NSString*)getAddressFieldHome:(NSString*)addrField;
- (NSString*)getAddressFieldWork:(NSString*)addrField;
- (id)getAvatar; // byte[]
- (NSString*)getAvatarHash;
- (NSString*)getChildElementXML;
- (NSString*)getEmailHome;
- (NSString*)getEmailWork;
- (NSString*)getField:(NSString*)field;
- (NSString*)getFirstName;
- (NSString*)getJabberId;
- (NSString*)getLastName;
- (NSString*)getMiddleName;
- (NSString*)getNickName;
- (NSString*)getOrganization;
- (NSString*)getOrganizationUnit;
- (NSString*)getPhoneHome:(NSString*)phoneType;
- (NSString*)getPhoneWork:(NSString*)phoneType;
- (void)load:(SmackXMPPConnection*)connection;
- (void)load:(SmackXMPPConnection*)connection :(NSString*)user;
- (void)save:(SmackXMPPConnection*)connection;
- (void)setAddressFieldHome:(NSString*)addrField :(NSString*)value;
- (void)setAddressFieldWork:(NSString*)addrField :(NSString*)value;
- (void)setAvatar:(id)bytes; // byte[]
- (void)setEmailHome:(NSString*)email;
- (void)setEmailWork:(NSString*)emailWork;
- (void)setEncodedImage:(NSString*)encodedAvatar;
- (void)setField:(NSString*)field :(NSString*)value;
- (void)setField:(NSString*)field :(NSString*)value :(BOOL)isUnescapable;
- (void)setFirstName:(NSString*)firstName;
- (void)setJabberId:(NSString*)jabberId;
- (void)setLastName:(NSString*)lastName;
- (void)setMiddleName:(NSString*)middleName;
- (void)setNickName:(NSString*)nickName;
- (void)setOrganization:(NSString*)organization;
- (void)setOrganizationUnit:(NSString*)organizationUnit;
- (void)setPhoneHome:(NSString*)phoneType :(NSString*)phoneNum;
- (void)setPhoneWork:(NSString*)phoneType :(NSString*)phoneNum;
- (NSString*)toString;

@end

@interface SmackXMPPException : NSObject {
}

- (SmackXMPPError*)getXMPPError;

@end

@interface SmackConfiguration : NSObject {
}

+ (NSString*)getVersion;

@end

@interface SmackDNSUtilHostAddress : NSObject {
}

- (NSString*)getHost;
- (int)getPort;
- (NSString*)toString;
- (BOOL)equals:(id)o;

@end

@interface SmackDNSUtil : NSObject {
}

- (SmackDNSUtilHostAddress*)resolveXMPPDomain:(NSString*)domain;
- (SmackDNSUtilHostAddress*)resolveXMPPServerDomain:(NSString*)domain;

@end

@interface SmackOutOfBandExtension : NSObject <SmackPacketExtension> {
}

- (void)setUrl:(NSString*)url;
- (NSString*)getUrl;
- (void)setDesc:(NSString*)desc;
- (NSString*)getDesc;

@end

@interface SmackVCardUpdateExtension : NSObject <SmackPacketExtension> {
}

- (void)setPhoto:(NSString*)photo;
- (NSString*)getPhoto;
- (NSString*)toXML;

@end

@interface SmackChatStateNotifications : NSObject <SmackPacketExtension> {
}

+ (SmackChatStateNotifications*)getChatState:(SmackMessage*)message;
+ (SmackChatStateNotifications*)createChatState:(NSString*)type;

@end

#define SmackResolveXMPPDomain(domain) [NSClassFromString(@"org.jivesoftware.smack.util.DNSUtil") resolveXMPPDomain:domain]

@protocol AdiumSmackBridgeDelegate

- (void)setConnection:(SmackXMPPConnection*)conn;
- (void)setDisconnection:(JavaBoolean*)blah;
- (void)setConnectionError:(NSString*)error;
- (void)setNewMessagePacket:(SmackPacket*)packet;
- (void)setNewPresencePacket:(SmackPacket*)packet;
- (void)setNewIQPacket:(SmackPacket*)packet;

@end

@interface AdiumSmackBridge : NSObject {
}

- (void)initSubscriptionMode;
- (void)setDelegate:(id<AdiumSmackBridgeDelegate>)delegate;
- (id<AdiumSmackBridgeDelegate>)delegate;

- (void)createConnection:(BOOL)useSSL :(SmackConnectionConfiguration*)conf;
- (SmackXServiceDiscoveryManager*)getServiceDiscoveryManager;

- (BOOL)isInstanceOfClass:(id)object :(NSString*)classname;
- (JavaMethod*)getMethod:(NSString*)classname :(NSString*)methodname :(JavaVector*)parameterTypes;

+ (void)createRosterEntry:(SmackRoster*)roster :(NSString*)jid :(NSString*)name :(NSString*)group;
+ (BOOL)isInstanceOfClass:(id)obj :(NSString*)classname;
+ (id)getStaticFieldFromClass:(NSString*)fieldname :(NSString*)classname;
+ (JavaMethod*)getMethod:(NSString*)classname :(NSString*)method :(JavaVector*)argumentTypes;
+ (id)invokeMethod:(JavaMethod*)meth :(id)obj :(JavaVector*)params;

+ (void)setVCardAvatar:(SmackXVCard*)vCard :(NSData*)avatar;

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
