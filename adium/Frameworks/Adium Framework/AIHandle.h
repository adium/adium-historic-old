//
//  AIHandle.h
//  Adium
//
//  Created by Adam Iser on Fri Mar 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIListContact, AIAccount, AIMutableOwnerArray;
@protocol AIContentObject;

@interface AIHandle : NSObject {
    NSString		*UID;
    NSString		*serviceID;
    NSString		*serverGroup;
    AIAccount		*account;
    float		index;
    BOOL		temporary;

    AIListContact	*containingContact;

    NSMutableDictionary	*statusDictionary;
}

//Init
+ (id)handleWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary forAccount:(AIAccount *)inAccount;
- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary forAccount:(AIAccount *)inAccount;

//Identifying information
- (NSString *)UID;
- (NSString *)serviceID;
- (NSString *)serverGroup;

//Ownership
- (AIAccount *)account;
- (void)setContainingContact:(AIListContact *)inContact;
- (AIListContact *)containingContact;

//Status
- (NSMutableDictionary *)statusDictionary;

@end
