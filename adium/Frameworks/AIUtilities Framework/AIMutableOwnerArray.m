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

/*
    An array that keeps track of who owns each of its objects.
    
    Every object in the array has an associated owner.  The best use for this class is when multiple pieces of code may be trying to control the same thing.  For instance, if there are several events that can cause something to change colors, by using an owner-array it is possible to prevent conflicts and determine an average color based on all the values.  It's also easy for a specific owner to remove the value they contributed, or replace it with another.
 
	Priority levels can be used to dictate the ordering of objects in the array.  0 is the highest priority; 10 is the lowest.
*/

#import "AIMutableOwnerArray.h"

@interface AIMutableOwnerArray (PRIVATE)
- (void)_createArrays;
- (void)_createSubArraysForPriority:(int)priority;
- (void)_destroyArrays;
- (void)_destroySubArraysForPriority:(int)priority;
- (void)_buildOwnerAndContentArrays;
- (void)_removeObjectFromSubArraysWithOwner:(id)inOwner;
@end

@implementation AIMutableOwnerArray

//inits the array
- (id)init
{
    [super init];

	int i;
	for (i=0; i<11; i++) {
		contentSubArray[i] = nil;
		ownerSubArray[i] = nil;
	}
	
    contentArray = nil;
    ownerArray = nil;
    
    return(self);
}

- (void)dealloc
{
    [self _destroyArrays];

    [super dealloc];
}

//Adds an object with a specified owner at medium priority (Pass nil to remove the object)
- (void)setObject:(id)anObject withOwner:(id)inOwner
{
	[self setObject:anObject withOwner:inOwner priorityLevel:Medium_Priority];
}


//Adds an object with a specified owner (Pass nil to remove the object)
- (void)setObject:(id)anObject withOwner:(id)inOwner priorityLevel:(int)priority
{
	//Keep priority in bounds
	if (priority < 0) priority = 0;
	if (priority > 10) priority = 10;
	
    int	ownerIndex;
	
	if(!ownerArray) [self _createArrays];
    if(!ownerSubArray[priority]) [self _createSubArraysForPriority:priority];
	
    //Remove any existing objects
	ownerIndex = [ownerArray indexOfObject:inOwner];
	if(ownerIndex != NSNotFound){
		//Remove object and owner from the main arrays
		[ownerArray removeObjectAtIndex:ownerIndex];
		[contentArray removeObjectAtIndex:ownerIndex];
		
		//Remove object and owner from their current subArrays
		[self _removeObjectFromSubArraysWithOwner:inOwner];
	}
	
    //Add the new object
    if(anObject != nil){
        [contentSubArray[priority] addObject:anObject];
        [ownerSubArray[priority] addObject:inOwner];
		
		[self _buildOwnerAndContentArrays];
		
    }else{
		//Destory the main arrays if necessary
        if(ownerArray && ([ownerArray count] == 0)) [self _destroyArrays];
		//Destroy this subarray if necessary
		if([ownerSubArray[priority] count] == 0) [self _destroySubArraysForPriority:priority];
    }
}

//Returns an object with the specified owner
- (id)objectWithOwner:(id)inOwner
{
    if(ownerArray && contentArray){
        int	index = [ownerArray indexOfObject:inOwner];
        if(index != NSNotFound) return([contentArray objectAtIndex:index]);
    }
    
    return(nil);
}

//Returns the owner of the specified object
- (id)ownerWithObject:(id)inObject
{
    if(ownerArray && contentArray){
        int	index = [contentArray indexOfObject:inObject];
        if(index != NSNotFound) return([ownerArray objectAtIndex:index]);
    }
    
    return(nil);
}

//
- (NSEnumerator *)objectEnumerator
{
	return([contentArray objectEnumerator]);
}

//
- (NSEnumerator *)ownerEnumerator
{
	return([ownerArray objectEnumerator]);
}
//
- (NSArray *)allValues
{
	return(contentArray);
}


//Return the number of objects
- (unsigned)count
{
    return([contentArray count]);
}

//Return the specified object
- (id)objectAtIndex:(unsigned)index
{
    return([contentArray objectAtIndex:index]);
}

//Return the specific owner
- (id)ownerAtIndex:(unsigned)index
{
    return ([ownerArray objectAtIndex:index]);   
}

//Return the average color
- (NSColor *)averageColor
{
    NSColor	*average = nil;
    int		loop;

    for(loop = 0;loop < [ownerArray count];loop++){
        average = [contentArray objectAtIndex:loop];
    }

    return(average);
}

- (NSDate *)earliestDate
{
    if([ownerArray count] != 0){
        NSDate	*earlyDate = [contentArray objectAtIndex:0];
        int		loop;

        for(loop = 1;loop < [ownerArray count];loop++){
            NSDate	*date = [contentArray objectAtIndex:loop];

            if([earlyDate timeIntervalSinceDate:date] > 0){
                earlyDate = date;
            }
        }

        return(earlyDate);
    }else{
        return(nil);
    }
}

//Returns YES if the array contains the specified integer value
- (BOOL)containsAnyIntegerValueOf:(int)inValue
{
    int	loop;

    for(loop = 0;loop < [ownerArray count];loop++){
        if([[contentArray objectAtIndex:loop] intValue] == inValue){
            return(YES);
        }
    }

    return(NO);
}

//Returns the greatest integer value
- (int)greatestIntegerValue
{
    int	loop;
    int	count = [ownerArray count];
    int	greatest = 0;

    if(count != 0){
        greatest = [[contentArray objectAtIndex:0] intValue];

        for(loop = 1;loop < count;loop++){
            int	current = [[contentArray objectAtIndex:loop] intValue];

            if(current > greatest){
                greatest = current;
            }
        }
    }
    
    return(greatest);
}

//Returns the greatest double value
- (double)greatestDoubleValue
{
    int		loop;
    int		count = [ownerArray count];
    double	greatest = 0;

    if(count != 0){
        greatest = [[contentArray objectAtIndex:0] doubleValue];

        for(loop = 1;loop < [ownerArray count];loop++){
            double	current = [[contentArray objectAtIndex:loop] doubleValue];

            if(current > greatest){
            greatest = current;
            }
        }
    }

    return(greatest);
}

//Returns the first image
- (NSImage *)firstImage
{
    return([ownerArray count] ? [contentArray objectAtIndex:0] : nil);
}

- (void)_createArrays
{
    contentArray = [[NSMutableArray alloc] init];
    ownerArray = [[NSMutableArray alloc] init];
}
- (void)_createSubArraysForPriority:(int)priority
{
    contentSubArray[priority] = [[NSMutableArray alloc] init];
    ownerSubArray[priority] = [[NSMutableArray alloc] init];
}
- (void)_buildOwnerAndContentArrays
{
	NSMutableArray *thisOwnerArray, *thisContentArray;
	int i, index;
	
	//Remove all the owners and content objects from the main arrays
	[ownerArray removeAllObjects];
	[contentArray removeAllObjects];
	
	//Check each subArray, adding from priority 0 to priority 10
	for (i=0; i<11; i++) {
		thisOwnerArray = ownerSubArray[i];
		
		//If arrays exist at this priority level, add them to the main arrays
		if (thisOwnerArray) {
			thisContentArray = contentSubArray[i];
			
			[ownerArray addObjectsFromArray:thisOwnerArray];
			[contentArray addObjectsFromArray:thisContentArray];
		}
	}
}

- (void)_destroyArrays
{
    [contentArray release]; contentArray = nil;
    [ownerArray release]; ownerArray = nil;
}
- (void)_destroySubArraysForPriority:(int)priority
{
	[ownerSubArray[priority] release]; ownerSubArray[priority] = nil;
	[contentSubArray[priority] release]; contentSubArray[priority] = nil;
}

- (void)_removeObjectFromSubArraysWithOwner:(id)inOwner
{
	NSMutableArray *thisOwnerArray, *thisContentArray;
	int i, index;
	
	//Check each subArray
	for (i=0; i<11; i++) {
		thisOwnerArray = ownerSubArray[i];
		
		if (thisOwnerArray) {
			index = [thisOwnerArray indexOfObject:inOwner];
			
			if (index != NSNotFound) {
				thisContentArray = contentSubArray[i];
				
				//Remove the object and owner
				[thisOwnerArray removeObjectAtIndex:index];
				[thisContentArray removeObjectAtIndex:index];
				break;
			}
		}
	}
}
@end
