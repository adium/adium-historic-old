//
//  AIListContact.h
//  Adium
//
//  Created by Adam Iser on Fri Mar 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIListObject.h"

@class AIHandle;
@protocol AIContentObject;

@interface AIListContact : AIListObject {
    NSMutableArray	*contentObjectArray;
    NSMutableDictionary	*statusDictionary;
    NSMutableArray	*handleArray;

    NSString		*serviceID;
//    int			index;
}

- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID;
- (NSString *)serviceID;

//Contained Handles
//- (unsigned)handleCount;
//- (id)handleAtIndex:(unsigned)index;
- (NSEnumerator *)handleEnumerator;
- (void)addHandle:(AIHandle *)inHandle;
- (void)removeHandle:(AIHandle *)inHandle;

//Content
- (NSArray *)contentObjectArray;
- (void)addContentObject:(id <AIContentObject>)inObject;

//Status
- (AIMutableOwnerArray *)statusArrayForKey:(NSString *)inKey;

/*- (int)index;
- (void)setIndex:(int)inIndex;*/

@end
