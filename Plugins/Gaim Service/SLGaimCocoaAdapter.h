//
//  SLGaimCocoaAdapter.h
//  Adium
//  Adapts gaim to the Cocoa event loop.
//
//  Created by Scott Lamb on Sun Nov 2 2003.
//

/*!
 * @class SLGaimCocoaAdapter
 * Singleton to run libgaim from a Cocoa event loop.
 **/
@interface SLGaimCocoaAdapter : AIObject {

}

+ (SLGaimCocoaAdapter *)sharedInstance;
- (void)addAdiumAccount:(id)adiumAccount;
- (oneway void)sendEncodedMessage:(NSString *)encodedMessage
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
- (oneway void)xferRequest:(GaimXfer *)xfer;
- (oneway void)xferRequestAccepted:(GaimXfer *)xfer withFileName:(NSString *)xferFileName;
- (oneway void)xferRequestRejected:(GaimXfer *)xfer;
- (oneway void)getInfoFor:(NSString *)inUID onAccount:(id)adiumAccount;

- (oneway void)setAway:(NSString *)awayHTML onAccount:(id)adiumAccount;
- (oneway void)setInfo:(NSString *)profileHTML onAccount:(id)adiumAccount;
- (oneway void)setBuddyIcon:(NSString *)buddyImageFilename onAccount:(id)adiumAccount;
- (oneway void)setIdleSinceTo:(NSDate *)idleSince onAccount:(id)adiumAccount;

- (oneway void)setCheckMail:(NSNumber *)checkMail forAccount:(id)adiumAccount;

- (oneway void)MSNRequestBuddyIconFor:(NSString *)inUID onAccount:(id)adiumAccount;
- (oneway void)OSCAREditComment:(NSString *)comment forUID:(NSString *)inUID onAccount:(id)adiumAccount;

- (oneway void)doRequestInputCbValue:(NSValue *)callBackValue withUserDataValue:(NSValue *)userDataValue inputString:(NSString *)string;
- (oneway void)doRequestActionCbValue:(NSValue *)callBackValue withUserDataValue:(NSValue *)userDataValue callBackIndex:(NSNumber *)callBackIndexNumber;

- (void)displayFileSendError;
- (void *)handleNotifyMessageOfType:(GaimNotifyType)type withTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary;
- (void *)handleNotifyEmails:(size_t)count detailed:(BOOL)detailed subjects:(const char **)subjects froms:(const char **)froms tos:(const char **)tos urls:(const char **)urls;
- (NSString *)_processGaimImagesInString:(NSString *)inString forAdiumAccount:(id)adiumAccount;
@end
