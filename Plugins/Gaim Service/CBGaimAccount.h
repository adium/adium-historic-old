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

#import "GaimCommon.h"
#import <Adium/AIAccount.h>

@protocol AIAccount_Privacy;
@class SLGaimCocoaAdapter, ESFileTransfer, AIService, AIContentMessage, AIStatus;

@interface CBGaimAccount : AIAccount <AIAccount_Privacy>
{     
    NSMutableDictionary *chatDict;

    NSMutableArray      *filesToSendArray;
        
	NSString			*lastDisconnectionError;
	
    GaimAccount         *account;
    
    int                 reconnectAttemptsRemaining;
	
	NSMutableArray		*permittedContactsArray;
	NSMutableArray		*deniedContactsArray;
	
	BOOL				inDealloc;
	
	NSMutableDictionary	*shouldDisplayDict;
}

- (const char*)protocolPlugin;
- (GaimAccount*)gaimAccount;

- (void)initAccount;
- (void)initSSL;
- (void)createNewGaimAccount;   //This can be sublcassed to change settings for the gaim account, which is recreated with each connect cycle
- (void)dealloc;
- (NSSet *)supportedPropertyKeys;
- (void)updateStatusForKey:(NSString *)key;
- (NSDictionary *)defaultProperties;
- (NSString *)unknownGroupName;
- (NSArray *)contactStatusFlags;
- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError;
- (BOOL)useDisplayNameAsStatusMessage;
- (BOOL)displayConversationClosed;
- (BOOL)displayConversationTimedOut;
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
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type;
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type;
-(NSArray *)listObjectsOnPrivacyList:(PRIVACY_TYPE)type;

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

- (char *)gaimStatusTypeForStatus:(AIStatus *)statusState
						  message:(NSAttributedString **)statusMessage;
- (void)setStatusState:(AIStatus *)statusState
	withGaimStatusType:(const char *)gaimStatusType 
			andMessage:(NSString *)statusMessage;


- (void)setAccountProfileTo:(NSAttributedString *)profile;

- (BOOL)shouldSetAliasesServerside;

- (SLGaimCocoaAdapter *)gaimThread;

#pragma mark Gaim callback handling methods
- (oneway void)accountConnectionConnected;
- (oneway void)accountConnectionReportDisconnect:(NSString *)text;
- (oneway void)accountConnectionNotice:(NSString *)text;
- (oneway void)accountConnectionDisconnected;
- (oneway void)accountConnectionProgressStep:(NSNumber *)step percentDone:(NSNumber *)connectionProgressPrecent;

- (oneway void)newContact:(AIListContact *)theContact withName:(NSString *)inName;
- (oneway void)updateContact:(AIListContact *)theContact toGroupName:(NSString *)groupName contactName:(NSString *)contactName;
- (oneway void)updateContact:(AIListContact *)theContact toAlias:(NSString *)gaimAlias;
- (oneway void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event;
- (oneway void)updateSignon:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateSignoff:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateSignonTime:(AIListContact *)theContact withData:(NSDate *)signonDate;
- (oneway void)updateWentAway:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateAwayReturn:(AIListContact *)theContact withData:(void *)data;
- (oneway void)updateEvil:(AIListContact *)theContact withData:(NSNumber *)evilNumber;
- (oneway void)updateIcon:(AIListContact *)theContact withData:(NSData *)userIconData;
- (oneway void)updateUserInfo:(AIListContact *)theContact withData:(NSString *)userInfoString;

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

- (oneway void)requestReceiveOfFileTransfer:(ESFileTransfer *)fileTransfer;
- (oneway void)updateProgressForFileTransfer:(ESFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent;
- (oneway void)fileTransferCanceledRemotely:(ESFileTransfer *)fileTransfer;
- (oneway void)destroyFileTransfer:(ESFileTransfer *)fileTransfer;
- (ESFileTransfer *)newFileTransferObjectWith:(NSString *)destinationUID
										 size:(unsigned long long)inSize
							   remoteFilename:(NSString *)remoteFilename;

- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject;

- (AIListContact *)mainThreadContactWithUID:(NSString *)inUID;
- (AIChat *)mainThreadChatWithContact:(AIListContact *)contact;
- (AIChat *)mainThreadChatWithName:(NSString *)name;
- (oneway void)requestAddContactWithUID:(NSString *)contactUID;

- (void)gotGroupForContact:(AIListContact *)contact;

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject contentMessage:(AIContentMessage *)contentMessage;
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forGaimStatusType:(const char *)gaimStatusType;
- (BOOL)inviteContact:(AIListContact *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage;

- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact;
- (NSString *)titleForAccountActionMenuLabel:(const char *)label;

- (NSString *)_UIDForAddingObject:(AIListContact *)object;

- (void)_updateAwayOfContact:(AIListContact *)theContact toAway:(BOOL)newAway;

@end
