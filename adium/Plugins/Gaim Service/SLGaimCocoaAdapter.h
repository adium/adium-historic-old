//
//  SLGaimCocoaAdapter.h
//  Adium
//  Adapts gaim to the Cocoa event loop.
//
//  Created by Scott Lamb on Sun Nov 2 2003.
//


@protocol GaimThread
- (void)addAdiumAccount:(id)adiumAccount;
- (oneway void)sendMessage:(NSString *)encodedMessage fromAccount:(id)sourceAccount inChat:(AIChat *)chat withFlags:(int)flags;
- (oneway void)sendTyping:(BOOL)typing inChat:(AIChat *)chat;
- (oneway void)addUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName;
- (oneway void)removeUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:groupName;
- (oneway void)moveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName;
- (oneway void)renameGroup:(NSString *)oldGroupName onAccount:(id)adiumAccount to:(NSString *)newGroupName;

- (oneway void)setAlias:(NSString *)alias forUID:(NSString *)UID onAccount:(id)adiumAccount;

- (oneway void)openChat:(AIChat *)chat onAccount:(id)adiumAccount;
- (oneway void)closeChat:(AIChat *)chat;
- (void)connectAccount:(id)adiumAccount;
- (void)disconnectAccount:(id)adiumAccount;
- (oneway void)xferRequest:(GaimXfer *)xfer;
- (oneway void)xferRequestAccepted:(GaimXfer *)xfer withFileName:(NSString *)xferFileName;
- (oneway void)xferRequestRejected:(GaimXfer *)xfer;

- (oneway void)setAway:(NSString *)awayHTML onAccount:(id)adiumAccount;
- (oneway void)setInfo:(NSString *)profileHTML onAccount:(id)adiumAccount;
- (oneway void)setBuddyIcon:(NSString *)buddyImageFilename onAccount:(id)adiumAccount;
- (oneway void)setIdleSinceTo:(NSDate *)idleSince onAccount:(id)adiumAccount;

- (oneway void)setCheckMail:(NSNumber *)checkMail forAccount:(id)adiumAccount;

- (oneway void)getInfoFor:(NSString *)inUID onAccount:(id)adiumAccount;

- (oneway void)MSNRequestBuddyIconFor:(NSString *)inUID onAccount:(id)adiumAccount;
- (oneway void)OSCAREditComment:(NSString *)comment forUID:(NSString *)inUID onAccount:(id)adiumAccount;
@end

/*!
 * @class SLGaimCocoaAdapter
 * Singleton to run libgaim from a Cocoa event loop.
 * You just need to do one <tt>[[SLGaimCocoaAdapter alloc] init]</tt>
 * where you initialize the gaim core and gaim will be its events
 * from Cocoa.
 **/
@interface SLGaimCocoaAdapter : AIObject<GaimThread> {

}

+ (SLGaimCocoaAdapter *)sharedInstance;
- (void)addAdiumAccount:(id)adiumAccount;
- (oneway void)sendMessage:(NSString *)encodedMessage fromAccount:(id)sourceAccount inChat:(AIChat *)chat withFlags:(int)flags;
- (oneway void)sendTyping:(BOOL)typing inChat:(AIChat *)chat;
- (oneway void)addUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName;
- (oneway void)removeUID:(NSString *)objectUID onAccount:(id)adiumAccount fromGroup:groupName;
- (oneway void)moveUID:(NSString *)objectUID onAccount:(id)adiumAccount toGroup:(NSString *)groupName;
- (oneway void)renameGroup:(NSString *)oldGroupName onAccount:(id)adiumAccount to:(NSString *)newGroupName;

- (oneway void)setAlias:(NSString *)alias forUID:(NSString *)UID onAccount:(id)adiumAccount;

- (oneway void)openChat:(AIChat *)chat onAccount:(id)adiumAccount;
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

- (void *)handleNotifyMessageOfType:(GaimNotifyType)type withTitle:(const char *)title primary:(const char *)primary secondary:(const char *)secondary;
- (void *)handleNotifyEmails:(size_t)count detailed:(BOOL)detailed subjects:(const char **)subjects froms:(const char **)froms tos:(const char **)tos urls:(const char **)urls;
- (NSString *)_processGaimImagesInString:(NSString *)inString forAdiumAccount:(id)adiumAccount;
@end
