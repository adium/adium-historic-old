/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import <AIUtilities/AIUtilities.h>
#import "AIAccount.h"
#import "AIContactObject.h"
#import "AIContactGroup.h"

//Any object that can be communicated with

@interface AIContactObject (PRIVATE)
- (id)init;
@end

@implementation AIContactObject

// Display -------------------------------------------------
//Returns the object's display name
- (NSString *)displayName
{
    return(nil); //Arbitrary, as we should never use a non-subclasses version of this method
}

//Returns the requested display array for this object
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


// Grouping / Structure -------------------------------------------------
//Returns the group this object is in (will be nil for the root object)
- (AIContactGroup *)containingGroup
{    
    return(containingGroup);
}

//Sets the group this object is in
- (void)setContainingGroup:(AIContactGroup *)inGroup
{
    if(inGroup == nil){
        NSParameterAssert(containingGroup != nil);
        [containingGroup release]; containingGroup = nil;
    
    }else{
        NSParameterAssert(containingGroup == nil);

        containingGroup = [inGroup retain];
    }
}


// Account Ownership -------------------------------------------------
//Registers an account as an owner of this handle
- (void)registerOwner:(AIAccount *)inOwner
{
    [ownerArray addObject:inOwner];
}

//unregisters an account as an owner
- (void)unregisterOwner:(AIAccount *)inOwner
{
    [ownerArray removeObject:inOwner];
}

//Returns YES if one of this handle's owners is the specified account.
- (BOOL)belongsToAccount:(AIAccount *)inAccount
{
    int 	loop;

    //Compare the account's ID to the account ID of our owners
    for(loop = 0;loop < [ownerArray count];loop++){
        if(inAccount == [ownerArray objectAtIndex:loop]){
            return(YES);
        }
    }

    return(NO);
}

// Sorting ------------------------------------------------------------
//If we come first, result is -1.  If object comes first, the result is 1.
- (NSComparisonResult)compare:(AIContactObject *)object
{
    NSComparisonResult 	result;
    BOOL		weAreInvisible = NO;
    BOOL		theyAreInvisible = NO;
    
    NSParameterAssert(object != nil);
    
    if([[self displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1]){
        weAreInvisible = YES;
    }
    if([[object displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1]){
        theyAreInvisible = YES;
    }
    
    if(weAreInvisible && !theyAreInvisible){
        result = 1;
    }else if(!weAreInvisible && theyAreInvisible){
        result = -1;
    }else{
        result = [[self displayName] caseInsensitiveCompare:[object displayName]];
    }

    return(result);
}


// Private -------------------------------------------------
//Init
- (id)init
{
    [super init];
    
    displayDictionary = [[NSMutableDictionary alloc] init];
    ownerArray = [[NSMutableArray alloc] init];
    containingGroup = nil;
    
    return(self);
}

- (void)dealloc
{
    [displayDictionary release];
    [ownerArray release];
//    [activeOwner release];
    [containingGroup release];

    [super dealloc];
}


@end
