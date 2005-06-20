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

#import "ESObjectWithStatus.h"
#import "AIContentTyping.h"

@class AIAccount, AIListObject, AIListContact, AIContentObject;
@protocol AIContainingObject;

#define Chat_WillClose							@"Chat_WillClose"
#define	Chat_Created							@"Chat_Created"
#define Chat_DidOpen							@"Chat_DidOpen"
#define Chat_AttributesChanged					@"Chat_AttributesChanged"
#define Chat_StatusChanged						@"Chat_StatusChagned"
#define Chat_ParticipatingListObjectsChanged	@"Chat_ParticipatingListObjectsChanged"
#define Chat_SourceChanged 						@"Chat_SourceChanged"
#define Chat_DestinationChanged 				@"Chat_DestinationChanged"

#define KEY_UNVIEWED_CONTENT	@"UnviewedContent"
#define KEY_TYPING				@"Typing"

#define	KEY_CHAT_TIMED_OUT		@"Timed Out"
#define KEY_CHAT_CLOSED_WINDOW	@"Closed Window"

typedef enum {
	AIChatTimedOut = 0,
	AIChatClosedWindow
} AIChatUpdateType;

#define KEY_ENCRYPTED_CHAT_PREFERENCE	@"Encrypted Chat Preference"
#define GROUP_ENCRYPTION				@"Encryption"

typedef enum {
	EncryptedChat_Default = -2, /* For use by a menu which wants to provide a 'no preference' option */
	EncryptedChat_Never = -1,
	EncryptedChat_Manually = 0, /* Manually is the default */
	EncryptedChat_Automatically = 1, 
	EncryptedChat_RejectUnencryptedMessages = 2
} AIEncryptedChatPreference;

//Chat errors should be indicated by setting a status object on this key 
//with an NSNumber of the appropriate error type as its object
#define	KEY_CHAT_ERROR			@"Chat Error"

//This key may be set before sending KEY_CHAT_ERROR to provide any data the
//the error message should make use of.  It may be of any type.
#define	KEY_CHAT_ERROR_DETAILS	@"Chat Error Details"

typedef enum {
	AIChatUnknownError = 0,
	AIChatMessageSendingUserIsBlocked,
	AIChatMessageSendingNotAllowedWhileInvisible,
	AIChatMessageSendingUserNotAvailable,
	AIChatMessageSendingTooLarge,
	AIChatMessageSendingTimeOutOccurred,
	AIChatMessageSendingConnectionError,
	AIChatMessageReceivingMissedTooLarge,
	AIChatMessageReceivingMissedInvalid,
	AIChatMessageReceivingMissedRateLimitExceeded,
	AIChatMessageReceivingMissedRemoteIsTooEvil,
	AIChatMessageReceivingMissedLocalIsTooEvil,
	AIChatCommandFailed,
	AIChatInvalidNumberOfArguments
} AIChatErrorType;

@interface AIChat : ESObjectWithStatus <AIContainingObject> {
    AIAccount			*account;
	NSDate				*dateOpened;
	BOOL				isOpen;
	
    NSMutableArray		*contentObjectArray;
    NSMutableArray		*participatingListObjects;
	AIListContact		*preferredListObject;
	NSString			*name;
	NSString			*uniqueChatID;
	
	NSMutableSet		*ignoredListContacts;
	
	BOOL				expanded;			//Exanded/Collapsed state of this object
	
	BOOL				enableTypingNotifications;
}

+ (id)chatForAccount:(AIAccount *)inAccount;

- (AIAccount *)account;
- (void)setAccount:(AIAccount *)inAccount;

- (NSDate *)dateOpened;
- (void)setDateOpened:(NSDate *)inDate;

- (BOOL)isOpen;
- (void)setIsOpen:(BOOL)flag;

- (NSArray *)participatingListObjects;
- (void)addParticipatingListObject:(AIListContact *)inObject;
- (void)removeParticipatingListObject:(AIListContact *)inObject;
- (AIListContact *)listObject;
- (void)setListObject:(AIListContact *)inObject;
- (AIListContact *)preferredListObject;
- (void)setPreferredListObject:(AIListContact *)inObject;
- (BOOL)inviteListContact:(AIListContact *)inObject withMessage:(NSString *)inviteMessage;

- (NSArray *)contentObjectArray;
- (BOOL)hasContent;
- (void)setContentArray:(NSArray *)inContentArray;
- (void)addContentObject:(AIContentObject *)inObject;
- (void)appendContentArray:(NSArray *)inContentArray;
- (void)removeAllContent;

- (NSString *)name;
- (void)setName:(NSString *)inName;

- (NSString *)uniqueChatID;

- (NSImage *)chatImage;
- (NSImage *)chatMenuImage;

- (void)setSecurityDetails:(NSDictionary *)securityDetails;
- (NSDictionary *)securityDetails;
- (BOOL)isSecure;
- (BOOL)supportsSecureMessagingToggling;

- (BOOL)canSendImages;

- (BOOL)isListContactIgnored:(AIListObject *)inContact;
- (void)setListContact:(AIListContact *)inContact isIgnored:(BOOL)isIgnored;

@end
