//
//  AIChat.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIChat.h"

@interface AIChat (PRIVATE)
- (id)initForAccount:(AIAccount *)inAccount;
@end

@implementation AIChat

+ (id)chatForAccount:(AIAccount *)inAccount
{
    return([[[self alloc] initForAccount:inAccount] autorelease]);
}

- (id)initForAccount:(AIAccount *)inAccount
{
    [super init];

    account = [inAccount retain];
    statusDictionary = [[NSMutableDictionary alloc] init];
    contentObjectArray = [[NSMutableArray alloc] init];
    participatingListObjects = [[NSMutableArray alloc] init];
    
    return(self);
}

- (void)dealloc
{
    [account release];
    [statusDictionary release];
    [contentObjectArray release];
    [participatingListObjects release];
    
    [super dealloc];
}
    
- (AIAccount *)account
{
    return(account);
}

//Status -------------------------------------------------------------------------------------
//Status
- (NSMutableDictionary *)statusDictionary
{
    return(statusDictionary);
}


//Users --------------------------------------------------------------------------------------
- (NSArray *)participatingListObjects
{
    return(participatingListObjects);
}

- (void)addParticipatingListObject:(AIListObject *)inObject
{
    [participatingListObjects addObject:inObject]; //Add
    [[adium notificationCenter] postNotificationName:Content_ChatParticipatingListObjectsChanged object:self]; //Notify
}

//
- (void)removeParticipatingListObject:(AIListObject *)inObject
{
    [participatingListObjects removeObject:inObject]; //Remove
    [[adium notificationCenter] postNotificationName:Content_ChatParticipatingListObjectsChanged object:self]; //Notify
}

//If this chat only has one participating list object, it is returned.  Otherwise, nil is returned
- (AIListObject *)listObject
{
    if([participatingListObjects count] == 1){
        return([participatingListObjects objectAtIndex:0]);
    }else{
        return(nil);
    }
}


//Content ------------------------------------------------------------------------------------
//Return our array of content objects
- (NSArray *)contentObjectArray
{
    return(contentObjectArray);
}

- (void)setContentArray:(NSArray *)inContentArray
{
    if((NSArray *)contentObjectArray != inContentArray){
        [contentObjectArray release];
        contentObjectArray = [inContentArray mutableCopy];
    }
}

//Add a message object to this handle
- (void)addContentObject:(AIContentObject *)inObject
{
    //Add the object
    [contentObjectArray insertObject:inObject atIndex:0];
}

//
- (void)appendContentArray:(NSArray *)inContent
{
    [contentObjectArray addObjectsFromArray:inContent];
}

//
- (void)removeAllContent
{
    [contentObjectArray release]; contentObjectArray = [[NSMutableArray alloc] init];
}


@end
