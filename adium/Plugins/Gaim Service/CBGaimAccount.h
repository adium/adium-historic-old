//
//  CBGaimAccount.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.

#import "GaimCommon.h"

@interface CBGaimAccount : AIAccount <AIAccount_List, AIAccount_Content>
{     
//    NSMutableDictionary	*handleDict;
    NSMutableDictionary *chatDict;

    NSMutableArray      *filesToSendArray;
        
    GaimAccount         *account;
    GaimConnection      *gc;
    
    int                 reconnectAttemptsRemaining;
}

- (const char*)protocolPlugin;
- (GaimAccount*)gaimAccount;

//accountBlist methods
- (void)accountNewBuddy:(GaimBuddy*)buddy;
- (void)accountUpdateBuddy:(GaimBuddy*)buddy;
- (void)accountUpdateBuddy:(GaimBuddy*)buddy forEvent:(GaimBuddyEvent)event;
- (void)accountRemoveBuddy:(GaimBuddy*)buddy;

//accountConv methods
- (void)accountConvDestroy:(GaimConversation*)conv;
- (void)accountConvUpdated:(GaimConversation*)conv type:(GaimConvUpdateType)type;
- (void)accountConvReceivedIM:(const char*)message inConversation:(GaimConversation*)conv withFlags:(GaimMessageFlags)flags atTime:(time_t)mtime;

//accountXfer methods
- (void)accountXferRequestFileReceiveWithXfer:(GaimXfer *)xfer;
- (void)accountXferUpdateProgress:(GaimXfer *)xfer percent:(float)percent;
- (void)accountXferCanceledRemotely:(GaimXfer *)xfer;

//AIAccount sublcassed methods
- (void)initAccount;
- (void)createNewGaimAccount;   //This can be sublcassed to change settings for the gaim account, which is recreated with each connect cycle
- (void)dealloc;
- (NSArray *)supportedPropertyKeys;
- (void)updateStatusForKey:(NSString *)key;
- (NSDictionary *)defaultProperties;
- (NSString *)unknownGroupName;
- (id <AIAccountViewController>)accountView;
- (NSArray *)contactStatusFlags;

//AIAccount_Handles
// Returns a dictionary of AIHandles available on this account
//- (NSDictionary *)availableHandles; //return nil if no contacts/list available
//
//// Returns YES if the list is editable
//- (BOOL)contactListEditable;
//
// Add a handle to this account
//- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary;
//// Remove a handle from this account
//- (BOOL)removeHandleWithUID:(NSString *)inUID;
//
//// Add a group to this account
//- (BOOL)addServerGroup:(NSString *)inGroup;
//// Remove a group
//- (BOOL)removeServerGroup:(NSString *)inGroup;
//// Rename a group
//- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName;

//AIAccount_Files
//Instructs the account to accept a file transfer request
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer;
//Instructs the account to reject a file receive request
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer;

//AIAccount_Privacy
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type;
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type;


//Connectivity
- (void)connect;
- (void)configureAccountProxy;
- (void)disconnect;
- (void)accountConnectionNotice:(const char*)text;
- (void)accountConnectionReportDisconnect:(const char*)text;
- (void)accountConnectionDisconnected;
- (void)accountConnectionConnected;
- (void)resetLibGaimAccount;

//Account status
- (NSArray *)supportedPropertyKeys;
- (void)updateAllStatusKeys;
- (void)updateStatusForKey:(NSString *)key;
- (void)setAccountUserImage:(NSImage *)image;
- (void)setAccountIdleTo:(NSTimeInterval)idle;
- (void)setAccountAwayTo:(NSAttributedString *)awayMessage;
- (void)setAccountProfileTo:(NSAttributedString *)profile;

@end
