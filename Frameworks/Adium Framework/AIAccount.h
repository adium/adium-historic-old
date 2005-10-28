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

#import "AIListObject.h"

@class AIListContact, AIChat, AIContentObject, ESFileTransfer, AIStatus;

#define GROUP_ACCOUNT_STATUS   @"Account Status"

//Connect host and port keys
#define KEY_CONNECT_HOST 			@"Connect Host"
#define KEY_CONNECT_PORT 			@"Connect Port"
#define KEY_ACCOUNT_CHECK_MAIL		@"Check Mail"
#define KEY_ENABLED					@"Enabled"

#define	Adium_RequestImmediateDynamicContentUpdate	@"Adium_RequestImmediateDynamicContentUpdate"

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

typedef enum {
    PRIVACY_ALLOW_ALL = 1,      //Anyone can conctact you
	PRIVACY_DENY_ALL,           //Nobody can contact you
	PRIVACY_ALLOW_USERS,        //Only those on your allow list can contact you
	PRIVACY_DENY_USERS,         //Those on your deny list can't contact you
	PRIVACY_ALLOW_CONTACTLIST   //Only those on your contact list can contact you
} PRIVACY_OPTION;

//Support for file transfer
@protocol AIAccount_Files
	//can the account send entire folders on its own?
	- (BOOL)canSendFolders;

    //Instructs the account to accept a file transfer request
    - (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer;

    //Instructs the account to reject a file receive request
    - (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer;

    //Instructs the account to initiate sending of a file
	- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer;

	//Instructs the account to cancel a filet ransfer in progress
	- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer;
@end

//Support for privacy settings
@protocol AIAccount_Privacy
    //Add a list object to the privacy list (either PRIVACY_PERMIT or PRIVACY_DENY). Return value indicates success.
    -(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type;
    //Remove a list object from the privacy list (either PRIVACY_PERMIT or PRIVACY_DENY). Return value indicates success
    -(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type;
	//Return an array of AIListContacts on the specified privacy list.  Returns an empty array if no contacts are on the list.
	-(NSArray *)listObjectsOnPrivacyList:(PRIVACY_TYPE)type;
	//Identical to the above method, except it returns an array of strings, not list objects
	-(NSArray *)listObjectIDsOnPrivacyList:(PRIVACY_TYPE)type;
    //Set the privacy options
    -(void)setPrivacyOptions:(PRIVACY_OPTION)option;
	//Get the privacy options
	-(PRIVACY_OPTION)privacyOptions;
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
	int							accountNumber;					//Unique integer that represents this account
	
    NSString                    *password;
    BOOL                        silentAndDelayed;				//We are waiting for and processing our sign on updates
    BOOL						disconnectedByFastUserSwitch;	//We are offline because of a fast user switch
	BOOL						namesAreCaseSensitive;
	
	//Auto-reconnect
	NSTimer						*reconnectTimer;
	
	//Attributed string refreshing
    NSTimer                     *attributedRefreshTimer;
    NSMutableSet				*autoRefreshingKeys;
	NSMutableSet				*dynamicKeys;
	
	//Contact update guarding
	NSTimer						*delayedUpdateStatusTimer;
	AIListContact				*delayedUpdateStatusTarget;
	NSTimer						*silenceAllContactUpdatesTimer;
}

- (void)initAccount;
- (void)connect;
- (void)disconnect;
- (void)performRegisterWithPassword:(NSString *)inPassword;
- (NSString *)accountWillSetUID:(NSString *)proposedUID;
- (void)didChangeUID;
- (void)willBeDeleted;

//Properties
- (BOOL)requiresPassword;
- (BOOL)shouldSendAutoresponsesWhileAway;
- (BOOL)disconnectOnFastUserSwitch;
- (BOOL)connectivityBasedOnNetworkReachability;
- (BOOL)suppressTypingNotificationChangesAfterSend;

//Status
- (NSSet *)supportedPropertyKeys;
- (id)statusForKey:(NSString *)key;
- (void)updateStatusForKey:(NSString *)key;
- (void)delayedUpdateContactStatus:(AIListContact *)inContact;
- (float)delayedUpdateStatusInterval;
- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage;

//Messaging, Chatting, Strings
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact;
- (BOOL)openChat:(AIChat *)chat;
- (BOOL)closeChat:(AIChat *)chat;
- (BOOL)inviteContact:(AIListObject *)contact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage;
- (BOOL)joinGroupChatNamed:(NSString *)name;
- (BOOL)sendContentObject:(AIContentObject *)object;
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject;

//Presence Tracking
- (BOOL)contactListEditable;
- (void)addContacts:(NSArray *)objects toGroup:(AIListGroup *)group;
- (void)removeContacts:(NSArray *)objects;
- (void)deleteGroup:(AIListGroup *)group;
- (void)moveListObjects:(NSArray *)objects toGroup:(AIListGroup *)group;
- (void)renameGroup:(AIListGroup *)group to:(NSString *)newName;

//Contact-specific menu items
- (NSArray *)menuItemsForContact:(AIListContact *)inContact;

//Account-specific menu items
- (NSArray *)accountActionMenuItems;

//Secure messaging
- (BOOL)allowSecureMessagingTogglingForChat:(AIChat *)inChat;
- (NSString *)aboutEncryption;
- (void)requestSecureMessaging:(BOOL)inSecureMessaging
						inChat:(AIChat *)inChat;

- (BOOL)canSendImagesForChat:(AIChat *)inChat;

@end

#import "AIAbstractAccount.h"
