//
//  AIChat.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.

@class AIAccount, AIContentObject, AIListObject;

@interface AIChat : AIObject {
    AIAccount			*account;
    NSMutableDictionary *statusDictionary;
    NSMutableArray		*contentObjectArray;
    NSMutableArray		*participatingListObjects;
	NSString			*name;
}

+ (id)chatForAccount:(AIAccount *)inAccount initialStatusDictionary:(NSDictionary *)inDictionary;
- (NSMutableDictionary *)statusDictionary;
- (AIAccount *)account;
- (void)setAccount:(AIAccount *)inAccount;

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

- (NSString *)name;
- (void)setName:(NSString *)inName;

@end
