/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

@class AIHandleIdentifier, AIMessageObject, AIListContact, AIHandle, AIChat, AIContentObject, AIListObject, ESFileTransfer, DCJoinChatWindowController;
@protocol AIServiceController;

#import "AIListObject.h"

#define GROUP_ACCOUNT_STATUS   @"Account Status"

#define NEW_ACCOUNT_DISPLAY_TEXT	NSLocalizedString(@"<New Account>",nil)

typedef enum {
    STATUS_NA = -1,
    STATUS_OFFLINE,
    STATUS_CONNECTING,
    STATUS_ONLINE,
    STATUS_DISCONNECTING
} ACCOUNT_STATUS;

typedef enum {
    PRIVACY_PERMIT = 0,
    PRIVACY_DENY
}  PRIVACY_TYPE;

//Support for file transfer
@protocol AIAccount_Files
    //Instructs the account to accept a file transfer request
    - (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer;

    //Instructs the account to reject a file receive request
    - (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer;

    //Instructs the account to initiate sending of a file
	- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer;
@end

//Support for privacy settings
@protocol AIAccount_Privacy
    //Add a list object to the privacy list (either PRIVACY_PERMIT or PRIVACY_DENY). Return value indicates success.
    -(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type;
    //Remove a list object from the privacy list (either PRIVACY_PERMIT or PRIVACY_DENY). Return value indicates success
    -(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type;

	//Return an array of AIListContacts on the specified privacy list.  Returns an empty array if no contacts are on the list.
	-(NSArray *)listObjectsOnPrivacyList:(PRIVACY_TYPE)type;
@end


/*!
 * @class AIAccount
 * @abstract An account of ours (one we connect to and use to talk to handles)
 * @discussion The base AIAccount class provides no practical functionality,
 * so almost all of the AIAccounts you deal with will be subclasses.  You will
 * almost never need to talk directly with an AIAccount.  For information on
 * accounts, check out 'working with accounts' and 'creating service code'.
 */
@interface AIAccount : AIListObject {
    NSString                    *password;
    BOOL                        silentAndDelayed;				//We are waiting for and processing our sign on updates
    BOOL						disconnectedByFastUserSwitch;	//We are offline because of a fast user switch
	int							accountNumber;					//Unique integer that represents this account
	
	//Auto-reconnect
	NSTimer						*reconnectTimer;

	//Attributed string refreshing
    NSTimer                     *attributedRefreshTimer;
    NSMutableArray				*autoRefreshingKeys;

	//Contact update guarding
	NSTimer						*delayedUpdateStatusTimer;
	AIListContact				*delayedUpdateStatusTarget;
	
	NSTimer						*silenceAllContactUpdatesTimer;
}

- (id)initWithUID:(NSString *)inUID accountNumber:(int)inAccountNumber service:(AIService *)inService;
- (int)accountNumber;

- (void)silenceAllContactUpdatesForInterval:(NSTimeInterval)interval;
- (void)autoReconnectAfterDelay:(int)delay;
- (void)autoReconnectAfterNumberDelay:(NSNumber *)delayNumber;

/*
 * @method properties
 * These properties are always applicable:
 *
 * Status          ACCOUNT_STATUS
 * Idle Since      NSDate
 *
 * And these are applicable only when Status is STATUS_ONLINE:
 *
 * Signon Date     NSDate
 * IdleSince       NSDate
 * StatusMessage   NSAttributedString
 * Away            boolean
 */

//Methods that should be subclassed
- (void)initAccount; 				//Init anything relating to the account

- (NSArray *)supportedPropertyKeys;		//Return an array of supported status keys
- (void)updateStatusForKey:(NSString *)key; //The account's status did change

- (NSAttributedString *)autoRefreshingOutgoingContentForStatusKey:(NSString *)key;
- (void)autoRefreshingOutgoingContentForStatusKey:(NSString *)key selector:(SEL)selector;

- (void)connect;
- (void)disconnect;

//Methods that might be subclassed
- (BOOL)requiresPassword;
- (BOOL)disconnectOnFastUserSwitch;
- (BOOL)shouldSendAutoresponsesWhileAway;
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject;
- (BOOL)inviteContact:(AIListContact *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage;
- (BOOL)createNewGroupChatWithListObject:(AIListObject *)contact;
- (BOOL)connectivityBasedOnNetworkReachability;

- (AIListContact *)_contactWithUID:(NSString *)sourceUID;
- (void)updateContactStatus:(AIListContact *)inContact;
- (void)delayedUpdateContactStatus:(AIListContact *)inContact;
- (float)delayedUpdateStatusInterval;


//Support for messaging --
//Send a message object to its destination
- (BOOL)sendContentObject:(AIContentObject *)object;
//Returns YES if the object is available for receiving content of the specified type.  Pass a nil object to check the account's ability to send any content of the given type.  Pass YES for absolute and the account will only return YES if it's absolutely certain that it can send content to the specified object.
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact;
//Open a chat instance
- (BOOL)openChat:(AIChat *)chat;
//Close a chat instance
- (BOOL)closeChat:(AIChat *)chat;

//Support for standard UID based contacts --
- (void)removeContacts:(NSArray *)objects;
- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)group;
- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group;
- (void)renameGroup:(AIListGroup *)group to:(NSString *)newName;
- (BOOL)contactListEditable;

@end

