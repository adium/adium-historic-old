//
//  AIChat.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIChat.h"
#import <Adium/Adium.h>

@interface AIChat (PRIVATE)
- (id)initForAccount:(AIAccount *)inAccount object:(AIListObject *)inObject;
@end

@implementation AIChat

+ (id)chatForAccount:(AIAccount *)inAccount object:(AIListObject *)inObject
{
    return([[[self alloc] initForAccount:inAccount object:inObject] autorelease]);
}

- (id)initForAccount:(AIAccount *)inAccount object:(AIListObject *)inObject
{
    [super init];

    account = [inAccount retain];
    object = [inObject retain];
    statusDictionary = [[NSMutableDictionary alloc] init];
    contentObjectArray = [[NSMutableArray alloc] init];
    
    return(self);
}

- (void)dealloc
{
    [account release];
    [object release];
    [statusDictionary release];
    [contentObjectArray release];
    
    [super dealloc];
}
    
- (AIAccount *)account
{
    return(account);
}

- (AIListObject *)object
{
    return(object);
}

//Status
- (NSMutableDictionary *)statusDictionary
{
    return(statusDictionary);
}

//Return our array of content objects
- (NSArray *)contentObjectArray
{
    return(contentObjectArray);
}

//Add a message object to this handle
- (void)addContentObject:(AIContentObject *)inObject
{
    //Add the object
    [contentObjectArray insertObject:inObject atIndex:0];
}

- (void)appendContentArray:(NSArray *)inContent
{
    [contentObjectArray addObjectsFromArray:inContent];
}


@end
