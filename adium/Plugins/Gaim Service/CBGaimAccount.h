//
//  CBGaimAccount.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.

#import "GaimCommon.h"
#import "SLGaimCocoaAdapter.h"

@protocol AdiumGaimDO
- (oneway void)accountConnectionConnected;
- (oneway void)accountConnectionReportDisconnect:(NSString *)text;
- (oneway void)accountConnectionNotice:(const char*)text;
- (oneway void)accountConnectionDisconnected;
- (oneway void)accountConnectionProgressStep:(size_t)step of:(size_t)step_count withText:(const char *)text;

- (oneway void)newContact:(AIListContact *)theContact;
- (oneway void)updateContact:(AIListContact *)theContact toGroupName:(NSString *)groupName;
- (oneway void)updateContact:(AIListContact *)theContact;
- (oneway void)updateContact:(AIListContact *)theContact toAlias:(NSString *)gaimAlias;
- (oneway void)updateContact:(AIListContact *)theContact forEvent:(GaimBuddyEvent)event;
- (oneway void)updateSignon:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateSignoff:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateSignonTime:(AIListContact *)theContact withData:(NSDate *)signonDate;
- (oneway void)updateWentAway:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateAwayReturn:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateIdle:(AIListContact *)theContact withData:(NSDate *)idleSinceDate;
- (oneway void)updateEvil:(AIListContact *)theContact withData:(NSNumber *)evilNumber;
- (oneway void)updateIcon:(AIListContact *)theContact withData:(NSData *)userIconData;
- (oneway void)removeContact:(AIListContact *)theContact;

- (oneway void)destroyMultiChat:(AIChat *)chat;
- (oneway void)destroyIMChat:(AIChat *)chat;
- (oneway void)addChat:(AIChat *)chat;
- (oneway void)typingUpdateForIMChat:(AIChat *)chat typing:(BOOL)typing;
- (oneway void)updateForChat:(AIChat *)chat type:(GaimConvUpdateType)type;
- (oneway void)receivedIMChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat;
- (oneway void)receivedMultiChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat;
- (oneway void)addUser:(NSString *)contactName toChat:(AIChat *)chat;
- (oneway void)removeUser:(NSString *)contactName fromChat:(AIChat *)chat;

- (oneway void)accountPrivacyList:(PRIVACY_TYPE)type added:(NSString *)sourceUID;
- (oneway void)accountPrivacyList:(PRIVACY_TYPE)type removed:(NSString *)sourceUID;

- (oneway void)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer;
- (oneway void)updateProgressForFileTransfer:(ESFileTransfer *)fileTransfer percent:(float)percent bytesSent:(float)bytesSent;
- (oneway void)fileTransferCanceledRemotely:(ESFileTransfer *)fileTransfer;
- (oneway void)destroyFileTransfer:(ESFileTransfer *)fileTransfer;

- (AIChat *)chatWithName:(NSString *)name;

@end

@interface CBGaimAccount : AIAccount <AIAccount_List, AIAccount_Content, AIAccount_Privacy,AdiumGaimDO>
{     
    NSMutableDictionary *chatDict;

    NSMutableArray      *filesToSendArray;
        
	NSString			*lastDisconnectionError;
	
    GaimAccount         *account;
    GaimConnection      *gc;
    
    int                 reconnectAttemptsRemaining;
	
	BOOL				insideDealloc;
	
	NSMutableArray		*permittedContactsArray;
	NSMutableArray		*deniedContactsArray;
	
//	SLGaimCocoaAdapter	*gaimThread;
}

- (const char*)protocolPlugin;
- (GaimAccount*)gaimAccount;

- (void)initAccount;
- (void)initSSL;
- (void)createNewGaimAccount;   //This can be sublcassed to change settings for the gaim account, which is recreated with each connect cycle
- (void)dealloc;
- (NSArray *)supportedPropertyKeys;
- (void)updateStatusForKey:(NSString *)key;
- (NSDictionary *)defaultProperties;
- (NSString *)unknownGroupName;
- (NSArray *)contactStatusFlags;
- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError;
- (AIListContact *)_mainThreadContactWithUID:(NSString *)sourceUID;

	//AIAccount_Files
	//Instructs the account to accept a file transfer request
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer;
	//Instructs the account to reject a file receive request
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer;

//Private (for subclasses only) file transfer methods
- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)_beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer;

	//AIAccount_Privacy
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type;
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type;
-(NSArray *)listObjectsOnPrivacyList:(PRIVACY_TYPE)type;

	//Connectivity
- (void)connect;
- (void)configureAccountProxy;
- (void)disconnect;
- (NSString *)connectionStringForStep:(int)step;
- (void)configureGaimAccountForConnect;
- (NSString *)host;
- (NSString *)hostKey;
- (int)port;
- (NSString *)portKey;

	//Account status
- (NSArray *)supportedPropertyKeys;
- (void)updateAllStatusKeys;
- (void)updateStatusForKey:(NSString *)key;
- (void)setAccountUserImage:(NSImage *)image;
- (void)setAccountIdleTo:(NSTimeInterval)idle;
- (void)setAccountAwayTo:(NSAttributedString *)awayMessage;
- (void)setAccountProfileTo:(NSAttributedString *)profile;

#pragma mark Gaim callback handling methods
- (oneway void)accountConnectionConnected;
- (oneway void)accountConnectionReportDisconnect:(NSString *)text;
- (oneway void)accountConnectionNotice:(const char*)text;
- (oneway void)accountConnectionDisconnected;
- (oneway void)accountConnectionProgressStep:(size_t)step of:(size_t)step_count withText:(const char *)text;

- (oneway void)newContact:(AIListContact *)theContact;
- (oneway void)updateContact:(AIListContact *)theContact toGroupName:(NSString *)groupName;
- (oneway void)updateContact:(AIListContact *)theContact;
- (oneway void)updateContact:(AIListContact *)theContact toAlias:(NSString *)gaimAlias;
- (oneway void)updateContact:(AIListContact *)theContact forEvent:(GaimBuddyEvent)event;
- (oneway void)updateSignon:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateSignoff:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateSignonTime:(AIListContact *)theContact withData:(NSDate *)signonDate;
- (oneway void)updateWentAway:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateAwayReturn:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateIdle:(AIListContact *)theContact withData:(NSDate *)idleSinceDate;
- (oneway void)updateEvil:(AIListContact *)theContact withData:(NSNumber *)evilNumber;
- (oneway void)updateIcon:(AIListContact *)theContact withData:(NSData *)userIconData;
- (oneway void)removeContact:(AIListContact *)theContact;

- (oneway void)destroyMultiChat:(AIChat *)chat;
- (oneway void)destroyIMChat:(AIChat *)chat;
- (oneway void)addChat:(AIChat *)chat;
- (oneway void)typingUpdateForIMChat:(AIChat *)chat typing:(BOOL)typing;
- (oneway void)updateForChat:(AIChat *)chat type:(GaimConvUpdateType)type;
- (oneway void)receivedIMChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat;
- (oneway void)receivedMultiChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat;
- (oneway void)addUser:(NSString *)contactName toChat:(AIChat *)chat;
- (oneway void)removeUser:(NSString *)contactName fromChat:(AIChat *)chat;

- (oneway void)accountPrivacyList:(PRIVACY_TYPE)type added:(NSString *)sourceUID;
- (oneway void)accountPrivacyList:(PRIVACY_TYPE)type removed:(NSString *)sourceUID;

- (oneway void)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer;
- (oneway void)updateProgressForFileTransfer:(ESFileTransfer *)fileTransfer percent:(float)percent bytesSent:(float)bytesSent;
- (oneway void)fileTransferCanceledRemotely:(ESFileTransfer *)fileTransfer;
- (oneway void)destroyFileTransfer:(ESFileTransfer *)fileTransfer;

- (AIChat *)chatWithName:(NSString *)name;

@end
