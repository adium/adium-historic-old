//
//  AIListGroup.m
//  Adium
//
//  Created by Adam Iser on Fri Mar 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIListGroup.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>

@implementation AIListGroup


- (id)initWithUID:(NSString *)inUID
{
    [super initWithUID:inUID];

    objectArray = [[NSMutableArray alloc] init];
    sortedObjectArray = [[NSMutableArray alloc] init];
    sortedCount = 0;
    expanded = NO;
//    index = 0;
    
    return(self);
}

- (NSString *)displayName
{
    return(UID);
}

//Manual Ordering
/*- (void)setIndex:(int)inIndex
{
    index = inIndex;
}
- (int)index{
    return(index);
}
*/

//Contained Objects
//Returns the specified object
- (id)objectAtIndex:(unsigned)index
{
    NSParameterAssert(index >= 0 && index < [objectArray count]);

    return([objectArray objectAtIndex:index]);
}

- (NSEnumerator *)objectEnumerator
{
    return([objectArray objectEnumerator]);
}



//Expanded State
//Set whether this group is expanded or collapsed
- (void)setExpanded:(BOOL)inExpanded
{
    expanded = inExpanded;
}
- (BOOL)isExpanded{
    return(expanded);
}


//Sorting
//Returns the number of visible/sorted objects in this group
- (unsigned)sortedCount
{
    return(sortedCount);
}

//Returns the specified visible/sorted object
- (id)sortedObjectAtIndex:(unsigned)index
{
    NSParameterAssert(index >= 0 && index < [sortedObjectArray count]);

    return([sortedObjectArray objectAtIndex:index]);
}

//Resorts the group contents
- (void)sortGroupAndSubGroups:(BOOL)subGroups sortController:(id <AIListSortController>)sortController
{
    AIMutableOwnerArray		*visibleArray;
    NSEnumerator		*enumerator;
    AIListObject		*object;

    //Sort the contents of any groups within this group
    if(subGroups){
        enumerator = [objectArray objectEnumerator];
        while((object = [enumerator nextObject])){
            if([object isMemberOfClass:[AIListGroup class]]){
                [(AIListGroup *)object sortGroupAndSubGroups:YES sortController:sortController];
            }
        }
    }

    //Sort this group
    if(sortController){
        [sortController sortListObjects:sortedObjectArray];
    }

    //Count the number of visible items in this group
    sortedCount = 0;
    enumerator = [objectArray objectEnumerator];
    while((object = [enumerator nextObject])){
        if(![[object displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1]){
            sortedCount++;
        }
    }

    //Set this group as visible if it contains anything visible
    visibleArray = [self displayArrayForKey:@"Hidden"];
    [visibleArray setObject:[NSNumber numberWithInt:(sortedCount == 0)] withOwner:self];
}


//Editing
//Adds an object to this group
- (void)addObject:(AIListObject *)inObject
{
    [inObject setContainingGroup:self];
    [objectArray addObject:inObject];
    [sortedObjectArray addObject:inObject];
}

//Add an object to this group
- (void)insertObject:(AIListObject *)inObject atIndex:(int)index
{
    [inObject setContainingGroup:self];
    [objectArray insertObject:inObject atIndex:index];
    [sortedObjectArray addObject:inObject]; //since the array is sorted, placement makes no difference
}

//Replace an object in this group
- (void)replaceObject:(AIListObject *)oldObject with:(AIListObject *)newObject
{
    int index;

    index = [objectArray indexOfObject:oldObject];
    [objectArray replaceObjectAtIndex:index withObject:newObject];

    index = [sortedObjectArray indexOfObject:oldObject];
    [sortedObjectArray replaceObjectAtIndex:index withObject:newObject];
}

//Removes an object from this group
- (void)removeObject:(AIListObject *)inObject
{
    [inObject setContainingGroup:nil];
    [objectArray removeObject:inObject];
    [sortedObjectArray removeObject:inObject];
}

//Returns the index of an object
- (int)indexOfObject:(AIListObject *)inObject
{
    return([objectArray indexOfObject:inObject]);
}

//Remove all the objects from this group
- (void)removeAllObjects
{
    NSEnumerator		*enumerator;
    AIListObject		*object;

    //Set all the contanining groups to nil
    enumerator = [objectArray objectEnumerator];
    while((object = [enumerator nextObject])){
        [object setContainingGroup:nil];
    }
        
    //Remove the objects
    [objectArray removeAllObjects];
    [sortedObjectArray removeAllObjects];
}


@end
