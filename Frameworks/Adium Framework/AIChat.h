//
//  AIChat.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.

#import "ESObjectWithStatus.h"

@class AIAccount, AIContentObject;
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


//Chat errors should be indicated by setting a status object on this key 
//with an NSNumber of the appropriate error type as its object
#define	KEY_CHAT_ERROR			@"Chat Error"

//This key may be set before sending KEY_CHAT_ERROR to provide any data the
//the error message should make use of.  It may be of any type.
#define	KEY_CHAT_ERROR_DETAILS	@"Chat Error Details"

typedef enum {
	AIChatUnknownError = 0,
	AIChatUserNotAvailable,
	AIChatMessageSendingTooLarge,
	AIChatMessageReceivingMissedTooLarge,
	AIChatMessageReceivingMissedInvalid,
	AIChatMessageReceivingMissedRateLimitExceeded,
	AIChatMessageReceivingMissedRemoteIsTooEvil,
	AIChatMessageReceivingMissedLocalIsTooEvil
} AIChatErrorType;

@interface AIChat : ESObjectWithStatus <AIContainingObject> {
    AIAccount			*account;
	NSDate				*dateOpened;
	BOOL				isOpen;
	
    NSMutableArray		*contentObjectArray;
    NSMutableArray		*participatingListObjects;
	AIListObject		*preferredListObject;
	NSString			*name;
	NSString			*uniqueChatID;
	
	BOOL				expanded;			//Exanded/Collapsed state of this object
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

@end
