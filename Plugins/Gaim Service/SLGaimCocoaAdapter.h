//
//  SLGaimCocoaAdapter.h
//  Adium
//  Adapts gaim to the Cocoa event loop.
//
//  Created by Scott Lamb on Sun Nov 2 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#include <Libgaim/libgaim.h>
#import "GaimCommon.h"
#import "CBGaimAccount.h"

#define	ENABLE_WEBCAM	TRUE

@class AIChat, AIListContact, CBGaimAccount, NDRunLoopMessenger;

/*!
 * @class SLGaimCocoaAdapter
 * Singleton to run libgaim from a Cocoa event loop.
 **/
@interface SLGaimCocoaAdapter : AIObject {

}

+ (SLGaimCocoaAdapter *)sharedInstance;
+ (NDRunLoopMessenger *)gaimThreadMessenger;

- (void)addAdiumAccount:(id)adiumAccount;
- (BOOL)sendEncodedMessage:(NSString *)encodedMessage
		   originalMessage:(NSString *)originalMessage 
			   fromAccount:(id)sourceAccount
					inChat:(AIChat *)chat
				 withFlags:(int)flags;

- (oneway void)sendTyping:(AITypingState)typingState inChat:(AIChat *)chat;

- (oneway void)addUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName;
- (oneway void)removeUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:groupName;
- (oneway void)moveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName;
- (oneway void)renameGroup:(NSString *)oldGroupName onAccount:(id)adiumAccount to:(NSString *)newGroupName;
- (oneway void)deleteGroup:(NSString *)groupName onAccount:(id)adiumAccount;

- (oneway void)setAlias:(NSString *)alias forUID:(NSString *)UID onAccount:(id)adiumAccount;

- (oneway void)openChat:(AIChat *)chat onAccount:(id)adiumAccount;
- (oneway void)inviteContact:(AIListContact *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage;

- (oneway void)closeChat:(AIChat *)chat;
- (void)connectAccount:(id)adiumAccount;
- (void)disconnectAccount:(id)adiumAccount;
- (void)registerAccount:(id)adiumAccount;
- (oneway void)xferRequest:(GaimXfer *)xfer;
- (oneway void)xferRequestAccepted:(GaimXfer *)xfer withFileName:(NSString *)xferFileName;
- (oneway void)xferRequestRejected:(GaimXfer *)xfer;
- (oneway void)xferCancel:(GaimXfer *)xfer;
- (oneway void)getInfoFor:(NSString *)inUID onAccount:(id)adiumAccount;

- (oneway void)setGaimStatusType:(const char *)gaimStatusType withMessage:(NSString *)message onAccount:(id)adiumAccount;
- (oneway void)setInvisible:(BOOL)isInvisible onAccount:(id)adiumAccount;
- (oneway void)setInfo:(NSString *)profileHTML onAccount:(id)adiumAccount;
- (oneway void)setBuddyIcon:(NSString *)buddyImageFilename onAccount:(id)adiumAccount;
- (oneway void)setIdleSinceTo:(NSDate *)idleSince onAccount:(id)adiumAccount;

- (oneway void)setCheckMail:(NSNumber *)checkMail forAccount:(id)adiumAccount;

- (oneway void)OSCAREditComment:(NSString *)comment forUID:(NSString *)inUID onAccount:(id)adiumAccount;
- (oneway void)OSCARSetFormatTo:(NSString *)inFormattedUID onAccount:(id)adiumAccount;
- (oneway void)OSCARSetAvailableMessageTo:(NSString *)availablePlaintext onAccount:(id)adiumAccount;

- (void)displayFileSendError;
- (void *)handleNotifyMessageOfType:(GaimNotifyType)type withTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary;

- (oneway void)performContactMenuActionFromDict:(NSDictionary *)dict;

- (oneway void)requestSecureMessaging:(BOOL)inSecureMessaging
							   inChat:(AIChat *)inChat;
- (void)gaimConversation:(GaimConversation *)conv setSecurityDetails:(NSDictionary *)securityDetailsDict;
- (void)refreshedSecurityOfGaimConversation:(GaimConversation *)conv;
- (NSString *)localizedOTRMessage:(NSString *)msg withUsername:(const char *)username;

@end

//Lookup functions
void* adium_gaim_get_handle(void);
GaimConversation* existingConvLookupFromChat(AIChat *chat);
GaimConversation* convLookupFromChat(AIChat *chat, id adiumAccount);
AIChat* imChatLookupFromConv(GaimConversation *conv);
AIChat* existingChatLookupFromConv(GaimConversation *conv);
AIChat* chatLookupFromConv(GaimConversation *conv);
AIListContact* contactLookupFromIMConv(GaimConversation *conv);
AIListContact* contactLookupFromBuddy(GaimBuddy *buddy);
GaimAccount* accountLookupFromAdiumAccount(CBGaimAccount *adiumAccount);
CBGaimAccount* accountLookup(GaimAccount *acct);
NSMutableDictionary* get_chatDict(void);