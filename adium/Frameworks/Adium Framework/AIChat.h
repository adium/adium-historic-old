//
//  AIChat.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIAccount, AIContentObject, AIListObject;

@interface AIChat : NSObject {
    AIAccount		*account;
    AIListObject	*object;
    NSMutableDictionary *statusDictionary;
    NSMutableArray	*contentObjectArray;
}

+ (id)chatForAccount:(AIAccount *)inAccount object:(AIListObject *)inObject;
- (NSMutableDictionary *)statusDictionary;
- (AIAccount *)account;
- (AIListObject *)object;

- (NSArray *)contentObjectArray;
- (void)addContentObject:(AIContentObject *)inObject;
- (void)appendContentArray:(NSArray *)inContent;

@end
