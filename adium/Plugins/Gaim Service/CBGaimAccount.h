//
//  CBGaimAccount.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.

#import "GaimCommon.h"
#import "SLGaimCocoaAdapter.h"

@protocol AdiumGaimDO

- (GaimAccount*)gaimAccount;

- (ESFileTransfer *)newFileTransferObjectWith:(NSString *)destinationUID;

- (AIListContact *)mainThreadContactWithUID:(NSString *)inUID;
- (AIChat *)chatWithName:(NSString *)name;
- (AIChat *)chatWithContact:(AIListContact *)contact;
- (oneway void)requestAddContactWithUID:(NSString *)contactUID;

- (NSString *)uniqueObjectID;
@end

@interface CBGaimAccount : AIAccount <AIAccount_List, AIAccount_Content, AIAccount_Privacy,AdiumGaimDO>
{     
    NSMutableDictionary *chatDict;

    NSMutableArray      *filesToSendArray;
        
	NSString			*lastDisconnectionError;
	
    GaimAccount         *account;
    
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
- (void)configureGaimAccount;
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
- (oneway void)accountConnectionNotice:(NSString *)text;
- (oneway void)accountConnectionDisconnected;
- (oneway void)accountConnectionProgressStep:(NSNumber *)step percentDone:(NSNumber *)connectionProgressPrecent;

- (oneway void)newContact:(AIListContact *)theContact;
- (oneway void)updateContact:(AIListContact *)theContact toGroupName:(NSString *)groupName;
- (oneway void)updateContact:(AIListContact *)theContact toAlias:(NSString *)gaimAlias;
- (oneway void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event;
- (oneway void)updateSignon:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateSignoff:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateSignonTime:(AIListContact *)theContact withData:(NSDate *)signonDate;
- (oneway void)updateWentAway:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateAwayReturn:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateIdle:(AIListContact *)theContact withData:(NSDate *)idleSinceDate;
- (oneway void)updateEvil:(AIListContact *)theContact withData:(NSNumber *)evilNumber;
- (oneway void)updateIcon:(AIListContact *)theContact withData:(NSData *)userIconData;
- (oneway void)removeContact:(AIListContact *)theContact;

- (oneway void)addChat:(AIChat *)chat;
- (oneway void)typingUpdateForIMChat:(AIChat *)chat typing:(NSNumber *)typing;
- (oneway void)updateForChat:(AIChat *)chat type:(NSNumber *)type;
- (oneway void)receivedIMChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat;
- (oneway void)receivedMultiChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat;
- (oneway void)addUser:(NSString *)contactName toChat:(AIChat *)chat;
- (oneway void)removeUser:(NSString *)contactName fromChat:(AIChat *)chat;

- (oneway void)accountPrivacyList:(PRIVACY_TYPE)type added:(NSString *)sourceUID;
- (oneway void)accountPrivacyList:(PRIVACY_TYPE)type removed:(NSString *)sourceUID;

- (ESFileTransfer *)newFileTransferObjectWith:(NSString *)destinationUID;
- (oneway void)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer;
- (oneway void)updateProgressForFileTransfer:(ESFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent;
- (oneway void)fileTransferCanceledRemotely:(ESFileTransfer *)fileTransfer;
- (oneway void)destroyFileTransfer:(ESFileTransfer *)fileTransfer;
- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject;

- (AIListContact *)_contactWithUID:(NSString *)inUID;
- (AIListContact *)mainThreadContactWithUID:(NSString *)inUID;
- (AIChat *)chatWithName:(NSString *)name;
- (AIChat *)chatWithContact:(AIListContact *)contact;
- (oneway void)requestAddContactWithUID:(NSString *)contactUID;

- (void)gotGroupForContact:(AIListContact *)contact;
- (void)preferencesChanged:(NSNotification *)notification;

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject contentMessage:(AIContentMessage *)contentMessage;
@end
