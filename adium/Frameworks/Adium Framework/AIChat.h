//
//  AIChat.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.

@class AIAccount, AIContentObject, AIListObject;

@interface AIChat : AIObject {
    AIAccount			*account;
    NSMutableDictionary *statusDictionary;
	NSDate				*dateOpened;
	
    NSMutableArray		*contentObjectArray;
    NSMutableArray		*participatingListObjects;
	AIListObject		*preferredListObject;
	NSString			*name;
	NSString			*uniqueChatID;
	
	NSImage				*_serviceImage; 	//Cache of the default service image for our contact
	NSImage				*_cachedImage;		//Cache of our big image, so we can know easily when it changes
	NSImage				*_cachedMiniImage; 	//Cache of our mini image, so we only need to render it once
}

+ (id)chatForAccount:(AIAccount *)inAccount initialStatusDictionary:(NSDictionary *)inDictionary;
- (NSMutableDictionary *)statusDictionary;
- (AIAccount *)account;
- (void)setAccount:(AIAccount *)inAccount;

- (NSDate *)dateOpened;
- (void)setDateOpened:(NSDate *)inDate;

- (NSArray *)participatingListObjects;
- (void)addParticipatingListObject:(AIListObject *)inObject;
- (BOOL)inviteListObject:(AIListObject *)inObject;
- (void)removeParticipatingListObject:(AIListObject *)inObject;
- (AIListObject *)listObject;
- (AIListObject *)preferredListObject;
- (void)setPreferredListObject:(AIListObject *)inObject;

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
