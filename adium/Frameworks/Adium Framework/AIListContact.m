//
//  AIListContact.m
//  Adium
//
//  Created by Adam Iser on Fri Mar 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIListContact.h"
#import "AIHandle.h"
#import <AIUtilities/AIUtilities.h>

@implementation AIListContact

- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
    [super initWithUID:inUID];

    serviceID = [inServiceID retain];
    handleArray = [[NSMutableArray alloc] init];
    statusDictionary = [[NSMutableDictionary alloc] init];
    contentObjectArray = [[NSMutableArray alloc] init];
    
    return(self);
}

- (NSString *)serviceID
{
    return(serviceID);
}


//Contained Handles
- (NSEnumerator *)handleEnumerator
{
    return([handleArray objectEnumerator]);
}

- (void)addHandle:(AIHandle *)inHandle
{
    [inHandle setContainingContact:self];    
    [handleArray addObject:inHandle];
}

- (void)removeHandle:(AIHandle *)inHandle
{
    NSEnumerator	*enumerator;
    AIMutableOwnerArray	*array;
    
    //Remove all the status values this handle applied to us
    enumerator = [[statusDictionary allValues] objectEnumerator];
    while((array = [enumerator nextObject])){
        [array setObject:nil withOwner:inHandle];
    }

    //remove it
    [inHandle setContainingContact:nil];
    [handleArray removeObject:inHandle];
}

- (void)removeAllHandles
{
    NSEnumerator	*enumerator;
    AIHandle		*handle;

    //Remove all handles
    enumerator = [handleArray objectEnumerator];
    while((handle = [enumerator nextObject])){
        [self removeHandle:handle];
    }
}


//Manual Ordering
/*- (void)setIndex:(int)inIndex
{
    index = inIndex;
}
- (int)index{
    return(index);
}*/


//Content
//Return our array of content objects
- (NSArray *)contentObjectArray
{
    return(contentObjectArray);
}

//Add a message object to this handle
- (void)addContentObject:(id <AIContentObject>)inObject
{
    //Add the object
    [contentObjectArray insertObject:inObject atIndex:0];

    //Keep the array under X number of objects

}


//Status
//Returns the requested status array for this object
- (AIMutableOwnerArray *)statusArrayForKey:(NSString *)inKey
{
    AIMutableOwnerArray	*array = [statusDictionary objectForKey:inKey];

    if(!array){
        array = [[AIMutableOwnerArray alloc] init];
        [statusDictionary setObject:array forKey:inKey];
        [array release];
    }

    return(array);
}


- (NSString *)displayName
{
    AIMutableOwnerArray	*displayName;
    NSString		*outName;

    //'Alias' Dislay Name
    displayName = [self displayArrayForKey:@"Display Name"];
    if(displayName != nil && [displayName count] != 0){
        outName = [displayName objectAtIndex:0];

    }else{ //Server Dislay Name
        displayName = [self statusArrayForKey:@"Display Name"];
        if(displayName != nil && [displayName count] != 0){
            outName = [displayName objectAtIndex:0];

        }else if([handleArray count] != 0){ //UID
            outName = [[handleArray objectAtIndex:0] UID];

        }else{
            outName = @"##INVALID!";

        }
    }

    return(outName);
}

@end
