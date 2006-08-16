//
//  ESjoscarCocoaAdapter.h
//  Adium
//
//  Created by Evan Schoenberg on 6/28/05.
//

#import <Cocoa/Cocoa.h>
#import "AIContentTyping.h"
//for AIPrivacyOption
#import "AIAccount.h"

@class RAFjoscarAccount, DefaultAppSession, AimConnection, JoscarBridge, NSJavaVirtualMachine;
@protocol Set,ChatRoomManagerListener,ChatInvitation,SecuridProvider;

@interface ESjoscarCocoaAdapter : AIObject <SecuridProvider> {
	JoscarBridge			*joscarBridge;

	RAFjoscarAccount		*account;
	RAFjoscarAccount		*accountProxy; //Sends messages to account on the main thread
	
	DefaultAppSession		*appSession;
	AimConnection			*aimConnection; //current aimConnection

	NSMutableDictionary		*pendingBuddyAddDict;
	NSMutableDictionary		*pendingBuddyMoveDict;

	NSMutableDictionary		*joscarChatsDict;	
	
	NSMutableDictionary		*fileTransferPollingTimersDict;
	
	NSTimer					*buddyAddTimer;
	
	ESjoscarCocoaAdapter	*selfProxy; //Sends messages to self on the main thread
}

+ (void)initializeJavaVM;
- (id)initForAccount:(RAFjoscarAccount *)inAccount;

- (void)connectWithPassword:(NSString *)password proxyConfiguration:(NSDictionary *)proxyConfiguration host:(NSString *)host port:(int)port;
- (void)disconnect;

- (NSString *)processOutgoingMessage:(NSString *)message /*toUID:(NSString *)inUID*/ joscarData:(id *)outJoscarData;
- (NSString *)processIncomingDirectMessage:(NSString *)message joscarData:(id)directMessage;
- (void)leaveChatWithUID:(NSString *)inUID;
- (BOOL)chatWithUID:(NSString *)inUID sendMessage:(NSString *)message isAutoreply:(BOOL)isAutoreply joscarData:(NSSet *)attachmentsSet;
- (void)chatWithUID:(NSString *)inUID setTypingState:(AITypingState)typingState;

- (void)addContactsWithUIDs:(NSArray *)UIDs toGroup:(NSString *)groupName;
- (void)removeContactsWithUIDs:(NSArray *)UIDs;
- (void)moveContactsWithUIDs:(NSArray *)UIDs toGroup:(NSString *)groupName;
- (void)requestAuthorizationForContactWithUID:(NSString *)UID;

- (void)requestInfoForContactWithUID:(NSString *)UID;
- (void)setAlias:(NSString *)inAlias forContactWithUID:(NSString *)UID;
- (void)setNotes:(NSString *)inNotes forContactWithUID:(NSString *)UID;

- (void)setUserProfile:(NSString *)profile;
- (void)setMessageAway:(NSString *)away;
- (void)setIdleSince:(NSDate *)idleSince;
- (void)setUnidle;

- (void)acceptIncomingFileTransferWithIdentifier:(NSValue *)identifier destinationPath:(NSString *)localPath;
- (void)rejectIncomingFileTransferWithIdentifier:(NSValue *)identifier;
- (void)cancelFileTransferWithIdentifier:(NSValue *)identifier;
- (NSValue *)initiateOutgoingFileTransferForUID:(NSString *)UID
									   forFiles:(NSArray *)pathArray;

- (void)setVisibleStatus:(BOOL)visible;
- (void)setStatusMessage:(NSString *)msg withSongURL:(NSString *)itmsURL;
- (void)setAccountUserIconData:(NSData *)data;

- (NSArray *)getBlockedBuddies;
- (AIPrivacyOption)privacyMode;
- (NSArray *)getAllowedBuddies;
- (NSObject <Set> *)getEffectiveBlockedBuddies;
- (NSObject <Set> *)getEffectiveAllowedBuddies;
- (void)addToBlockList:(NSString *)sn;
- (void)addToAllowedList:(NSString *)sn;
- (void)removeFromBlockList:(NSString *)sn;
- (void)removeFromAllowedList:(NSString *)sn;
- (void)setPrivacyMode:(AIPrivacyOption)mode;

- (AIChat *)handleChatInvitation:(id<ChatInvitation>)invite withDecision:(BOOL)decision;
- (void)leaveGroupChatWithName:(NSString *)name;
- (void)groupChatWithName:(NSString *)name sendMessage:(NSString *)message isAutoReply:(BOOL)isAutoReply;
- (void)joinChatRoom:(NSString *)name;
- (void)inviteUser:(NSString *)inUID toChat:(NSString *)chatName withMessage:(NSString *)inviteMessage;

- (void)setDisplayRecentBuddies:(BOOL)inDisplayRecentBuddies;
@end
