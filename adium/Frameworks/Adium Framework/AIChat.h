//
//  AIChat.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIAccount, AIContentObject, AIListObject;

@interface AIChat : AIObject {
    AIAccount		*account;
    NSMutableDictionary *statusDictionary;
    NSMutableArray	*contentObjectArray;
    NSMutableArray	*participatingListObjects;
}

+ (id)chatForAccount:(AIAccount *)inAccount;
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
- (void)appendContentArray:(NSArray *)inContent;
- (void)removeAllContent;


@end
