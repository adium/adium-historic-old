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

/*
    Contact groups hold handles and other groups (anything that is a subclass of AIContactObject).
    
    The group keeps track of its contents using 2 seperate arrays.  One array is stored in the user's manual order, while the other array is sorted according to the current sort mode.  This is the difference between the count/sortedCount and objectAtIndex/sortedObjectAtIndex methods.
    
    When an item is added/removed/replaced in the group, the sorted list is automatically rebuilt.
    When an object in the group's properties are changed, the group should be sent a re-sort message.
*/

#import <AIUtilities/AIUtilities.h>
#import "AIContactGroup.h"
#import "AIContactHandle.h"

@interface AIContactGroup (PRIVATE)
- (id)initWithName:(NSString *)inName;
- (void)flushSortedArray;
- (NSMutableArray *)sortedContactArray;
@end

@implementation AIContactGroup

//Create a new contact group
+ (id)contactGroupWithName:(NSString *)inName
{
    return([[[self alloc] initWithName:inName] autorelease]);
}

//Set the group name
- (void)setName:(NSString *)inName
{
    NSParameterAssert(inName != nil); NSParameterAssert([inName length] != nil);

    [name release]; name = nil;
    name = [inName retain];
}

//Returns the group name
- (NSString *)displayName
{
    return(name);
}

//Returns the number of objects
- (unsigned)count
{
    return([contactArray count]);
}

//Returns the specified object
- (id)objectAtIndex:(unsigned)index
{
    NSParameterAssert(index >= 0 && index < [contactArray count]);

    return([contactArray objectAtIndex:index]);
}

- (NSEnumerator *)objectEnumerator
{
    return([contactArray objectEnumerator]);
}

//Returns the number of visible/sorted objects in this group
- (unsigned)sortedCount
{
    return(sortedCount);
}

//Returns the specified visible/sorted object
- (id)sortedObjectAtIndex:(unsigned)index
{
    NSArray	*sortedArray = [self sortedContactArray];

    NSParameterAssert(index >= 0 && index < [sortedArray count]);

    return([sortedArray objectAtIndex:index]);
}

//Returns 0 if no handle in this group belongs, 1 if they all belong, and -1 if some belong
- (int)contentsBelongToAccount:(AIAccount *)inAccount
{
    int 	loop;
    BOOL	foundBelong = NO;
    BOOL	foundNonBelong = NO;
    
    NSParameterAssert(inAccount != nil);

    //Check the ownership of every handle in this group
    for(loop = 0;loop < [contactArray count];loop++){
        if([[contactArray objectAtIndex:loop] belongsToAccount:inAccount]){
            foundBelong = YES;
        }else{
            foundNonBelong = YES;
        }

        if(foundBelong && foundNonBelong) return(-1); //exit early if we find a mix
    }

    return(foundBelong);
}

//Resorts the group contents
- (void)sortGroupAndSubGroups:(BOOL)subGroups
{
    AIMutableOwnerArray		*visibleArray;
    int 			loop;
          
    //Make sure a contact array exists
    if(!sortedContactArray) sortedContactArray = [contactArray mutableCopy];

    //Sort the Array
    sortedCount = 0;
    [sortedContactArray sortUsingSelector:@selector(compare:)];
    
    //Find any arrays it contains and sort them, and count the number of invisible items
    for(loop = 0;loop < [contactArray count];loop++){
        AIContactObject	*object = [sortedContactArray objectAtIndex:loop];

        if(subGroups && [object isMemberOfClass:[AIContactGroup class]]){
            [(AIContactGroup *)object sortGroupAndSubGroups:subGroups];
        }
        
        if(![[(AIContactHandle *)object displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1]){
            sortedCount++;
        }
    }

    //Set this group as visible if it contains anything visible
    visibleArray = [self displayArrayForKey:@"Hidden"];
    [visibleArray removeObjectsWithOwner:self];
    [visibleArray addObject:[NSNumber numberWithInt:(sortedCount == 0)] withOwner:self];
}

// Semi-Private ---------------------------------------------------------------------------------
//Adds an object to this group
- (void)addObject:(AIContactObject *)inObject
{
    [inObject setContainingGroup:self];
    [contactArray addObject:inObject];
    [self flushSortedArray];
}

//Replace an object in this group
- (void)replaceObject:(AIContactObject *)oldObject with:(AIContactObject *)newObject
{
    int index = [contactArray indexOfObject:oldObject];

    [contactArray replaceObjectAtIndex:index withObject:newObject];
    [self flushSortedArray];
}

//Removes an object to this group
- (void)removeObject:(AIContactObject *)inObject
{
    [inObject setContainingGroup:nil];
    [contactArray removeObject:inObject];
    [self flushSortedArray];
}


// Private ---------------------------------------------------------------------------------
//init
- (id)initWithName:(NSString *)inName
{
    [super init];

    NSParameterAssert(inName != nil); NSParameterAssert([inName length] != 0);

    //Create object array
    contactArray = [[NSMutableArray alloc] init];
    
    //Retain the name
    name = [inName retain];

    return(self);
}

- (void)dealloc
{
    [contactArray release];
    [sortedContactArray release];
    [name release];

    [super dealloc];
}

//deallocates/flushes the sorted array.  Call after adding/removing/replacing contents.
- (void)flushSortedArray
{
    if(sortedContactArray){
        [sortedContactArray release]; sortedContactArray = nil;
    }
}

//returns the sorted contact array (building if necessary)
- (NSMutableArray *)sortedContactArray
{
    if(!sortedContactArray){
        //Create a fresh array and sort it
        sortedContactArray = [contactArray mutableCopy];
        [self sortGroupAndSubGroups:NO];
    }
    
    return(sortedContactArray);
}

@end
