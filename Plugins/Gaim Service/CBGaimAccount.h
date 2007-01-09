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

#import <Adium/AIAccount.h>
#import "GaimCommon.h"

@protocol AIAccount_Privacy;
@class SLGaimCocoaAdapter, ESFileTransfer, AIService, AIContentMessage, AIStatus, AIWindowController;

@interface CBGaimAccount : AIAccount <AIAccount_Privacy>
{   	
    GaimAccount         *account;

	NSMutableDictionary	*customEmoticonWaitingDict;

	NSString			*lastDisconnectionError;
    int                 reconnectAttemptsRemaining;
	
	NSMutableArray		*permittedContactsArray;
	NSMutableArray		*deniedContactsArray;	
}

- (const char*)protocolPlugin;
- (GaimAccount*)gaimAccount;
- (const char *)gaimAccountName;

- (void)createNewGaimAccount;

- (void)dealloc;
- (NSSet *)supportedPropertyKeys;
- (void)updateStatusForKey:(NSString *)key;
- (NSDictionary *)defaultProperties;
- (NSString *)unknownGroupName;
- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString **)disconnectionError;
- (BOOL)useDisplayNameAsStatusMessage;
- (AIService *)_serviceForUID:(NSString *)contactUID;

/* CBGaimAccount odes not implement AIAccount_Files; however, all subclasses which do use the same code.
	The superclass therefore has the code and declares the methods here. */
	//Instructs the account to accept a file transfer request
- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer;
	//Instructs the account to reject a file receive request
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer;
	//Instructs the account to cancel a file transfer in progress
- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer;

	//Private (for subclasses only) file transfer methods
- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)_beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer;

	//AIAccount_Privacy
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(AIPrivacyType)type;
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(AIPrivacyType)type;
-(NSArray *)listObjectsOnPrivacyList:(AIPrivacyType)type;

	//Connectivity
- (void)connect;
- (void)configureAccountProxyNotifyingTarget:(id)target selector:(SEL)selector;
- (void)disconnect;
- (NSString *)connectionStringForStep:(int)step;
- (void)configureGaimAccount;

//Account status
- (NSSet *)supportedPropertyKeys;
- (void)updateStatusForKey:(NSString *)key;
- (void)setAccountUserImageData:(NSData *)originalData;
- (void)setAccountIdleSinceTo:(NSDate *)idleSince;

- (void)setStatusState:(AIStatus *)statusState statusID:(const char *)statusID isActive:(NSNumber *)isActive arguments:(NSMutableDictionary *)arguments;
- (const char *)gaimStatusIDForStatus:(AIStatus *)statusState
							arguments:(NSMutableDictionary *)arguments;

- (void)setAccountProfileTo:(NSAttributedString *)profile;

- (BOOL)shouldSetAliasesServerside;

- (SLGaimCocoaAdapter *)gaimThread;

#pragma mark Gaim callback handling methods
- (void)accountConnectionConnected;
- (void)accountConnectionReportDisconnect:(NSString *)text;
- (void)accountConnectionNotice:(NSString *)text;
- (void)accountConnectionDisconnected;
- (void)accountConnectionProgressStep:(NSNumber *)step percentDone:(NSNumber *)connectionProgressPrecent;

- (void)newContact:(AIListContact *)theContact withName:(NSString *)inName;
- (void)updateContact:(AIListContact *)theContact
				 toGroupName:(NSString *)groupName
				 contactName:(NSString *)contactName;
- (void)updateContact:(AIListContact *)theContact toAlias:(NSString *)gaimAlias;
- (void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event;
- (void)updateSignon:(AIListContact *)theContact withData:(void *)data;
- (void)updateSignoff:(AIListContact *)theContact withData:(void *)data;
- (void)updateSignonTime:(AIListContact *)theContact withData:(NSDate *)signonDate;
- (void)updateStatusForContact:(AIListContact *)theContact
				  toStatusType:(NSNumber *)statusTypeNumber
					statusName:(NSString *)statusName 
				 statusMessage:(NSAttributedString *)statusMessage;
- (NSString *)statusNameForGaimBuddy:(GaimBuddy *)b;
- (NSAttributedString *)statusMessageForGaimBuddy:(GaimBuddy *)b;
- (void)updateEvil:(AIListContact *)theContact withData:(NSNumber *)evilNumber;
- (void)updateIcon:(AIListContact *)theContact withData:(NSData *)userIconData;

- (void)removeContact:(AIListContact *)theContact;

- (void)addChat:(AIChat *)chat;
- (void)typingUpdateForIMChat:(AIChat *)chat typing:(NSNumber *)typing;
- (void)updateForChat:(AIChat *)chat type:(NSNumber *)type;
- (void)receivedIMChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat;
- (void)receivedMultiChatMessage:(NSDictionary *)messageDict inChat:(AIChat *)chat;
- (void)removeUser:(NSString *)contactName fromChat:(AIChat *)chat;

- (void)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer;
- (void)updateProgressForFileTransfer:(ESFileTransfer *)fileTransfer 
									 percent:(NSNumber *)percent
								   bytesSent:(NSNumber *)bytesSent;
- (void)fileTransferCancelledRemotely:(ESFileTransfer *)fileTransfer;
- (void)fileTransferCancelledLocally:(ESFileTransfer *)fileTransfer;
- (void)destroyFileTransfer:(ESFileTransfer *)fileTransfer;
- (ESFileTransfer *)newFileTransferObjectWith:(NSString *)destinationUID
										 size:(unsigned long long)inSize
							   remoteFilename:(NSString *)remoteFilename;

- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject;
- (BOOL)canSendFolders;

- (AIChat *)chatWithContact:(AIListContact *)contact;
- (AIChat *)chatWithName:(NSString *)name;
- (void)requestAddContactWithUID:(NSString *)contactUID;

- (void)gotGroupForContact:(AIListContact *)contact;

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString 
					   forStatusState:(AIStatus *)statusState;
- (BOOL)inviteContact:(AIListContact *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage;

- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact;
- (NSString *)titleForAccountActionMenuLabel:(const char *)label;

- (NSString *)_UIDForAddingObject:(AIListContact *)object;

#pragma mark Contacts
- (void)renameContact:(AIListContact *)theContact toUID:(NSString *)newUID;
- (void)updateWentIdle:(AIListContact *)theContact withData:(NSDate *)idleSinceDate;
- (void)updateIdleReturn:(AIListContact *)theContact withData:(void *)data;
- (void)updateUserInfo:(AIListContact *)theContact withData:(GaimNotifyUserInfo *)user_info;

#pragma mark Chats
- (void)errorForChat:(AIChat *)chat type:(NSNumber *)type;
- (void)removeUsersArray:(NSArray *)usersArray fromChat:(AIChat *)chat;
- (void)updateTopic:(NSString *)inTopic forChat:(AIChat *)chat;
- (void)updateTitle:(NSString *)inTitle forChat:(AIChat *)chat;
- (void)convUpdateForChat:(AIChat *)chat type:(NSNumber *)type;
- (void)addUsersArray:(NSArray *)usersArray
			withFlags:(NSArray *)flagsArray
		   andAliases:(NSArray *)aliasesArray 
		  newArrivals:(NSNumber *)newArrivals
			   toChat:(AIChat *)chat;

#pragma mark Emoticons
- (void)chat:(AIChat *)inChat isWaitingOnCustomEmoticon:(NSString *)isWaiting;
- (void)chat:(AIChat *)inChat setCustomEmoticon:(NSString *)emoticonEquivalent withImageData:(NSData *)inImageData;
- (void)chat:(AIChat *)inChat closedCustomEmoticon:(NSString *)inEmoticon;

@end
