//
//  AIChat.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
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

    
//Associated Account ---------------------------------------------------------------------------------------------------
#pragma mark Associated Account
- (AIAccount *)account
{
    return(account);
}

- (void)setAccount:(AIAccount *)inAccount
{
	if(inAccount != account){
		[account release];
		account = [inAccount retain];
	}
}


//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
//Status
- (NSMutableDictionary *)statusDictionary
{
    return(statusDictionary);
}


//Participating ListObjects --------------------------------------------------------------------------------------------
#pragma mark Participating ListObjects
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


//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Content
//Return our array of content objects
- (NSArray *)contentObjectArray
{
    return(contentObjectArray);
}

- (BOOL)hasContent
{
    return ([contentObjectArray count] != 0);
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
- (void)appendContentArray:(NSArray *)inContentArray
{
    [contentObjectArray addObjectsFromArray:inContentArray];
}

//
- (void)removeAllContent
{
    [contentObjectArray release]; contentObjectArray = [[NSMutableArray alloc] init];
}


@end
