//
//  AIChat.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIAccount, AIContentObject, AIListObject, AIAdium;

@interface AIChat : NSObject {
    AIAdium		*owner;
    AIAccount		*account;
    NSMutableDictionary *statusDictionary;
    NSMutableArray	*contentObjectArray;
    NSMutableArray	*participatingListObjects;
}

+ (id)chatWithOwner:(id)inOwner forAccount:(AIAccount *)inAccount;
- (NSMutableDictionary *)statusDictionary;
- (AIAccount *)account;

- (NSArray *)participatingListObjects;
- (void)addParticipatingListObject:(AIListObject *)inObject;
- (void)removeParticipatingListObject:(AIListObject *)inObject;
- (AIListObject *)listObject;

- (NSArray *)contentObjectArray;
- (void)setContentArray:(NSArray *)inContentArray;
- (void)addContentObject:(AIContentObject *)inObject;
- (void)appendContentArray:(NSArray *)inContent;
- (void)removeAllContent;


@end
