/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIListGroup.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>

@implementation AIListGroup

- (id)initWithUID:(NSString *)inUID
{
    [super initWithUID:inUID serviceID:nil];

    objectArray = [[NSMutableArray alloc] init];
    visibleCount = 0;
    expanded = NO;
    
    return(self);
}

- (NSString *)displayName
{
    return(UID);
}

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

//Returns the number of visible objects in this group
- (unsigned)visibleCount
{
    return(visibleCount);
}

- (unsigned)count
{
    return([objectArray count]);
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
        [sortController sortListObjects:objectArray];
    }

    //Count the number of visible items in this group
    visibleCount = 0;
    enumerator = [objectArray objectEnumerator];
    while((object = [enumerator nextObject])){
        if(![[object displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1]){
            visibleCount++;
        }
    }

    //Set this group as visible if it contains anything visible
    visibleArray = [self displayArrayForKey:@"Hidden"];
    [visibleArray setObject:[NSNumber numberWithInt:(visibleCount == 0)] withOwner:self];
}


//Editing
//Adds an object to this group
- (void)addObject:(AIListObject *)inObject
{
    [inObject setContainingGroup:self];
    [objectArray addObject:inObject];
}

//Replace an object in this group
- (void)replaceObject:(AIListObject *)oldObject with:(AIListObject *)newObject
{
    int index;

    index = [objectArray indexOfObject:oldObject];
    [objectArray replaceObjectAtIndex:index withObject:newObject];
}

//Removes an object from this group
- (void)removeObject:(AIListObject *)inObject
{
    [inObject setContainingGroup:nil];
    [objectArray removeObject:inObject];
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
    visibleCount = 0;
}


@end
