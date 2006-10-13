//
//  SmackInterfaceDefinitions.h
//  Adium
//
//  Created by Andreas Monitzer on 2006-05-29.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import <Adium/AIJavaControllerProtocol.h>

@interface SmackConnectionConfiguration : JavaObject {
}

- (NSString *)getHost;
- (int)getPort;
- (NSString *)getServiceName;
- (NSString *)getTruststorePassword;
- (NSString *)getTruststorePath;
- (NSString *)getTruststoreType;
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
- (void)setTruststorePassword:(NSString *)truststorePassword;
- (void)setTruststorePath:(NSString *)truststorePath;
- (void)setTruststoreType:(NSString *)truststoreType;
- (void)setVerifyChainEnabled:(BOOL)verifyChainEnabled;
- (void)setVerifyRootCAEnabled:(BOOL)verifyRootCAEnabled;

@end

@interface SmackMessageType : JavaObject {
}

- (SmackMessageType *)fromString:(NSString *)type;
- (NSString *)toString;

@end

@class SmackMessage;

@interface SmackChat : JavaObject {
}

- (SmackMessage *)createMessage;
- (NSString *)getParticipant;
- (NSString *)getThreadID;
- (SmackMessage *)nextMessage;
- (SmackMessage *)nextMessage:(long)timeout;
- (SmackMessage *)pollMessage;
- (void)sendMessage:(SmackMessage *)message;
//- (void)sendMessage:(NSString *)message; // I wonder which one gets called there

@end

@interface JavaBoolean : JavaObject {
}

- (BOOL)booleanValue;

@end

@interface JavaIterator : JavaObject {
}

- (BOOL)hasNext;
- (id)next;
- (void)remove;

@end

@interface JavaCollection : JavaObject {
}

- (BOOL)contains:(id)o;
- (BOOL)equals:(id)o;
- (int)hashCode;
- (BOOL)isEmpty;
- (JavaIterator*)iterator;
- (int)size;

@end

@interface JavaSet : JavaObject {
}

- (BOOL)contains:(id)o;
- (BOOL)equals:(id)o;
- (int)hashCode;
- (BOOL)isEmpty;
- (JavaIterator*)iterator;
- (int)size;

@end

@interface JavaVector : JavaObject {
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
- (NSString *)toString;
- (JavaIterator*)iterator;

@end

@interface JavaMapEntry : JavaObject {
}

- (BOOL)equals:(id)o;
- (id)getKey;
- (id)getValue;
- (int)hashCode;

@end

@interface JavaMap : JavaObject {
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
- (void)putAll:(JavaMap *)t;
- (id)remove:(id)key;
- (int)size;
- (JavaSet*)entrySet;
- (JavaSet*)keySet;
- (JavaCollection*)values;

@end

@interface JavaList : JavaObject {
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

@interface JavaDate : JavaObject {
}

// Returns the number of milliseconds since January 1, 1970, 00:00:00 GMT represented by this Date object.
- (long)getTime;

@end

@interface JavaFile : JavaObject {
}

- (NSString *)getPath;
- (NSString *)getName;
- (NSString *)getAbsoluteFile;
- (NSString *)getAbsolutePath;

@end

@interface JavaMethod : JavaObject {
}

- (NSString *)getName;
- (id)invoke:(id)obj :(id)args; // second is String[]
- (NSString *)toString;
- (Class <JavaObject>)getReturnType;

@end

@interface JavaProperties : JavaMap {
}

@end

/*
 * java.lang.System
 */
@protocol JavaSystem
+ (JavaProperties *)getProperties;
@end

@protocol JavaEnum
+ (id)valueOf:(Class)classType :(NSString *)name;
@end

@interface SmackAccountManager : JavaObject {
}

- (void)changePassword:(NSString *)newPassword;
- (void)createAccount:(NSString *)username :(NSString *)password;
- (void)createAccount:(NSString *)username :(NSString *)password :(JavaMap *)attributes;
- (void)deleteAccount;
- (NSString *)getAccountAttribute:(NSString *)name;
- (JavaIterator*)getAccountAttributes;
- (NSString *)getAccountInstructions;
- (BOOL)supportsAccountCreation;

@end

@interface SmackRosterPacketItemStatus : JavaObject {
}

- (SmackRosterPacketItemStatus*)fromString:(NSString *)type;
- (NSString *)toString;

@end

@interface SmackRosterPacketItemType : JavaObject {
}

- (SmackRosterPacketItemType*)fromString:(NSString *)type;
- (NSString *)toString;

@end

@interface SmackRosterEntry : JavaObject {
}

- (BOOL)equals:(id)object;
- (JavaIterator*)getGroups;
- (NSString *)getName;
- (SmackRosterPacketItemStatus*)getStatus;
- (SmackRosterPacketItemType*)getType;
- (NSString *)getUser;
- (void)setName:(NSString *)name;
- (NSString *)toString;

@end

@interface SmackRosterPacketItem : JavaObject {
}

- (void)addGroupName:(NSString *)groupName;
- (JavaIterator*)getGroupNames;
- (SmackRosterPacketItemStatus*)getItemsStatus;
- (SmackRosterPacketItemType*)getItemType;
- (NSString *)getName;
- (NSString *)getUser;
- (void)removeGroupName:(NSString *)groupName;
- (void)setItemType:(SmackRosterPacketItemType*)itemType;
- (void)setName:(NSString *)name;
- (NSString *)toXML;

@end

@interface SmackRosterGroup : JavaObject {
}

- (void)addEntry:(SmackRosterEntry*)entry;
- (BOOL)contains:(SmackRosterEntry*)entry;
//- (BOOL)contains:(NSString *)user;
- (JavaIterator*)getEntries;
- (SmackRosterEntry*)getEntry:(NSString *)user;
- (int)getEntryCount;
- (NSString *)getName;
- (void)removeEntry:(SmackRosterEntry*)entry;
- (void)setName:(NSString *)name;

@end

@interface SmackPresenceMode : JavaObject {
}

- (SmackPresenceMode *)fromString:(NSString *)type;
- (NSString *)toString;

@end

@interface SmackPresenceType : JavaObject {
}

- (SmackPresenceType*)fromString:(NSString *)type;
- (NSString *)toString;

@end

@class SmackXMPPError;
@protocol SmackPacketExtension;

@interface SmackPacket : JavaObject {
}

- (void)addExtension:(id<SmackPacketExtension,NSObject>)extension;
- (void)deleteProperty:(NSString *)name;
- (SmackXMPPError*)getError;
- (id<SmackPacketExtension, JavaObject>)getExtension:(NSString *)elementName :(NSString *)namespace;
- (JavaIterator*)getExtensions;
- (NSString *)getFrom;
- (NSString *)getPacketID;
- (id)getProperty:(NSString *)name;
- (JavaIterator*)getPropertyNames;
- (NSString *)getTo;
- (void)removeExtension:(id<SmackPacketExtension,NSObject>)extension;

- (void)setError:(SmackXMPPError*)error;
- (void)setFrom:(NSString *)from;
- (void)setPacketID:(NSString *)packetID;
- (void)setProperty:(NSString *)name :(id)value; // some collisions!
- (void)setTo:(NSString *)to;
- (NSString *)toXML;

@end

@interface SmackMessage : SmackPacket {
}

- (NSString *)getBody;
- (NSString *)getSubject;
- (NSString *)getThread;
- (SmackMessageType *)getType;
- (void)setBody:(NSString *)body;
- (void)setSubject:(NSString *)subject;
- (void)setThread:(NSString *)thread;
- (void)setType:(SmackMessageType *)type;
- (NSString *)toXML;

@end

@interface SmackPresence : SmackPacket {
}

- (SmackPresenceMode *)getMode;
- (int)getPriority;
- (NSString *)getStatus;
- (SmackPresenceType*)getType;
- (void)setMode:(SmackPresenceMode *)mode;
- (void)setPriority:(int)priority;
- (void)setStatus:(NSString *)status;
- (void)setType:(SmackPresenceType*)type;
- (NSString *)toString;
- (NSString *)toXML;

@end

@interface SmackIQType : JavaObject {
}

- (SmackIQType*)fromString:(NSString *)type;
- (NSString *)toString;

@end

@interface SmackIQ : SmackPacket {
}

- (NSString *)getChildElementXML;
- (SmackIQType*)getType;
- (void)setType:(SmackIQType*)type;
- (NSString *)toXML;

@end

@interface SmackRegister : SmackIQ {
}

- (JavaMap *)getAttributes;
- (NSString *)getChildElementXML;
- (NSString *)getInstructions;
- (void)setAttributes:(JavaMap *)atttributes;
- (void)setInstructions:(NSString *)instructions;

@end

@interface SmackRosterPacket : SmackIQ {
}

- (void)addRosterItem:(SmackRosterPacketItem*)item;
- (NSString *)getChildElementXML;
- (int)getRosterItemCount;
- (JavaIterator*)getRosterItems;

@end

@class SmackRosterSubscriptionMode;

@protocol SmackRosterSubscriptionMode <JavaObject>
+ (SmackRosterSubscriptionMode *)valueOf:(NSString *)name;
@end

@interface SmackRosterSubscriptionMode : JavaObject <SmackRosterSubscriptionMode> {
}

@end

@interface SmackRoster : JavaObject {
}

- (void)addRosterListener:(id)rosterListener;
- (void)removeRosterListener:(id)rosterListener;
- (BOOL)contains:(NSString *)user;
- (void)createEntry:(NSString *)user :(NSString *)name :(id)groups; // last param is String[]
- (SmackRosterGroup*)createGroup:(NSString *)name;
- (int)getDefaultSubscriptionMode;
- (JavaVector *)getEntries;
- (SmackRosterEntry*)getEntry:(NSString *)user;
- (int)getEntryCount;
- (SmackRosterGroup*)getGroup:(NSString *)name;
- (int)getGroupCount;
- (JavaVector *)getGroups;
- (SmackPresence *)getPresence:(NSString *)user;
- (SmackPresence *)getPresenceResource:(NSString *)userResource;
- (JavaIterator*)getPresences:(NSString *)user;
- (int)getSubscriptionMode;
- (JavaIterator*)getUnfiledEntries;
- (int)getUnfiledEntryCount;
- (void)reload;
- (void)removeEntry:(SmackRosterEntry*)entry;
- (void)setDefaultSubscriptionMode:(SmackRosterSubscriptionMode*)subscriptionMode;
- (void)setSubscriptionMode:(SmackRosterSubscriptionMode*)subscriptionMode;

@end

@interface SmackInvisibleCommand : SmackIQ {
}

- (void)setInvisible:(BOOL)invisible;
- (BOOL)getInvisible;

@end

@interface SmackRegistration : SmackIQ {
}

- (JavaMap *)getAttributes;
- (NSString *)getChildElementXML;
- (NSString *)getInstructions;
- (void)setAttributes:(JavaMap *)attributes;
- (void)setInstructions:(NSString *)instructions;

@end

@interface SmackPrivacyItem : SmackIQ {
}

- (int)getOrder;
- (NSString *)getType;
- (NSString *)getValue;
- (BOOL)isAllow;
- (BOOL)isFilterEverything;
- (BOOL)isFilterIQ;
- (BOOL)isFilterMessage;
- (BOOL)isFilterPresence_in;
- (BOOL)isFilterPresence_out;
- (void)setFilterIQ:(BOOL)filterIQ;
- (void)setFilterMessage:(BOOL)filterMessage;
- (void)setFilterPresence_in:(BOOL)filterPresence_in;
- (void)setFilterPresence_out:(BOOL)filterPresence_out;
- (void)setValue:(NSString *)value;
- (NSString *)toXML;

@end

@interface SmackPrivacyList : JavaObject {
}

- (JavaVector *)getItems; // of SmackPrivacyItem
- (BOOL)isActiveList;
- (BOOL)isDefaultList;
- (NSString *)toString;

@end

@class SmackXMPPConnection, SmackPrivacyListManager;

@protocol SmackPrivacyListManager
+ (SmackPrivacyListManager *)getInstanceFor:(SmackXMPPConnection *)connection;
@end

@interface SmackPrivacyListManager : JavaObject <SmackPrivacyListManager> {
}

- (void)createPrivacyList:(NSString *)listname :(JavaVector *)privacyItems;
- (void)declineActiveList;
- (void)declineDefaultList;
- (void)deletePrivacyList:(NSString *)listName;
- (SmackPrivacyList*)getActiveList;
- (SmackPrivacyList*)getDefaultList;
- (SmackPrivacyList*)getPrivacyList:(NSString *)listName;
- (id)getPrivacyLists; // PrivacyList[]
- (void)setActiveListName:(NSString *)listName;
- (void)setDefaultListName:(NSString *)listName;
- (void)updatePrivacyList:(NSString *)listName :(JavaVector *)privacyItems;

@end

@interface SmackSASLAuthentication : JavaObject {
}

- (NSString *)authenticate:(NSString *)username :(NSString *)password :(NSString *)resource;
- (NSString *)authentcateAnonymously;
- (JavaList*)getRegisterSASLMechanisms;
- (BOOL)hasAnonymousAuthentication;
- (BOOL)hasNonAnonymousAuthentication;
- (BOOL)isAuthenticated;
- (void)send:(NSString *)stanza;

@end

@protocol SmackPacketExtension

- (NSString *)getElementName;
- (NSString *)getNamespace;
- (NSString *)toXML;

@end

@interface SmackXDelayInformation : JavaObject <SmackPacketExtension> {
}

- (JavaDate *)getStamp;
- (NSString *)getFrom;
- (NSString *)getReason;

@end

@interface SmackXMPPError : JavaObject {
}

- (int)getCode;
- (NSString *)getMessage;
- (NSString *)toString;
- (NSString *)toXML;

@end

@interface SmackXMPPConnection : JavaObject {
}

- (void)close;
- (SmackChat*)createChat:(NSString *)participant;
- (SmackAccountManager*)getAccountManager;
- (SmackRoster*)initializeRoster;
- (SmackRoster*)getRoster;
- (SmackSASLAuthentication*)getSASLAuthentication;
- (NSString *)getServiceName;
- (NSString *)getUser;
- (BOOL)isAnonymous;
- (BOOL)isAuthenticated;
- (BOOL)isConnected;
- (BOOL)isSecureConnection;
- (BOOL)isUsingCompression;
- (BOOL)isUsingTLS;
- (BOOL)login:(NSString *)username :(NSString *)password;
- (BOOL)login:(NSString *)username :(NSString *)password :(NSString *)resource;
- (BOOL)login:(NSString *)username :(NSString *)password :(NSString *)resource :(BOOL)sendPresence;
- (void)loginAnonymously;
- (void)sendPacket:(SmackPacket*)packet;

@end

@interface SmackXOccupant : JavaObject {
}

- (NSString *)getAffiliation;
- (NSString *)getJid;
- (NSString *)getNick;
- (NSString *)getRole;

@end

@interface SmackXFormFieldOption : JavaObject {
}

- (NSString *)getLabel;
- (NSString *)getValue;
- (NSString *)toString;
- (NSString *)toXML;

@end

@interface SmackXFormField : JavaObject {
}

- (NSString *)getDescription;
- (NSString *)getLabel;
- (JavaIterator*)getOptions;
- (NSString *)getType;
- (JavaIterator*)getValues;
- (NSString *)getVariable;
- (BOOL)isRequired;

- (void)resetValues;
- (void)addValue:(NSString *)value;

- (void)setLabel:(NSString *)label;
- (void)setType:(NSString *)type;

- (NSString *)toXML;

@end

@interface SmackXDataFormItem : JavaObject {
}

- (JavaIterator*)getFields;
- (NSString *)toXML;

@end

@interface SmackXDataFormReportedData : JavaObject {
}

- (JavaIterator*)getFields;
- (NSString *)toXML;

@end

@interface SmackXDataForm : JavaObject <SmackPacketExtension> {
}

- (void)addField:(SmackXFormField *)field;
- (void)addInstruction:(NSString *)instruction;
- (void)addItem:(SmackXDataFormItem*)item;
- (NSString *)getElementName;
- (JavaIterator*)getFields;
- (JavaIterator*)getInstructions;
- (JavaIterator*)getIterms;
- (NSString *)getNamespace;
- (SmackXDataFormReportedData*)getReportedData;
- (NSString *)getTitle;
- (NSString *)getType;
- (void)setInstructions:(JavaList*)instructions;
- (void)setReportedData:(SmackXDataFormReportedData*)reportedData;
- (void)setTitle:(NSString *)title;
- (NSString *)toXML;

@end

@class SmackXForm, SmackPacket;

@protocol SmackXForm <JavaObject>
+ (SmackXForm *)getFormFrom:(SmackPacket *)packet;
@end

@interface SmackXForm : JavaObject <SmackXForm> {
}
- (SmackXFormField *)getField:(NSString *)variable;
- (JavaIterator *)getFields;
- (NSString *)getInstructions;
- (NSString *)getTitle;
- (NSString *)getType;
- (void)setAnswer:(NSString *)variable :(NSNumber *)value;
- (SmackXDataForm *)getDataFormToSend;
- (SmackXForm *)createAnswerForm;
- (void)addField:(SmackXFormField *)field;
- (void)setInstructions:(NSString *)instructions;
- (void)setTitle:(NSString *)title;

@end

@interface SmackXDiscoverItem : JavaObject {
}

- (NSString *)getAction;
- (NSString *)getEntityID;
- (NSString *)getName;
- (NSString *)getNode;
- (void)setAction:(NSString *)action;
- (void)setName:(NSString *)name;
- (void)setNode:(NSString *)node;
- (NSString *)toXML;

@end

@interface SmackXDiscoverItems : SmackIQ {
}

- (void)addItem:(SmackXDiscoverItem*)item;
- (NSString *)getChildElementXML;
- (JavaIterator*)getItems;
- (NSString *)getNode;
- (void)setNode:(NSString *)node;

@end

@interface SmackXDiscoverInfoIdentity : JavaObject {
}

- (NSString *)getCategory;
- (NSString *)getName;
- (NSString *)getType;
- (void)setType:(NSString *)type;
- (NSString *)toXML;

@end

@interface SmackXDiscoverInfo : SmackIQ {
}

- (void)addFeature:(NSString *)feature;
- (void)addIdentity:(SmackXDiscoverInfoIdentity*)identity;
- (BOOL)containsFeature:(NSString *)feature;
- (JavaIterator*)getIdentities;
- (NSString *)getNode;
- (void)setNode:(NSString *)node;

@end

@interface SmackXDiscussionHistory : JavaObject {
}

- (int)getMaxChars;
- (int)getMaxStanzas;
- (int)getSeconds;
- (JavaDate *)getSince;
- (void)setMaxChars:(int)maxChars;
- (void)setMaxStanzas:(int)maxStanzas;
- (void)setSeconds:(int)seconds;
- (void)setSince:(JavaDate *)since;

@end

@interface SmackXMultiUserChat : JavaObject {
}

- (void)banUser:(NSString *)jid :(NSString *)reason;
- (void)banUsers:(JavaCollection*)jids;

- (void)changeAvailabilityStatus:(NSString *)status :(SmackPresenceMode *)mode;
- (void)changeNickname:(NSString *)nickname;
- (void)changeSubject:(NSString *)subject;

- (void)create:(NSString *)nickname;
- (SmackMessage *)createMessage;
- (SmackChat*)createPrivateChat:(NSString *)occupant;

- (void)destroy:(NSString *)reason :(NSString *)alternateJID;

- (JavaCollection*)getAdmins;
- (JavaCollection*)getMembers;
- (JavaCollection*)getModerators;
- (NSString *)getNickname;
- (SmackXOccupant*)getOccupant:(NSString *)user;
- (SmackPresence *)getOccupantPresence:(NSString *)user;
- (JavaIterator*)getOccupants;
- (int)getOccupantsCount;
- (JavaCollection*)getOutcasts;
- (JavaCollection*)getOwners;
- (JavaCollection*)getParticipants;
- (NSString *)getReservedNickname;
- (NSString *)getRoom;
- (NSString *)getSubject;

- (void)grantAdmin:(NSString *)jid;
- (void)revokeAdmin:(NSString *)jid;

- (void)grantMembership:(NSString *)jid;
- (void)revokeMembership:(NSString *)jid;

- (void)grantOwnership:(NSString *)jid;
- (void)revokeOwnership:(NSString *)jid;

- (void)grantModerator:(NSString *)nickname;
- (void)revokeModerator:(NSString *)nickname;

- (void)grantVoice:(NSString *)nickname;
- (void)revokeVoice:(NSString *)nickname;

- (void)kickParticipant:(NSString *)nickname :(NSString *)reason;

- (void)invite:(SmackMessage *)message :(NSString *)user :(NSString *)reason;
- (void)invite:(NSString *)user :(NSString *)reason;

- (BOOL)isJoined;
- (void)join:(NSString *)nickname;
- (void)join:(NSString *)nickname :(NSString *)password;
- (void)join:(NSString *)nickname :(NSString *)password :(SmackXDiscussionHistory*)history :(long)timeout;
- (void)leave;

- (SmackMessage *)nextMessage;
- (SmackMessage *)nextMessage:(long)timeout;
- (SmackMessage *)pollMessage;
- (void)sendMessage:(SmackMessage *)message;

- (SmackXForm *)getConfigurationForm;
- (void)sendConfigurationForm:(SmackXForm *)form;

- (SmackXForm *)getRegistrationForm;
- (void)sendRegistrationForm:(SmackXForm *)form;

@end

@interface SmackXFileTransferStatus : JavaObject {
}

- (NSString *)toString;

@end

@interface SmackXFileTransferError : JavaObject {
}

- (NSString *)getMessage;
- (NSString *)toString;

@end

@interface SmackXFileTransfer: JavaObject {
}

- (void)cancel;
- (long)getAmountWritten;
- (SmackXFileTransferError*)getError;
//- (JavaException*)getException;
- (NSString *)getFileName;
- (NSString *)getFilePath;
- (long)getFileSize;
- (NSString *)getPeer;
- (double)getProgress;
- (SmackXFileTransferStatus*)getStatus;
- (BOOL)isDone;

@end

@interface SmackXOutgoingFileTransfer : SmackXFileTransfer {
}

- (long)getBytesSent;
- (void)sendFile:(JavaFile *)file :(NSString *)description;
- (void)sendFile:(NSString *)filename :(long)fileSize :(NSString *)description;

@end

@interface SmackXIncomingFileTransfer : SmackXFileTransfer {
}

- (void)receiveFile:(JavaFile *)file;

@end

@interface SmackXFileTransferRequest : JavaObject {
}

- (SmackXIncomingFileTransfer*)accept;
- (NSString *)getDescription;
- (NSString *)getFileName;
- (long)getFileSize;
- (NSString *)getMimeType;
- (NSString *)getRequestor;
- (NSString *)getStreamID;
- (void)reject;

@end

@interface SmackXMessageEvent : JavaObject <SmackPacketExtension> {
}

- (JavaIterator*)getEventTypes;
- (NSString *)getPacketID;
- (BOOL)isCancelled;
- (BOOL)isComposing;
- (BOOL)isDelivered;
- (BOOL)isDisplayed;
- (BOOL)isMessageEventRequest;
- (BOOL)isOffline;
- (void)setCancelled:(BOOL)cancelled;
- (void)setComposing:(BOOL)composing;
- (void)setDelivered:(BOOL)delivered;
- (void)setDisplayed:(BOOL)displayed;
- (void)setOffline:(BOOL)offline;
- (void)setPacketID:(NSString *)packetID;
- (NSString *)toXML;

@end

@class SmackXServiceDiscoveryManager;

@protocol SmackXServiceDiscoveryManager <JavaObject>
+ (SmackXServiceDiscoveryManager *)getInstanceFor:(SmackXMPPConnection*)connection;
+ (NSString *)getIdentityName;
+ (NSString *)getIdentityType;
+ (void)setIdentityName:(NSString *)name;
+ (void)setIdentityType:(NSString *)type;
@end

@interface SmackXServiceDiscoveryManager : JavaObject <SmackXServiceDiscoveryManager> {
}

- (void)addFeature:(NSString *)feature;
- (BOOL)canPublishItems:(NSString *)entityID;
- (SmackXDiscoverInfo*)discoverInfo:(NSString *)entityID;
- (SmackXDiscoverInfo*)discoverInfo:(NSString *)entityID :(NSString *)node;
- (SmackXDiscoverItems*)discoverItems:(NSString *)entityID;
- (SmackXDiscoverItems*)discoverItems:(NSString *)entityID :(NSString *)node;
- (JavaIterator*)getFeatures;
- (BOOL)includesFeature:(NSString *)feature;
- (void)publishItems:(NSString *)entityID :(SmackXDiscoverItems*)discoverItems;
- (void)publishItems:(NSString *)entityID :(NSString *)node :(SmackXDiscoverItems*)discoverItems;
- (void)removeFeature:(NSString *)feature;
- (void)removeNodeInformationProvider:(NSString *)node;

@end

@interface SmackXVCard : SmackIQ {
}

- (BOOL)equals:(id)o;
- (NSString *)getAddressFieldHome:(NSString *)addrField;
- (NSString *)getAddressFieldWork:(NSString *)addrField;
- (id)getAvatar; // byte[]
- (NSString *)getAvatarHash;
- (NSString *)getChildElementXML;
- (NSString *)getEmailHome;
- (NSString *)getEmailWork;
- (NSString *)getField:(NSString *)field;
- (NSString *)getFirstName;
- (NSString *)getJabberId;
- (NSString *)getLastName;
- (NSString *)getMiddleName;
- (NSString *)getNickName;
- (NSString *)getOrganization;
- (NSString *)getOrganizationUnit;
- (NSString *)getPhoneHome:(NSString *)phoneType;
- (NSString *)getPhoneWork:(NSString *)phoneType;
- (void)load:(SmackXMPPConnection*)connection;
- (void)load:(SmackXMPPConnection*)connection :(NSString *)user;
- (void)save:(SmackXMPPConnection*)connection;
- (void)setAddressFieldHome:(NSString *)addrField :(NSString *)value;
- (void)setAddressFieldWork:(NSString *)addrField :(NSString *)value;
- (void)setAvatar:(id)bytes; // byte[]
- (void)setEmailHome:(NSString *)email;
- (void)setEmailWork:(NSString *)emailWork;
- (void)setEncodedImage:(NSString *)encodedAvatar;
- (void)setField:(NSString *)field :(NSString *)value;
- (void)setField:(NSString *)field :(NSString *)value :(BOOL)isUnescapable;
- (void)setFirstName:(NSString *)firstName;
- (void)setJabberId:(NSString *)jabberId;
- (void)setLastName:(NSString *)lastName;
- (void)setMiddleName:(NSString *)middleName;
- (void)setNickName:(NSString *)nickName;
- (void)setOrganization:(NSString *)organization;
- (void)setOrganizationUnit:(NSString *)organizationUnit;
- (void)setPhoneHome:(NSString *)phoneType :(NSString *)phoneNum;
- (void)setPhoneWork:(NSString *)phoneType :(NSString *)phoneNum;
- (NSString *)toString;

@end

@interface SmackXVersion : SmackIQ {
}

- (NSString *)getName;
- (NSString *)getOs;
- (NSString *)getVersion;
- (void)setName:(NSString *)name;
- (void)setOs:(NSString *)os;
- (void)setVersion:(NSString *)version;

@end

@interface SmackXMPPException : JavaObject {
}

- (SmackXMPPError*)getXMPPError;

@end

@interface SmackConfiguration : JavaObject {
}

+ (NSString *)getVersion;

@end

@interface SmackDNSUtilHostAddress : JavaObject {
}

- (NSString *)getHost;
- (int)getPort;
- (NSString *)toString;
- (BOOL)equals:(id)o;

@end

@interface SmackDNSUtil : JavaObject {
}

- (SmackDNSUtilHostAddress*)resolveXMPPDomain:(NSString *)domain;
- (SmackDNSUtilHostAddress*)resolveXMPPServerDomain:(NSString *)domain;

@end

@interface SmackOutOfBandExtension : JavaObject <SmackPacketExtension> {
}

- (void)setUrl:(NSString *)url;
- (NSString *)getUrl;
- (void)setDesc:(NSString *)desc;
- (NSString *)getDesc;

@end

@interface SmackVCardUpdateExtension : JavaObject <SmackPacketExtension> {
}

- (void)setPhoto:(NSString *)photo;
- (NSString *)getPhoto;
- (NSString *)toXML;

@end

@class SmackChatStateNotifications;

@protocol SmackChatStateNotifications
+ (SmackChatStateNotifications*)getChatState:(SmackMessage *)message;
+ (SmackChatStateNotifications*)createChatState:(NSString *)type;
@end

@interface SmackChatStateNotifications : JavaObject <SmackChatStateNotifications, SmackPacketExtension> {
}

@end

#define SmackResolveXMPPDomain(domain) [NSClassFromString(@"org.jivesoftware.smack.util.DNSUtil") resolveXMPPDomain:domain]

@protocol AdiumSmackBridgeDelegate

- (void)setConnection:(SmackXMPPConnection*)conn;
- (void)setDisconnection:(JavaBoolean*)blah;
- (void)setConnectionError:(NSString *)error;
- (void)setNewMessagePacket:(SmackPacket*)packet;
- (void)setNewPresencePacket:(SmackPacket*)packet;
- (void)setNewIQPacket:(SmackPacket*)packet;

@end

@protocol AdiumSmackBridge <JavaObject>
+ (void)createRosterEntry:(SmackRoster*)roster :(NSString *)jid :(NSString *)name :(NSString *)group;
+ (BOOL)isInstanceOfClass:(id)obj :(NSString *)classname;
+ (id)getStaticFieldFromClass:(NSString *)fieldname :(NSString *)classname;
+ (id)getStaticFieldFromClassObject:(NSString *)fieldname :(Class <JavaObject>)classobj;
+ (JavaMethod*)getMethod:(NSString *)classname :(NSString *)method :(JavaVector *)argumentTypes;
+ (id)invokeMethod:(JavaMethod*)meth :(id)obj :(JavaVector *)params;

+ (void)setVCardAvatar:(SmackXVCard*)vCard :(NSData*)avatar;
+ (NSData*)getVCardAvatar:(SmackXVCard*)vCard;
+ (BOOL)isAvatarEmpty:(SmackXVCard*)vCard;
+ (JavaVector *)getAllPrivacyLists:(SmackXMPPConnection*)conn;
@end

@interface AdiumSmackBridge : JavaObject <AdiumSmackBridge> {
}

- (void)initSubscriptionMode;
- (void)setDelegate:(id<AdiumSmackBridgeDelegate>)delegate;
- (id<AdiumSmackBridgeDelegate>)delegate;

- (void)createConnection:(BOOL)useSSL :(SmackConnectionConfiguration *)conf;
- (SmackXServiceDiscoveryManager*)getServiceDiscoveryManager;

- (BOOL)isInstanceOfClass:(id)object :(NSString *)classname;
- (JavaMethod*)getMethod:(NSString *)classname :(NSString *)methodname :(JavaVector *)parameterTypes;

@end

#pragma mark Extensions

@interface SmackXXHTMLExtension : JavaObject <SmackPacketExtension> {
}

- (void)addBody:(NSString *)body;
- (JavaIterator*)getBodies;
- (int)getBodyCount;
- (NSString *)getElementName;
- (NSString *)getNamespace;
- (NSString *)toXML;

@end

#pragma mark Jingle

@class SmackXPayloadType;

@interface SmackXJingleContentDescriptionJinglePayloadType : JavaObject {
}

- (SmackXPayloadType*)getPayloadType;
- (void)setPayload:(SmackXPayloadType*)payload;
- (NSString *)toXML;

@end

@interface SmackXJingleContentDescriptionJinglePayloadTypeAudio : SmackXJingleContentDescriptionJinglePayloadType {
}
@end

@interface SmackXJingleContentDescription : JavaObject {
}

- (void)addAudioPlayloadTypes:(JavaVector *)pts;
- (void)addJinglePayloadType:(SmackXJingleContentDescriptionJinglePayloadType*)pt;
- (JavaVector *)getAudioPayloadTypesList;
- (NSString *)getElementName;
- (JavaIterator*)getJinglePayloadTypes;
- (int)getJinglePayloadTypesCount;
- (JavaVector *)getJinglePayloadTypesList;
- (NSString *)toXML;

@end

@interface SmackXJingleContentDescriptionAudio : SmackXJingleContentDescription <SmackPacketExtension> {
}

@end

@interface SmackXTransportCandidate : JavaObject {
}

- (BOOL)equals:(id)obj;
- (int)getGeneration;
- (NSString *)getIP;
- (NSString *)getName;
- (int)getPort;
- (BOOL)isNull;
- (void)setGeneration:(int)generation;
- (void)setIP:(NSString *)ip;
- (void)setName:(NSString *)name;
- (void)setPort:(int)port;

@end

@interface SmackXJingleTransportJingleTransportCandidate : JavaObject {
}

- (SmackXTransportCandidate*)getMediaTransport;
- (void)setMediaTransport:(SmackXTransportCandidate*)cand;
- (NSString *)toXML;

@end

@interface SmackXJingleTransport : JavaObject <SmackPacketExtension> {
}

- (void)addCondidate:(SmackXJingleTransportJingleTransportCandidate*)candidate;
- (JavaIterator*)getCandidates;
- (NSString *)toXML;

@end

@interface SmackXTransportCandidateChannel : JavaObject {
}

- (BOOL)equals:(id)obj;
+ (SmackXTransportCandidateChannel*)fromString:(NSString *)value;
- (BOOL)isNull;
- (NSString *)toString;

@end

@interface SmackXTransportCandidateProtocol : JavaObject {
}

- (BOOL)equals:(id)obj;
+ (SmackXTransportCandidateProtocol*)fromString:(NSString *)value;
- (BOOL)isNull;
- (NSString *)toString;

@end

@interface SmackXTransportCandidateFixed : SmackXTransportCandidate {
}
@end

@interface SmackXTransportCandidateIce : SmackXTransportCandidate {
}

- (int)compareTo:(id)arg;
- (SmackXTransportCandidateChannel*)getChannel;
- (NSString *)getId;
- (int)getNetwork;
- (NSString *)getPassword;
- (int)getPreference;
- (SmackXTransportCandidateProtocol*)getProto;
- (NSString *)getUsername;
- (void)setChannel:(SmackXTransportCandidateChannel*)channel;
- (void)setId:(NSString *)_id;
- (void)setNetwork:(int)network;
- (void)setPassword:(NSString *)password;
- (void)setPreference:(int)preference;
- (void)setProto:(SmackXTransportCandidateProtocol*)proto;
- (void)setUsername:(NSString *)username;

@end

@interface SmackXJingleAction : JavaObject {
}

- (BOOL)equals:(id)obj;
+ (SmackXJingleAction*)fromString:(NSString *)value;
- (NSString *)toString;

@end

@class SmackXContentInfo;

@interface SmackXJingleContentInfo : JavaObject <SmackPacketExtension> {
}

- (SmackXContentInfo*)getMediaInfo;

@end

@interface SmackXJingleContentInfoAudio : SmackXJingleContentInfo {
}
@end

@interface SmackXJingleContentInfoAudioBusy : SmackXJingleContentInfoAudio {
}
@end

@interface SmackXJingleContentInfoAudioHold : SmackXJingleContentInfoAudio {
}
@end

@interface SmackXJingleContentInfoAudioQueued : SmackXJingleContentInfoAudio {
}
@end

@interface SmackXJingleContentInfoAudioRinging : SmackXJingleContentInfoAudio {
}
@end

@interface SmackXJingle : SmackIQ {
}

- (void)addDescription:(SmackXJingleContentDescription*)desc;
- (void)addDescriptions:(JavaVector *)descsList;
- (void)addTransport:(SmackXJingleTransport*)trans;
- (void)addTransports:(JavaVector *)transList;
- (SmackXJingleAction*)getAction;
- (SmackXJingleContentInfo*)getContentInfo;
- (JavaIterator*)getDescriptions;
- (NSString *)getInitiator;
- (NSString *)getResponder;
+ (int)getSessionHash:(NSString *)sid :(NSString *)initiator;
- (NSString *)getSid;
- (JavaIterator*)getTransports;
- (void)setAction:(SmackXJingleAction*)action;
- (void)setContentInfo:(SmackXJingleContentInfo*)contentInfo;
- (void)setInitiator:(NSString *)initiator;
- (void)setResponder:(NSString *)resp;
- (void)setSid:(NSString *)sid;

@end

@class SmackXJingleNegotiator;

@interface SmackXJingleListener : JavaObject {
}
@end


@interface SmackXJingleNegotiatorState : JavaObject {
}

- (SmackXJingleNegotiator*)getNegotiator;
- (void)setNegotiator:(SmackXJingleNegotiator*)neg;

@end

@interface SmackXJingleNegotiator : JavaObject {
}

- (void)addExpectedId:(NSString *)id;
- (void)close;
- (void)addListener:(SmackXJingleListener*)listener;
- (void)removeListener:(SmackXJingleListener*)listener;
- (SmackIQ*)dispatchIncomingPacket:(SmackIQ*)iq :(NSString *)_id;
- (SmackXMPPConnection*)getConnection;
- (SmackXJingleNegotiatorState*)getState;
- (Class)getStateClass;
- (BOOL)invalidState;
- (BOOL)isExpectedId:(NSString *)_id;
- (void)removeExpectedId:(NSString *)_id;
- (void)setConnection:(SmackXMPPConnection*)connection;

@end

@interface SmackXContentInfo : JavaObject {
}
@end

@interface SmackXContentInfoAudio : SmackXContentInfo {
}

+ (SmackXContentInfo*)fromString:(NSString *)value;
- (NSString *)toString;

@end

@class SmackXIncomingJingleSession;

@interface SmackXJingleSessionRequest : JavaObject {
}

- (SmackXIncomingJingleSession*)accept:(JavaVector *)pts;
- (NSString *)getFrom;
- (NSString *)getSessionID;
- (void)reject;

@end

@interface SmackXJingleSession : SmackXJingleNegotiator {
}

- (void)close;
+ (SmackIQ*)createError:(NSString *)_id :(NSString *)to :(NSString *)from :(int)errCode :(NSString *)errStr;
+ (SmackIQ*)createIQ:(NSString *)_id :(NSString *)to :(NSString *)from :(SmackIQType*)type;
- (SmackIQ*)dispatchIncomingPacket:(SmackIQ*)iq :(NSString *)_id;
- (BOOL)equals:(id)obj;
- (NSString *)getInitiator;
- (NSString *)getResponder;
- (NSString *)getSid;
- (BOOL)isFullyEstablished;
- (BOOL)isValid;
- (SmackIQ*)respond:(SmackIQ*)iq;
- (void)sendContentInfo:(SmackXContentInfo*)ci;
- (void)setInitiator:(NSString *)initiator;
- (void)setResponder:(NSString *)responder;
- (void)start:(SmackXJingleSessionRequest*)jin;

@end

@interface SmackXIncomingJingleSession : SmackXJingleSession {
}
@end

@interface SmackXOutgoingJingleSession : SmackXJingleSession {
}
@end

@interface SmackXJingleManager : JavaObject {
}

- (SmackXOutgoingJingleSession*)createOutgoingJingleSession:(NSString *)responder :(JavaVector *)payloadTypes;

@end

@interface SmackXPayloadType : JavaObject {
}

- (BOOL)equals:(id)obj;
- (int)getChannels;
- (int)getId;
- (NSString *)getName;
- (BOOL)isNull;
- (void)setChannels:(int)channels;
- (void)setId:(int)_id;
- (void)setName:(NSString *)name;

@end

@interface SmackXPayloadTypeAudio : SmackXPayloadType {
}

- (BOOL)equals:(id)obj;
- (int)getClockRate;
- (void)setClockRate:(int)clockRate;

@end
