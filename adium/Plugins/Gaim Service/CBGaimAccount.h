//
//  CBGaimAccount.h
//  Adium
//
//  Created by Colin Barrett on Sun Oct 19 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#include "internal.h"

#include "connection.h"
#include "conversation.h"
#include "core.h"
#include "debug.h"
#include "ft.h"
#include "notify.h"
#include "plugin.h"
#include "pounce.h"
#include "prefs.h"
#include "privacy.h"
#include "proxy.h"
#include "request.h"
#include "signals.h"
#include "sslconn.h"
#include "sound.h"
#include "util.h"

@interface CBGaimAccount : AIAccount <AIAccount_Handles,AIAccount_Content>
{     
    NSMutableDictionary	*handleDict;
    NSMutableDictionary *chatDict;

    NSMutableArray      *filesToSendArray;
        
    GaimAccount         *account;
    GaimConnection      *gc;
}

- (const char*)protocolPlugin;
- (GaimAccount*)gaimAccount;

// accountConnection methods
- (void)accountConnectionReportDisconnect:(const char*)text;
- (void)accountConnectionConnected;
- (void)accountConnectionDisconnected;

//accountBlist methods
- (void)accountNewBuddy:(GaimBuddy*)buddy;
- (void)accountUpdateBuddy:(GaimBuddy*)buddy;
- (void)accountRemoveBuddy:(GaimBuddy*)buddy;

//accountConv methods
- (void)accountConvDestroy:(GaimConversation*)conv;
- (void)accountConvUpdated:(GaimConversation*)conv type:(GaimConvUpdateType)type;
- (void)accountConvReceivedIM:(const char*)message inConversation:(GaimConversation*)conv withFlags:(GaimMessageFlags)flags atTime:(time_t)mtime;

//accountXfer methods
- (void)accountXferRequestFileReceiveWithXfer:(GaimXfer *)xfer;
- (void)accountXferBeginFileSendWithXfer:(GaimXfer *)xfer;
- (void)accountXferUpdateProgress:(GaimXfer *)xfer percent:(float)percent;
- (void)accountXferCanceledRemotely:(GaimXfer *)xfer;

//AIAccount sublcassed methods
- (void)initAccount;
- (void)dealloc;
- (NSArray *)supportedPropertyKeys;
- (void)updateStatusForKey:(NSString *)key;
- (NSDictionary *)defaultProperties;
- (id <AIAccountViewController>)accountView;

//AIAccount_Handles
// Returns a dictionary of AIHandles available on this account
- (NSDictionary *)availableHandles; //return nil if no contacts/list available

// Returns YES if the list is editable
- (BOOL)contactListEditable;

// Add a handle to this account
- (AIHandle *)addHandleWithUID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary;
// Remove a handle from this account
- (BOOL)removeHandleWithUID:(NSString *)inUID;

// Add a group to this account
- (BOOL)addServerGroup:(NSString *)inGroup;
// Remove a group
- (BOOL)removeServerGroup:(NSString *)inGroup;
// Rename a group
- (BOOL)renameServerGroup:(NSString *)inGroup to:(NSString *)newName;

//AIAccount_Files
//Instructs the account to accept a file transfer request
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer;
//Instructs the account to reject a file receive request
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer;

//AIAccount_Privacy
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type;
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type;


//Connectivity
- (void)configureAccountProxy;

//Account status
- (NSArray *)supportedPropertyKeys;
- (void)updateAllStatusKeys;
- (void)updateStatusForKey:(NSString *)key;
- (void)setAccountIdleTo:(NSTimeInterval)idle;
- (void)setAccountAwayTo:(NSAttributedString *)awayMessage;
- (void)setAccountProfileTo:(NSAttributedString *)profile;
- (void)setAccountUserImage:(NSImage *)image;


@end
