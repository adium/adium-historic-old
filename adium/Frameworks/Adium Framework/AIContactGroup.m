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
#import "AIAdium.h"
#import "AIContactGroup.h"
#import "AIContactHandle.h"

@interface AIContactGroup (PRIVATE)
- (id)initWithUID:(NSString *)inUID;
@end

@implementation AIContactGroup

//Create a new contact group
+ (id)contactGroupWithUID:(NSString *)inUID
{
    return([[[self alloc] initWithUID:inUID] autorelease]);
}

//Returns the group name
- (NSString *)displayName
{
    return(UID);
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
    NSParameterAssert(index >= 0 && index < [sortedContactArray count]);

    return([sortedContactArray objectAtIndex:index]);
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
- (void)sortGroupAndSubGroups:(BOOL)subGroups sortController:(id <AIContactSortController>)sortController
{
    AIMutableOwnerArray		*visibleArray;
    NSEnumerator		*enumerator;
    AIContactObject		*object;
    
    //Sort the contents of any groups within this group
    if(subGroups){
        enumerator = [contactArray objectEnumerator];
        while((object = [enumerator nextObject])){
            if([object isMemberOfClass:[AIContactGroup class]]){
                [(AIContactGroup *)object sortGroupAndSubGroups:YES sortController:sortController];
            }
        }
    }

    //Sort this group
    if(sortController){
        [sortController sortContactObjects:sortedContactArray];
    }
    
    //Count the number of visible items in this group
    sortedCount = 0;
    enumerator = [contactArray objectEnumerator];
    while((object = [enumerator nextObject])){        
        if(![[object displayArrayForKey:@"Hidden"] containsAnyIntegerValueOf:1]){
            sortedCount++;
        }
    }

    //Set this group as visible if it contains anything visible
    visibleArray = [self displayArrayForKey:@"Hidden"];
    [visibleArray removeObjectsWithOwner:self];
    [visibleArray addObject:[NSNumber numberWithInt:(sortedCount == 0)] withOwner:self];
}

//Set whether this group is expanded or collapsed
- (void)setExpanded:(BOOL)inExpanded
{
    expanded = inExpanded;
}
- (BOOL)isExpanded{
    return(expanded);
}

// Semi-Private ---------------------------------------------------------------------------------
//Adds an object to this group
- (void)addObject:(AIContactObject *)inObject
{
    [inObject setContainingGroup:self];
    [contactArray addObject:inObject];
    [sortedContactArray addObject:inObject];
}

//Add an object to this group
- (void)insertObject:(AIContactObject *)inObject atIndex:(int)index
{
    [inObject setContainingGroup:self];
    [contactArray insertObject:inObject atIndex:index];
    [sortedContactArray addObject:inObject]; //since the array is sorted, placement makes no difference
}

//Replace an object in this group
- (void)replaceObject:(AIContactObject *)oldObject with:(AIContactObject *)newObject
{
    int index;

    index = [contactArray indexOfObject:oldObject];
    [contactArray replaceObjectAtIndex:index withObject:newObject];

    index = [sortedContactArray indexOfObject:oldObject];
    [sortedContactArray replaceObjectAtIndex:index withObject:newObject];
}

//Removes an object to this group
- (void)removeObject:(AIContactObject *)inObject
{
    [inObject setContainingGroup:nil];
    [contactArray removeObject:inObject];
    [sortedContactArray removeObject:inObject];
}

//Returns the index of an object
- (int)indexOfObject:(AIContactObject *)inObject
{
    return([contactArray indexOfObject:inObject]);    
}

//returns the sorted contact array
- (NSMutableArray *)sortedContactArray
{
    return(sortedContactArray);
}



// Private ---------------------------------------------------------------------------------
//init
- (id)initWithUID:(NSString *)inUID
{
    [super initWithUID:inUID];

    //Create object array
    contactArray = [[NSMutableArray alloc] init];
    sortedContactArray = [[NSMutableArray alloc] init];
    expanded = YES;

    return(self);
}

- (void)dealloc
{
    [contactArray release];
    [sortedContactArray release];

    [super dealloc];
}

@end
