//
//  CBGaimAccount.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.

#import "GaimCommon.h"

@interface CBGaimAccount : AIAccount <AIAccount_List, AIAccount_Content, AIAccount_Privacy>
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
}

- (const char*)protocolPlugin;
- (GaimAccount*)gaimAccount;

	//AIAccount sublcassed methods
- (void)initAccount;
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

	//AIAccount_Privacy
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type;
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type;
-(NSArray *)listObjectsOnPrivacyList:(PRIVACY_TYPE)type;

	//Connectivity
- (void)connect;
- (void)configureAccountProxy;
- (void)disconnect;
- (NSString *)connectionStringForStep:(int)step;
- (void)resetLibGaimAccount;
- (NSString *)host;
- (int)port;
- (NSString *)hostKey;
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

	//accountConnection
- (void)accountConnectionNotice:(const char*)text;
- (void)accountConnectionReportDisconnect:(const char*)text;
- (void)accountConnectionDisconnected;
- (void)accountConnectionConnected;
- (void)accountConnectionProgressStep:(size_t)step of:(size_t)step_count withText:(const char *)text;

	//accountBlist
- (void)accountNewBuddy:(GaimBuddy*)buddy;
- (void)accountUpdateBuddy:(GaimBuddy*)buddy;
- (void)accountUpdateBuddy:(GaimBuddy*)buddy forEvent:(GaimBuddyEvent)event;
- (void)accountRemoveBuddy:(GaimBuddy*)buddy;

	//accountConv
- (void)accountConvDestroy:(GaimConversation*)conv;
- (void)accountConvUpdated:(GaimConversation*)conv type:(GaimConvUpdateType)type;
- (void)accountConvReceivedIM:(const char*)message inConversation:(GaimConversation*)conv withFlags:(GaimMessageFlags)flags atTime:(time_t)mtime;
- (void)accountConvReceivedChatMessage:(const char*)message inConversation:(GaimConversation*)conv from:(const char *)source withFlags:(GaimMessageFlags)flags atTime:(time_t)mtime;
- (void)accountConvAddedUser:(const char *)user inConversation:(GaimConversation *)conv;
- (void)accountConvAddedUsers:(GList *)users inConversation:(GaimConversation *)conv;
- (void)accountConvRemovedUser:(const char *)user inConversation:(GaimConversation *)conv;
- (void)accountConvRemovedUsers:(GList *)users inConversation:(GaimConversation *)conv;

	//accountXfer
- (void)accountXferRequestFileReceiveWithXfer:(GaimXfer *)xfer;
- (void)accountXferUpdateProgress:(GaimXfer *)xfer percent:(float)percent;
- (void)accountXferCanceledRemotely:(GaimXfer *)xfer;
- (void)accountXferDestroy:(GaimXfer *)xfer;

	//accountPrivacy
-(void)accountPrivacyList:(PRIVACY_TYPE)type added:(const char *)name;
-(void)accountPrivacyList:(PRIVACY_TYPE)type removed:(const char *)name;


@end
