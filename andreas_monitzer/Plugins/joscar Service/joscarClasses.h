
//
//  joscarClasses.h
//
//  Created by Evan Schoenberg on 6/21/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//


//These Java classes are defined by the oscar and joscar jar files or by the standard Java libraries
//See http://www.cocoadevcentral.com/articles/000024.php for info on constructors

/* Forward declarations */
@class AimSession, AppSession, BuddyInfoManager, MainBosService, BosService, BuddyInfoTracker, State, StateInfo, LoginService;
@class MutableBuddyList, PermissionList, MyBuddyIconManager;
@class RvConnectionManager;
@class IcbmService, InfoService, SsiService, TypingState;
@class ByteBlock, ChatRoomManager, ChatRoomSession,FullRoomInfo;
@class ArrayList, Date, File, Enum, Map;

@protocol Collection, Set, ChatRoomSessionListener, FileTransferListener, Iterator;

/*
 * net.kano.joustsim.Screenname
 *
 * Constructor: String formattedUID == @"(Ljava/lang/String;)"
 */
#define NewScreenname(screenname)	[NSClassFromString(@"net.kano.joustsim.Screenname") \
									newWithSignature:@"(Ljava/lang/String;)", \
									(screenname)]
@interface Screenname : NSObject {}
- (NSString *)getNormal;
- (NSString *)getFormatted;
@end

/*
 * net.kano.joustsim.oscar.AimConnectionProperties
 * Constructor: (Screenname sn, String password) == @"(Lnet/kano/joustsim/Screenname;Ljava/lang/String;)"
 */
#define NewAimConnectionProperties(sn, pass)	[NSClassFromString(@"net.kano.joustsim.oscar.AimConnectionProperties") \
												newWithSignature:@"(Lnet/kano/joustsim/Screenname;Ljava/lang/String;)", \
												(sn), (pass)]
@interface AimConnectionProperties : NSObject {}
- (void)setScreenname:(Screenname *)sn;
- (void)setPassword:(NSString *)password;
@end

/*
 * net.kano.joustsim.oscar.proxy.AimProxyInfo
 */
#define AimProxyInfoClass NSClassFromString(@"net.kano.joustsim.oscar.proxy.AimProxyInfo")
@interface AimProxyInfo : NSObject {}
+ (AimProxyInfo *)forSocks5:(NSString *)host :(int)port :(NSString *)username :(NSString *)password;
+ (AimProxyInfo *)forHttp:(NSString *)host :(int)port :(NSString *)username :(NSString *)password;
+ (AimProxyInfo *)forSocks4:(NSString *)host :(int)port;
+ (AimProxyInfo *)forNoProxy;
@end

/*
 * net.kano.joustsim.oscar.AimConnection
 * Constructor: (Screenname sn, String password)
 * Constructor: (AimConnectionProperties props)
 * Constructor: (AimSession aimSession, AimConnectionProperties props)
 * Constructor: (AimSession aimSession, TrustPreferences prefs, AimConnectionPropertiese props)
 */
@protocol StateListener, OpenedServiceListener;
@interface AimConnection : NSObject {}
- (AppSession *)getAppSession;
- (AimSession *)getAimSession;
- (Screenname *)getScreenname;
- (LoginService *)getLoginService;
/* XXX - MANY MORE */
- (BuddyInfoManager *)getBuddyInfoManager;
- (BuddyInfoTracker *)getBuddyInfoTracker;
- (MyBuddyIconManager *)getMyBuddyIconManager;
- (InfoService *)getInfoService;
- (MainBosService *)getBosService;
- (SsiService *)getSsiService;
- (State *)getState;
- (StateInfo *)getStateInfo;
- (void)connect;
- (void)disconnect;
- (ChatRoomManager *)getChatRoomManager;

- (IcbmService *)getIcbmService;

- (void)addStateListener:(id<StateListener>)listener;
- (void)removeStateListener:(id<StateListener>)listener;

- (void)addOpenedServiceListener:(id<OpenedServiceListener>)listener;
- (void)removeOpenedServiceListener:(id<OpenedServiceListener>)listener;

- (void)setProxy:(AimProxyInfo *)proxyInfo;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.login.SecuridProvider
 */
@protocol SecuridProvider
- (NSString *)getSecurid;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.login.LoginService
 */
@interface LoginService : NSObject {}
- (void)setSecuridProvider:(id<SecuridProvider>)provider;
- (id<SecuridProvider>)getSecuridProvider;
@end

/*
 * net.kano.joustsim.oscar.AimSession
 *
 * This is an abstract class!  Use DefaultAimSession.  (??)
 */
@interface AimSession : NSObject {}
- (AppSession *)getAppSession;
- (Screenname *)getScreenname;
- (AimConnection *)openConnection:(AimConnectionProperties *)props;
- (AimConnection *)getConnection;
- (void)closeConnection;
- (/*TrustPreferences **/id)getTrustPreferences;
@end

/*
 * net.kano.joustsim.oscar.DefaultAimSession
 * Constructor: (Screenname sn)
 * Constructor: (AppSession appSession, Screenname sn)
 * Constructor: (AppSession appSession,  Screenname sn, TrustPreferences trustPreferences)
 */
#define NewDefaultAimSession(sn, pass)	[NSClassFromString(@"net.kano.joustsim.oscar.DefaultAimSession") \
										newWithSignature:@"(Lnet/kano/joustsim/Screenname;)", \
										(sn)]
@interface DefaultAimSession : AimSession {}
@end

/*
 * net.kano.joustsim.oscar.AppSession
 *
 * This is an abstract class!  Use DefaultAppSession.
 */
@interface AppSession : NSObject {}
@end

/*
 * net.kano.joustsim.oscar.DefaultAppSession
 */
#define NewDefaultAppSession()		[[NSClassFromString(@"net.kano.joustsim.oscar.DefaultAppSession") alloc] init]
@interface DefaultAppSession : AppSession {}
- (AimSession *)openAimSession:(Screenname *)sn;
@end

/*
 * net.kano.joustsim.oscar.State
 */
@interface State : NSObject {}
- (NSString *)toString;
@end

/*
 * net.kano.joustsim.oscar.StateInfo
 */
@interface StateInfo : NSObject {}
- (State *)getState;
@end

/*
 * net.kano.joustsim.oscar.StateEvent
 */
@interface StateEvent : NSObject {}
- (AimConnection *)getAimConnection;
- (State *)getOldState;
- (StateInfo *)getOldStateInfo;
- (State *)getNewState;
- (StateInfo *)getNewStateInfo;
@end

/*
 * net.kano.joustsim.oscar.BuddyInfo
 */
@interface BuddyInfo : NSObject {}
- (NSString *)getUserProfile;
- (NSString *)getAwayMessage;
- (NSString *)getStatusMessage;
- (NSString *)getItunesUrl;
- (BOOL)isOnline;
- (BOOL)isAway;
- (Date *)getIdleSince;
- (Date *)getOnlineSince;
- (int)getWarningLevel;
- (ByteBlock *)getIconData;
- (BOOL)isMobile;
- (BOOL)isAolUser;
@end

/*
 * java.beans.PropertyChangeEvent extends java/util/EventObject
 */
@interface PropertyChangeEvent : NSObject {}
- (NSString *)getPropertyName;
- (NSObject *)getNewValue;
- (NSObject *)getOldValue;
@end

/*
 * net.kano.joustsim.oscar.BuddyInfoManager
 */
@protocol GlobalBuddyInfoListener;
@interface BuddyInfoManager : NSObject {}
- (void)addGlobalBuddyInfoListener:(id <GlobalBuddyInfoListener>)listener;
- (void)removeGlobalBuddyInfoListener:(id <GlobalBuddyInfoListener>)listener;
- (BuddyInfo *)getBuddyInfo:(Screenname *)sn;
@end

/*
 * net.kano.joustsim.oscar.MyBuddyIconManager
 */
@interface MyBuddyIconManager : NSObject {}
- (void)requestSetIcon:(ByteBlock *) iconInfo;
- (void)requestClearIcon;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.Service
 */
@interface Service : NSObject {}
@end

/*
 * net.kano.joustsim.oscar.oscar.service.bos.BosService
 */
@interface BosService : Service {}
@end

/*
 * net.kano.joustsim.oscar.oscar.service.ssi.ServerStoredSettings
 */
@interface ServerStoredSettings : NSObject {}
- (void)changeMobileDeviceShown:(BOOL)inFlag;
- (void)changeIdleTimeShown:(BOOL)inFlag;
- (void)changeTypingShown:(BOOL)inFlag;
- (void)changeRecentBuddiesUsed:(BOOL)inFlag;
@end

@interface SsiService : NSObject {}
- (MutableBuddyList *)getBuddyList;
- (PermissionList *)getPermissionList;
- (ServerStoredSettings *)getServerStoredSettings;
- (void)requestBuddyAuthorization:(Screenname *)sn :(NSString *)authorizationMessage;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.info.InfoService
 *
 * XXX - Probably lower-level than we should actually be going. Would be needed for profiles it looks like 
 * since BuddyInfoTracker can handle updating away messages. -eds
 */
@protocol InfoServiceListener;
@interface InfoService : Service {}
- (void)addInfoListener:(id <InfoServiceListener>)listener;
- (void)removeInfoListener:(id <InfoServiceListener>)listener;
- (void)requestAwayMessage:(Screenname *)sn;
- (void)requestUserProfile:(Screenname *)sn;
- (void)setAwayMessage:(NSString *)away;
- (void)setUserProfile:(NSString *)profile;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.bos.MainBosService
 */
 
@interface MainBosService : BosService {}
- (void)setIdleSince:(Date *)since;
- (void)setUnidle;
- (void)setVisibleStatus:(BOOL)visible;
- (void)setStatusMessage:(NSString *)msg;
- (void)setStatusMessageSong:(NSString *)msg :(NSString *)itmsURL;
//there's more, these are just the ones we actually use.
@end

/*
 *  net.kano.joustsim.oscar.BuddyInfoTracker
 */
@protocol BuddyInfoTrackerListener;
@interface BuddyInfoTracker : NSObject {}
- (void)addTracker:(Screenname *)sn :(id<BuddyInfoTrackerListener>)listener;
@end
/*
 * net.kano.joustsim.oscar.oscar.service.icbm.Message
 */
@interface Message : NSObject {}
- (NSString *)getMessageBody;
- (BOOL)isAutoResponse;
@end

@interface SimpleMessage : Message {}
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.BasicInstantMessage
 * Constructor: (String messageBody)
 * Constructor: (String messageBody, boolean autoResponse)
 * Constructor: (String msg, boolean ar, String aimexp)
 */
#define NewBasicInstantMessage(msg, ar)	[NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.icbm.BasicInstantMessage") \
										newWithSignature:@"(Ljava/lang/String;Z)", \
										(msg), (ar)]
@interface BasicInstantMessage : SimpleMessage {}
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.DirectMessage
 * Constructor: (String messageBody, boolean autoResponse, Set<Attachment> set)
 */
#define NewDirectMessage(msg, ar, set)	[NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.icbm.DirectMessage") \
										newWithSignature:@"(Ljava/lang/String;ZLjava/util/Set;)", \
										(msg), (ar), (set)]
@interface DirectMessage : Message {}
- (NSObject<Set> *)getAttachments;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.Conversation
 */
@interface Conversation : NSObject {}
- (Screenname *)getBuddy;
- (BOOL)canSendMessage;
- (void)sendMessage:(Message *)msg;
- (BOOL)open;
- (BOOL)isOpen;
- (BOOL)close;
- (BOOL)isClosed;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.ImConversation
 */
@interface ImConversation : Conversation {}
- (void)setTypingState:(TypingState *)typingState;
@end

@interface DirectimConversation : Conversation {}
- (void)setTypingState:(TypingState *)typingState;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.Message
 */
@interface MessageInfo : NSObject {}
- (Message *)getMessage;
@end

@interface ConversationEventInfo : NSObject {}
- (Screenname *)getFrom;
- (Screenname *)getTo;
@end

@interface SendFailedEvent : ConversationEventInfo {}
- (Message *)getMessage;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.ImSendFailedEvent
 */
@interface ImSendFailedEvent : SendFailedEvent {}
- (int)getErrorCode;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.TypingInfo
 */
@interface TypingInfo : ConversationEventInfo {}
- (TypingState *)getTypingState;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.IcbmService
 */
@protocol IcbmListener;
@interface IcbmService : Service {}
- (void)addIcbmListener:(id<IcbmListener>)listener;
- (ImConversation *)getImConversation:(Screenname *)sn;
- (DirectimConversation *)getDirectimConversation:(Screenname *)sn;
- (RvConnectionManager *)getRvConnectionManager;
- (void)sendAutomatically:(Screenname *)sn :(Message *)msg;
- (void)sendTypingAutomatically:(Screenname *)sn :(TypingState *)msg;
@end

#pragma mark Buddies and Groups

/*
 * net.kano.joustsim.oscar.oscar.service.ssi.Buddy
 */
@protocol BuddyListener;
@interface Buddy : NSObject {}
- (BOOL)isActive;
- (Screenname *)getScreenname;
- (NSString *)getAlias;
- (NSString *)getBuddyComment;
- (void)addBuddyListener:(id<BuddyListener>)listener;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.ssi.MutableBuddy
 */
@interface MutableBuddy : Buddy {}
- (void)changeAlias:(NSString *)alias;
- (void)changeBuddyComment:(NSString *)comment;
- (void)changeAlertEventMask:(int)alertEventMask;
- (void)changeAlertActionMask:(int)alertActionMask;
- (void)changeAlertSound:(NSString *)alertSound;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.ssi.Group
 */
@protocol GroupListener;
@interface Group : NSObject {}
- (NSString *)getName;
- (id<Collection>)getBuddiesCopy;
- (void)addGroupListener:(id<GroupListener>)listener;
@end

@interface MutableGroup : Group {}
- (void)rename:(NSString *)newName;
- (void)addBuddy:(NSString *)screenname;
//void copyBuddies(Collection<? extends Buddy> buddies);
- (void)deleteBuddy:(Buddy *)buddy;
//void deleteBuddies(List<Buddy> ingroup);
@end

@interface BuddyList : NSObject {}
//Returns a List
- (id<Collection>)getGroups;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.ssi.MutableBuddylist
 */
@interface MutableBuddyList : BuddyList {}
- (void)addGroup:(NSString *)groupName;
- (void)moveBuddies:(id <Collection>)buddies :(MutableGroup *)group;
- (void)deleteGroupAndBuddies:(Group *)group;
@end

/*
 * java.lang.Enum
 */
@interface Enum : NSObject {}
- (NSString *)name;
- (int)ordinal;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.ssi.PrivacyMode
 */
@interface PrivacyMode : Enum {}
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.TypingState
 */
@interface TypingState : Enum {}
@end

/*
 * net.kano.joustsim.oscar.oscar.service.ssi.PermissionList
 */
@protocol PermissionList
- (PrivacyMode *)getPrivacyMode;
//this set will only contain Screenname objects
- (NSObject <Set> *)getBlockedBuddies;
//this set will only contain Screenname objects
- (NSObject <Set> *)getAllowedBuddies;
//this set will only contain Screenname objects
- (NSObject <Set> *)getEffectiveBlockedBuddies;
//this set will only contain Screenname objects
- (NSObject <Set> *)getEffectiveAllowedBuddies;
- (void)addToBlockList:(Screenname *)sn;
- (void)addToAllowedList:(Screenname *)sn;
- (void)removeFromBlockList:(Screenname *)sn;
- (void)removeFromAllowedList:(Screenname *)sn;
- (void)setPrivacyMode:(PrivacyMode *)mode;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.ssi.PermissionList
 */
@interface PermissionList : NSObject <PermissionList> {}
@end




#pragma mark File transfer
@class FileSendBlock, InvitationMessage, TransferredFileInfo, ProgressStatusProvider;

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.ft.RvConnection
 */
@interface RvConnection : NSObject {}
- (BOOL)close;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.ft.RvSessionBasedConnection
 */
@interface RvSessionBasedConnection : RvConnection {}
@end

/*
 * abstract net.kano.joustsim.oscar.oscar.service.icbm.ft.FileTransfer
 */
@protocol EventListener;
@interface FileTransfer : RvSessionBasedConnection {}
- (FileSendBlock *)getRequestFileInfo;
- (InvitationMessage *)getInvitationMessage;
- (Screenname *)getBuddyScreenname;
- (void)addEventListener:(id<EventListener>)listener;
@end

@interface FileMapper : NSObject {}

@end

/*
 * net.adium.joscarBridge.JoscarFileMapper
 */
#define NewJoscarFileMapper(shouldUseIndicatedNames, path)	[NSClassFromString(@"net.adium.joscarBridge.JoscarFileMapper") \
															newWithSignature:@"(ZLjava/lang/String;)", \
															(shouldUseIndicatedNames), (path)]
@interface JoscarFileMapper : FileMapper {}
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.ft.IncomingFileTransfer
 */
@interface IncomingFileTransfer : FileTransfer {}
- (void)accept;
- (BOOL)isAccepted;
- (void)decline;
- (BOOL)isDeclined;

- (void)setFileMapper:(FileMapper *)mapper;
- (FileMapper *)getFileMapper;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.ft.OutgoingFileTransfer
 */
@interface OutgoingFileTransfer : FileTransfer {}
- (void)sendRequest:(InvitationMessage *)invitationMessage;
- (id<Collection>)getFiles;
- (void)addFilesInHierarchy:(NSString *)string :(File *)root :(id<Collection> /*File * */)list;
- (void)addFilesInFlatFolder:(NSString *)string :(id<Collection>)list;
- (void)addFile:(File *)file;
- (void)setSingleFile:(File *)file;
- (NSString *)getDisplayName;
- (void)setDisplayName:(NSString *)inDisplayName;
//public abstract java/util/Map getNameMappings();
//public abstract void mapName(java/io/File, java/lang/String);
//public abstract java/lang/String getMappedName(java/io/File);
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.ft.FileTransferManager
 */
@interface RvConnectionManager : NSObject {}
- (OutgoingFileTransfer *)createOutgoingFileTransfer:(Screenname *)sn;
@end

/*
 * net.kano.joscar.rvcmd.InvitationMessage
 */
#define NewInvitationMessage(msg)	[NSClassFromString(@"net.kano.joscar.rvcmd.InvitationMessage") \
										newWithSignature:@"(Ljava/lang/String;)", \
										(msg)]
@interface InvitationMessage : NSObject {}
@end

#pragma mark Group Chat
@protocol ChatInvitation
- (Screenname *)getScreenname;
- (int)getRoomExchange;
- (NSString *)getRoomName;
- (NSString *)getMessage;
	//InvalidInvitationReason getInvalidReason();
	//X509Certificate getBuddySignature();
- (BOOL)isValid;
- (BOOL)isForSecureChatRoom;
- (ChatRoomSession *)accept;
- (void)reject;
@end

/*
 * net/kano/joustsim/oscar/oscar/service/chatrooms/ChatRoomManagerListener
 */
@protocol ChatRoomManagerListener
- (void)handleInvitation:(ChatRoomManager *)manager :(id<ChatInvitation>)invite;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.chatrooms.ChatRoomManager
 */
@interface ChatRoomManager : NSObject {}
- (void)addListener:(id<ChatRoomManagerListener>)listener;
- (void)removeListener:(id<ChatRoomManagerListener>)listener;
//- (void)rejectInvitation:(ChatInvitationImpl *) inv;
//- (ChatRoomSession *)acceptInvitation(ChatInvitationImpl *)inv;
- (ChatRoomSession *)joinRoom:(NSString *)name;
- (ChatRoomSession *)joinRoom:(int)exchange :(NSString *)name;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.chatrooms.ChatRoomSession
 */
@interface ChatRoomSession : NSObject {}
- (void)addListener:(id<ChatRoomSessionListener>)listener;
- (void)removeListener:(id<ChatRoomSessionListener>)listener;
- (void)sendMessage:(NSString *)msg;
- (id<Set>)getUsers;
- (void)invite:(Screenname *)screenname :(NSString *)message;
- (FullRoomInfo *)getRoomInfo;
- (void)close;
@end

/*
 * net.kano.joscar.snaccmd.FullRoomInfo
 */
@interface FullRoomInfo : NSObject {}
- (NSString *)getRoomName;
- (int)getExchange;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.chatrooms.ChatRoomUser
 */
@interface ChatRoomUser : NSObject {}
- (Screenname *)getScreenname;
//- (FullUserInfo *)getInfo;
@end

/* 
 * net.kano.joustsim.oscar.oscar.service.chatrooms.ChatMessage
 */
@interface ChatMessage : NSObject {}
- (NSString *)getMessage;
@end

@interface Reason : NSObject {}
//getName returns one of @"TOO_FAST", @"TOO_LARGE", @"SENDER_WARNING_LEVEL", @"YOUR_WARNING_LEVEL"
- (NSString *)getName;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.MissedImInfo
 */
@interface MissedImInfo : NSObject {}
- (Screenname *)getFrom;
- (Screenname *)getTo;
- (int)getCount;
- (Reason *)getReason;
@end

#pragma mark File transfer

@interface FileSendBlock : NSObject {}
/**
 * Returns the "send type" code for this transfer. This will normally be
 * either SENDTYPE_SINGLEFILE (0x01) or SENDTYPE_DIR (0x02).
 */
- (int)getSendType;
/**
 * Returns the total number of files being sent.
 */
- (int)getFileCount;
/**
 * Returns the total cumulative file size, in bytes, of all files being
 * sent.
 */
- (long long)getTotalFileSize;
/**
 * Returns the name of the file being sent. Note that when sending an
 * entire directory of files, WinAIM sends something resembling
 * "directoryName\*" as the filename, indicating that the
 * transferred files should be placed in a new directory called
 * <code>directoryName</code>.
 *
 */
- (NSString *)getFilename;
@end

@interface RvConnectionState : NSObject {}
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.ft.events.RvConnectionEvent
 */
@interface RvConnectionEvent : NSObject {}
@end

@interface TransferredFileInfo : NSObject {}
/* Methods */
//public java/io/File getFile() {
- (long long)getFileSize;
- (long long)getResumedAt;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.ft.ProgressStatusProvider
 */
@interface ProgressStatusProvider : NSObject {}
- (long long)getStartPosition;
- (long long)getPosition;
- (long long)getLength;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.ft.events.TransferringFileEvent
 */
@interface TransferringFileEvent : RvConnectionEvent {}
- (TransferredFileInfo *)getFileInfo;
- (ProgressStatusProvider *)getProgressProvider;
@end

#pragma mark DirectIM
/*
 * net.kano.joustsim.oscar.oscar.service.icbm.dim.Attachment
 */
@interface Attachment : NSObject {}
- (NSString *)getId;
- (long long)getLength;
@end

/*
 * net.kano.joustsim.oscar.oscar.service.icbm.dim.FileAttachment
 */
#define NewFileAttachment(file, identifier, length)	[NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.icbm.dim.FileAttachment") \
													newWithSignature:@"(Ljava/io/File;Ljava/lang/String;J)", \
													(file), (identifier), (length)]
@interface FileAttachment : Attachment {}
- (File *)getFile;
@end

#pragma mark Misc. Joscar classes
@interface ByteBlock : NSObject {}
- (int)getLength;
@end

@interface JoscarTools : NSObject {}
+ (NSString *)getVersionString;
@end

#pragma mark Java classes
@protocol Collection
- (BOOL)add:(NSObject *)object;
- (BOOL)addAll:(id<Collection>)collection;
- (id<Iterator>)iterator;
@end

/*
 * java.util.HashMap
 */
@interface Map : NSObject
- (id)get:(id)key;

/*
 * Returns: previous value associated with specified key, or null if there was no mapping for key.
 * A null return can also indicate that the map previously associated null with the specified key, if the implementation
 * supports null values.
 */
- (id)put:(id)key :(id)value;
@end

/*
 * java.util.HashMap
 */
#define NewHashMap()	[[NSClassFromString(@"java.util.HashMap") alloc] init]
//#define NewSynchronizedHashMap()	[Collections synchronizedMap:NewHashMap()]
@interface HashMap : Map
@end

/*
 * java.util.HashSet
 */
#define NewHashSet(initialCapacity)	[NSClassFromString(@"java.util.HashSet") newWithSignature:@"(I)", \
									(initialCapacity)]
@interface HashSet : NSObject <Set> {}
@end

/*
 * java.util.ArrayList
 */
#define NewArrayList()		[[NSClassFromString(@"java.util.ArrayList") alloc] init]
@interface ArrayList : NSObject <Collection> {}
@end

/* java.lang.Object */
@interface NSObject (JavaObjectAdditions)
+ (id)getProperty:(NSString *)property;
- (NSString *)toString;
@end

/*
 * java.util.Date
 */
#define NewDate(timeInterval)	[NSClassFromString(@"java.util.Date") \
								newWithSignature:@"(J)", \
								(timeInterval)]
@interface Date : NSObject {}
@end

/*
 * java.util.Iterator
 */
@protocol Iterator
- (BOOL)hasNext;
- (id)next;
- (void)remove;
@end

/*
 * java.util.Set
 */
@protocol Set <Collection>
@end

/*
 * java.io.File
 */
#define NewFile(path)	[NSClassFromString(@"java.io.File") \
						newWithSignature:@"(Ljava/lang/String;)", \
						(path)]
@interface File : NSObject {}
- (NSString *)getCanonicalPath;
@end


#pragma mark Joscar Logging

/*
 * java.util.logging.Handler
 */
@interface Handler : NSObject {}
@end

@interface BridgeToAdiumHandler : Handler {}
- (void)setOutputDestination:(NSObject *)newDestination;
@end


#pragma mark Joscar Bridge
#define NewJoscarBridge(logLevel)	[NSClassFromString(@"net.adium.joscarBridge.joscarBridge") \
									newWithSignature:@"(I)", \
									(logLevel)]
@interface JoscarBridge : NSObject <GlobalBuddyInfoListener, StateListener, OpenedServiceListener,
									BuddyInfoTrackerListener, InfoServiceListener, EventListener, FileTransferListener,
									ChatRoomManagerListener, ChatRoomSessionListener,
									SecuridProvider>
{
}

- (void)setDelegate:(id)delegate;

- (ByteBlock *)byteBlockFromData:(NSData *)data;
- (NSData *)dataFromByteBlock:(ByteBlock *)byteBlock;

- (NSData *)dataFromAttachment:(Attachment *)attachment;

- (void)prepareOutgoingFileTransfer:(OutgoingFileTransfer *)fileTransfer;

- (TypingState *)typingStateFromString:(NSString *)string;

- (PrivacyMode *)privacyModeFromString:(NSString *)string;

- (BridgeToAdiumHandler *)getAdiumHandler;
@end

