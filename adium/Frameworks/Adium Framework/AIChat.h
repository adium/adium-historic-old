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

	NSString			*name;
}

+ (id)chatForAccount:(AIAccount *)inAccount initialStatusDictionary:(NSDictionary *)inDictionary;
- (NSMutableDictionary *)statusDictionary;
- (AIAccount *)account;
- (void)setAccount:(AIAccount *)inAccount;

- (NSDate *)dateOpened;
- (void)setDateOpened:(NSDate *)inDate;

- (NSArray *)participatingListObjects;
- (void)addParticipatingListObject:(AIListObject *)inObject;
- (void)removeParticipatingListObject:(AIListObject *)inObject;
- (AIListObject *)listObject;

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
@end
