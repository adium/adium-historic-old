//
//  AIChat.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.

@class AIAccount, AIContentObject, AIListObject, ESObjectWithStatus;

#define Chat_WillClose							@"Chat_WillClose"
#define	Chat_Created							@"Chat_Created"
#define Chat_DidOpen							@"Chat_DidOpen"
#define Chat_AttributesChanged					@"Chat_AttributesChanged"
#define Chat_StatusChanged						@"Chat_StatusChagned"
#define Chat_ParticipatingListObjectsChanged	@"Chat_ParticipatingListObjectsChanged"
#define Chat_AccountChanged 					@"Chat_AccountChanged"

#define KEY_UNVIEWED_CONTENT	@"UnviewedContent"
#define KEY_TYPING				@"Typing"

@interface AIChat : ESObjectWithStatus {
    AIAccount			*account;
	NSDate				*dateOpened;
	BOOL				isOpen;
	
    NSMutableArray		*contentObjectArray;
    NSMutableArray		*participatingListObjects;
	AIListObject		*preferredListObject;
	NSString			*name;
	NSString			*uniqueChatID;
	
	NSImage				*_serviceImage; 	//Cache of the default service image for our contact
	NSImage				*_cachedImage;		//Cache of our big image, so we can know easily when it changes
	NSImage				*_cachedMiniImage; 	//Cache of our mini image, so we only need to render it once
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

+ (NSString *)uniqueChatIDForChatWithName:(NSString *)name onAccount:(AIAccount *)account;
- (NSString *)name;
- (void)setName:(NSString *)inName;

- (NSString *)uniqueChatID;

- (NSImage *)chatImage;
- (NSImage *)chatMenuImage;

@end
