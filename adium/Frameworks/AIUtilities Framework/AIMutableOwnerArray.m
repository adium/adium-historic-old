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
- (id)_objectWithHighestPriority;
- (void)_moveObjectToFront:(int)objectIndex;
- (void)_createArrays;
- (void)_destroyArrays;
@end

@implementation AIMutableOwnerArray

//Init
- (id)init
{
    [super init];

    contentArray = nil;
    ownerArray = nil;
    priorityArray = nil;
	valueIsSortedToFront = NO;
	
    return(self);
}

//Dealloc
- (void)dealloc
{
    [self _destroyArrays];
    [super dealloc];
}


//Value Storage --------------------------------------------------------------------------------------------------------
#pragma mark Value Storage
//Adds an object with a specified owner at medium priority (Pass nil to remove the object)
- (void)setObject:(id)anObject withOwner:(id)inOwner
{
	[self setObject:anObject withOwner:inOwner priorityLevel:Medium_Priority];
}

//Adds an object with a specified owner (Pass nil to remove the object)
- (void)setObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority
{
    int	ownerIndex;
	//Keep priority in bounds
	if(priority < Highest_Priority || priority > Lowest_Priority) priority = Medium_Priority;
	
	//Remove any existing objects from this owner
	ownerIndex = [ownerArray indexOfObject:inOwner];
	if(ownerIndex != NSNotFound){
		[ownerArray removeObjectAtIndex:ownerIndex];
		[contentArray removeObjectAtIndex:ownerIndex];
		[priorityArray removeObjectAtIndex:ownerIndex];
	}
	
	//Add the new object
	if(anObject){
		//If we haven't created arrays yet, do so now
		if(!ownerArray) [self _createArrays];
		
		//Add the object
        [ownerArray addObject:inOwner];
        [contentArray addObject:anObject];
        [priorityArray addObject:[NSNumber numberWithFloat:priority]];
	}

	//Our array may no longer have the return value sorted to the front, clear this flag so it can be sorted again
	valueIsSortedToFront = NO;
}


//Value Retrieval ------------------------------------------------------------------------------------------------------
#pragma mark Value Retrieval
//Returns the object with the highest priority
- (id)objectValue
{
    return((ownerArray && [ownerArray count]) ? [self _objectWithHighestPriority] : nil);
}

//Returns the greatest double value
- (int)intValue
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest int value and move it to the front
		if(count != 1 && !valueIsSortedToFront){
			int 	currentMax = 0;
			int		indexOfMax = 0;
			int		index = 0;
			
			//Find the object with the largest int value
			for(index = 0;index < count;index++){
				int	value = [[contentArray objectAtIndex:index] intValue];
				
				if(value > currentMax){
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return(currentMax);
		}else{
			return([[contentArray objectAtIndex:0] intValue]);
		}
	}
	return 0;
}

//Returns the greatest double value
- (double)doubleValue
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest double value and move it to the front
		if(count != 1 && !valueIsSortedToFront){
			double  currentMax = 0;
			int		indexOfMax = 0;
			int		index = 0;
			
			//Find the object with the largest double value
			for(index = 0;index < count;index++){
				double	value = [[contentArray objectAtIndex:index] doubleValue];
				
				if(value > currentMax){
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return(currentMax);
		}else{
			return([[contentArray objectAtIndex:0] doubleValue]);
		}
	}
	
	return 0;
}

//Returns the earliest date
- (NSDate *)date
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest double value and move it to the front
		if(count != 1 && !valueIsSortedToFront){
			NSDate  *currentMax = nil;
			int		indexOfMax = 0;
			int		index = 0;
			
			//Find the object with the earliest date
			for(index = 0;index < count;index++){
				NSDate	*value = [contentArray objectAtIndex:index];
				
				if([currentMax timeIntervalSinceDate:value] > 0){
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return(currentMax);
		}else{
			return([contentArray objectAtIndex:0]);
		}
	}
	return nil;
}

//Return the object with highest priority in our arrays
- (id)_objectWithHighestPriority
{
	//If we have more than one object and the object we want is not already in the front of our arrays, 
	//we need to find the object with highest priority and move it to the front
	if([priorityArray count] != 1 && !valueIsSortedToFront){
		NSEnumerator	*enumerator = [priorityArray objectEnumerator];
		NSNumber		*priority;
		float			currentMax = Lowest_Priority;
		int				indexOfMax = 0;
		int				index = 0;
		
		//Find the object with highest priority
		while(priority = [enumerator nextObject]){
			float	value = [priority floatValue];
			if(value < currentMax){
				currentMax = value;
				indexOfMax = index;
			}
			index++;
		}

		//Move the object to the front, so we don't have to find it next time
		[self _moveObjectToFront:indexOfMax];
	}

	return([contentArray objectAtIndex:0]); 
}

//Move an object to the front of our arrays
- (void)_moveObjectToFront:(int)objectIndex
{
	if(objectIndex != 0){
		[contentArray exchangeObjectAtIndex:objectIndex withObjectAtIndex:0];
		[ownerArray exchangeObjectAtIndex:objectIndex withObjectAtIndex:0];
		[priorityArray exchangeObjectAtIndex:objectIndex withObjectAtIndex:0];
	}
	valueIsSortedToFront = YES;
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

//Return a value enumerator
- (NSEnumerator *)objectEnumerator
{
	return([contentArray objectEnumerator]);
}

//Return all values
- (NSArray *)allValues
{
	return(contentArray);
}

//Return the number of objects
- (unsigned)count
{
    return([contentArray count]);
}


//Array creation / Destruction -----------------------------------------------------------------------------------------
#pragma mark Array creation / Destruction
//We don't actually create our arrays until needed.  There are many places where a mutable owner array
//is created and not actually used to store anything, so this saves us a bit of ram.
//Create our storage arrays
- (void)_createArrays
{
    contentArray = [[NSMutableArray alloc] init];
    ownerArray = [[NSMutableArray alloc] init];
    priorityArray = [[NSMutableArray alloc] init];
}

//Destroy our storage arrays
- (void)_destroyArrays
{
    [contentArray release]; contentArray = nil;
    [ownerArray release]; ownerArray = nil;
    [priorityArray release]; priorityArray = nil;
}

@end
