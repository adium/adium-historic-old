//
//  AIListObject.m
//  Adium
//
//  Created by Adam Iser on Fri Mar 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIListObject.h"
#import "AIListGroup.h"
#import <AIUtilities/AIUtilities.h>

@implementation AIListObject

//Init
- (id)initWithUID:(NSString *)inUID
{
    [super init];

    displayDictionary = [[NSMutableDictionary alloc] init];
    containingGroup = nil;
    UID = [inUID retain];

    return(self);
}

- (void)dealloc
{
    [displayDictionary release];
    [containingGroup release];

    [super dealloc];
}


//Identifying information
- (NSString *)UID
{
    return(UID);
}

/*- (void)setUID:(NSString *)inUID
{
    [UID release]; UID = nil;
    UID = [inUID retain];
}*/

//Display
- (NSString *)displayName
{
    return(nil); //Arbitrary, as we should never use a non-subclassed version of this method
}

- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey
{
    AIMutableOwnerArray	*array = [displayDictionary objectForKey:inKey];

    if(!array){
        array = [[AIMutableOwnerArray alloc] init];
        [displayDictionary setObject:array forKey:inKey];
        [array release];
    }

    return(array);
}

//Nesting
//Returns the group this object is in (will be nil for the root object)
- (AIListGroup *)containingGroup
{
    return(containingGroup);
}

//Sets the group this object is in
- (void)setContainingGroup:(AIListGroup *)inGroup
{
    if(inGroup == nil){
        [containingGroup release]; containingGroup = nil;

    }else{
        containingGroup = [inGroup retain];
    }
}

@end
