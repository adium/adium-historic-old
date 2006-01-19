/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#include <Libgaim/libgaim.h>
#import <Adium/AIContentTyping.h>
#import "GaimCommon.h"
#import "CBGaimAccount.h"

#define	ENABLE_WEBCAM	FALSE

@class AIChat, AIListContact, CBGaimAccount, NDRunLoopMessenger;

/*!
 * @class SLGaimCocoaAdapter
 * Singleton to run libgaim from a Cocoa event loop.
 **/
@interface SLGaimCocoaAdapter : AIObject {

}

+ (void)prepareSharedInstance;
+ (SLGaimCocoaAdapter *)sharedInstance;
+ (NDRunLoopMessenger *)gaimThreadMessenger;

- (void)addAdiumAccount:(CBGaimAccount *)adiumAccount;
- (void)removeAdiumAccount:(CBGaimAccount *)adiumAccount;
- (void)sendEncodedMessage:(NSString *)encodedMessage
			   fromAccount:(id)sourceAccount
					inChat:(AIChat *)chat
				 withFlags:(GaimMessageFlags)flags;
- (BOOL)attemptGaimCommandOnMessage:(NSString *)originalMessage
						fromAccount:(AIAccount *)sourceAccount 
							 inChat:(AIChat *)chat;

- (void)sendTyping:(AITypingState)typingState inChat:(AIChat *)chat;

- (void)addUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName;
- (void)removeUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:(NSString *)groupName;
- (void)moveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName;
- (void)renameGroup:(NSString *)oldGroupName onAccount:(id)adiumAccount to:(NSString *)newGroupName;
- (void)deleteGroup:(NSString *)groupName onAccount:(id)adiumAccount;

- (void)setAlias:(NSString *)alias forUID:(NSString *)UID onAccount:(id)adiumAccount;

- (void)openChat:(AIChat *)chat onAccount:(id)adiumAccount;
- (void)inviteContact:(AIListContact *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage;

- (void)closeChat:(AIChat *)chat;
- (void)disconnectAccount:(id)adiumAccount;
- (void)registerAccount:(id)adiumAccount;
- (void)xferRequest:(GaimXfer *)xfer;
- (void)xferRequestAccepted:(GaimXfer *)xfer withFileName:(NSString *)xferFileName;
- (void)xferRequestRejected:(GaimXfer *)xfer;
- (void)xferCancel:(GaimXfer *)xfer;
- (void)getInfoFor:(NSString *)inUID onAccount:(id)adiumAccount;

- (void)setStatusID:(const char *)statusID isActive:(NSNumber *)isActive arguments:(NSMutableDictionary *)arguments onAccount:(id)adiumAccount;
- (void)setInfo:(NSString *)profileHTML onAccount:(id)adiumAccount;
- (void)setBuddyIcon:(NSString *)buddyImageFilename onAccount:(id)adiumAccount;
- (void)setIdleSinceTo:(NSDate *)idleSince onAccount:(id)adiumAccount;

- (void)setCheckMail:(NSNumber *)checkMail forAccount:(id)adiumAccount;
- (void)setDefaultPermitDenyForAccount:(id)adiumAccount;

- (void)OSCAREditComment:(NSString *)comment forUID:(NSString *)inUID onAccount:(id)adiumAccount;
- (void)OSCARSetFormatTo:(NSString *)inFormattedUID onAccount:(id)adiumAccount;

- (void)displayFileSendError;
- (void *)handleNotifyMessageOfType:(GaimNotifyType)type withTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary;
- (void *)handleNotifyFormattedWithTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary text:(const char *)text;

- (void)performContactMenuActionFromDict:(NSDictionary *)dict;
- (void)performAccountMenuActionFromDict:(NSDictionary *)dict;

- (void)doAuthRequestCbValue:(NSValue *)inCallBackValue
		   withUserDataValue:(NSValue *)inUserDataValue 
		 callBackIndexNumber:(NSNumber *)inIndexNumber
			 isInputCallback:(NSNumber *)isInputCallback;

@end

//Lookup functions
void *adium_gaim_get_handle(void);
GaimConversation *existingConvLookupFromChat(AIChat *chat);
GaimConversation *convLookupFromChat(AIChat *chat, id adiumAccount);
AIChat *imChatLookupFromConv(GaimConversation *conv);
AIChat *existingChatLookupFromConv(GaimConversation *conv);
AIChat *chatLookupFromConv(GaimConversation *conv);
AIListContact *contactLookupFromIMConv(GaimConversation *conv);
AIListContact *contactLookupFromBuddy(GaimBuddy *buddy);
GaimAccount *accountLookupFromAdiumAccount(CBGaimAccount *adiumAccount);
CBGaimAccount *accountLookup(GaimAccount *acct);
NSMutableDictionary *get_chatDict(void);
