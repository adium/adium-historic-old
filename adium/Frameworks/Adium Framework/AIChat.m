//
//  AIChat.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//

#import "AIChat.h"

@interface AIChat (PRIVATE)
- (id)initForAccount:(AIAccount *)inAccount initialStatusDictionary:(NSDictionary *)inDictionary;
@end

@implementation AIChat

+ (id)chatForAccount:(AIAccount *)inAccount initialStatusDictionary:(NSDictionary *)inDictionary
{
    return([[[self alloc] initForAccount:inAccount initialStatusDictionary:inDictionary] autorelease]);
}

- (id)initForAccount:(AIAccount *)inAccount initialStatusDictionary:(NSDictionary *)inDictionary
{
    [super init];

	name = nil;
    account = [inAccount retain];
    statusDictionary = (inDictionary ? [inDictionary mutableCopy] : [[NSMutableDictionary alloc] init]);
    contentObjectArray = [[NSMutableArray alloc] init];
    participatingListObjects = [[NSMutableArray alloc] init];
    dateOpened = [[NSDate date] retain];
	
    return(self);
}

- (void)dealloc
{
    [account release];
    [statusDictionary release];
    [contentObjectArray release];
    [participatingListObjects release];
  	[dateOpened release]; 
  
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

//Date Opened
#pragma mark Date Opened
- (NSDate *)dateOpened
{
	return(dateOpened);
}

- (void)setDateOpened:(NSDate *)inDate
{
	[dateOpened release]; 
	dateOpened = [inDate retain];
}

//Status ---------------------------------------------------------------------------------------------------------------
#pragma mark Status
//Status
- (NSMutableDictionary *)statusDictionary
{
    return(statusDictionary);
}
- (NSString *)name
{
	return (name ? name : [[self listObject] displayName]);
}
- (void)setName:(NSString *)inName
{
	[name release]; name = [inName retain]; 
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

- (NSString *)uniqueChatID
{
	NSString		*uniqueChatID;
	AIListObject	*listObject;
	if (listObject = [self listObject]){
		uniqueChatID = [listObject uniqueObjectID];
	}else{
		uniqueChatID = [NSString stringWithFormat:@"%@.%@",name,[account uniqueObjectID]];
	}
	
	return (uniqueChatID);
}

+ (NSString *)uniqueChatIDForChatWithName:(NSString *)name onAccount:(AIAccount *)account
{
	return [NSString stringWithFormat:@"%@.%@",name,[account uniqueObjectID]];
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
