//
//  AIHandle.m
//  Adium
//
//  Created by Adam Iser on Fri Mar 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIHandle.h"
#import <Adium/Adium.h>

@implementation AIHandle

//Init
+ (id)handleWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary forAccount:(AIAccount *)inAccount
{
    return([[[self alloc] initWithServiceID:inServiceID UID:inUID serverGroup:inGroup temporary:inTemporary forAccount:inAccount] autorelease]);    
}

- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID serverGroup:(NSString *)inGroup temporary:(BOOL)inTemporary forAccount:(AIAccount *)inAccount
{
    [super init];

    //Retain our information
    UID = [inUID retain];
    serviceID = [inServiceID retain];

    UIDAndServiceID = [[NSString stringWithFormat:@"%@.%@",serviceID,UID] retain];
    
    serverGroup = [inGroup retain];
    account = [inAccount retain];
    temporary = inTemporary;
    
    containingContact = nil;

    statusDictionary = [[NSMutableDictionary alloc] init];
    
    return(self);
}

- (void)dealloc
{
    [UID release];
    [serviceID release];
    [serverGroup release];
    [account release];
    [UIDAndServiceID release];

    [super dealloc];
}



//Identifying information
- (NSString *)UID
{
    return(UID);
}
- (NSString *)serviceID
{
    return(serviceID);
}
- (NSString *)UIDAndServiceID //ServiceID.UID
{
    return(UIDAndServiceID);
}
- (NSString *)serverGroup
{
    return(serverGroup);
}
- (BOOL)temporary
{
    return(temporary);
}

//Ownership
- (AIAccount *)account
{
    return(account);
}

- (void)setContainingContact:(AIListContact *)inContact
{
    [containingContact release]; containingContact = nil;

    if(inContact != nil){
        containingContact = [inContact retain];
    }
}
- (AIListContact *)containingContact
{
    return(containingContact);
}


//Status
- (NSMutableDictionary *)statusDictionary
{
    return(statusDictionary);
}

@end
