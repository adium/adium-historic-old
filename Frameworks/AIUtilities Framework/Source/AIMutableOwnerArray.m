/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
	Delegate method:
		- (void)mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority
*/

#import "AIMutableOwnerArray.h"

@interface AIMutableOwnerArray (PRIVATE)
- (id)_objectWithHighestPriority;
- (void)_moveObjectToFront:(int)objectIndex;
- (void)_createArrays;
- (void)_destroyArrays;
- (void)mutableOwnerArray:(AIMutableOwnerArray *)mutableOwnerArray didSetObject:(id)anObject withOwner:(id)inOwner;
@end

/*!
 * @class AIMutableOwnerArray
 * @brief An container object that keeps track of who owns each of its objects.
 *
 * Every object in the <tt>AIMutableOwnerArray</tt> has an associated owner.  The best use for this class is when 
 * multiple pieces of code may be trying to control the same thing.  For instance, if there are several events that can
 * cause something to change colors, by using an owner-array it is possible to prevent conflicts and determine an
 * average color based on all the values.  It's also easy for a specific owner to remove the value they contributed,
 * or replace it with another.
 *
 * An owner can only own one object in a given <tt>AIMutableOwnerArray</tt>.
 *
 * Floating point priority levels can be used to dictate the ordering of objects in the array.
 * Lower numbers have higher priority.
 */
@implementation AIMutableOwnerArray

//Init
- (id)init
{
	if ((self = [super init])) {
		contentArray = nil;
		ownerArray = nil;
		priorityArray = nil;
		valueIsSortedToFront = NO;
		delegate = nil;
	}

	return self;
}

//Dealloc
- (void)dealloc
{
	delegate = nil;
	
    [self _destroyArrays];
    [super dealloc];
}


- (NSString *)description
{
	NSMutableString	*desc = [[NSMutableString alloc] initWithFormat:@"<%@: %x: ", NSStringFromClass([self class]), self];
	NSEnumerator	*enumerator = [contentArray objectEnumerator];
	id				object;
	int				i = 0;
	
	while ((object = [enumerator nextObject])) {
		[desc appendFormat:@"(%@:%@)%@", [ownerArray objectAtIndex:i], object, (object == [contentArray lastObject] ? @"" : @", ")];
		i++;
	}
	[desc appendString:@">"];
	
	return [desc autorelease];
}


//Value Storage --------------------------------------------------------------------------------------------------------
#pragma mark Value Storage
/*!
 * @brief Store an object with an owner at default (medium) priority
 *
 * Calls <tt>setObject:withOwner:priorityLevel:</tt> with a priorityLevel of Medium_Priority.
 * Pass nil to remove the object
 */
- (void)setObject:(id)anObject withOwner:(id)inOwner
{
	[self setObject:anObject withOwner:inOwner priorityLevel:Medium_Priority];
}

/*!
 * @brief Store an object with an owner and a priority
 *
 *	<p>Stores an object in the array with a specified owner at a given priority</p>
 *	@param anObject An object to store
 *	@param inOwner The owner of the object
 *  @param priority <p>priority is a float from 0.0 to 1.0, with 0.0 the highest-priority (earliest in the array). Possible preset values are:<br>
 *			- Highest_Priority<br>
 *			- High_Priority<br>
 *			- Medium_Priority<br>
 *			- Low_Priority<br>
 *			- Lowest_Priority<br>
 */
- (void)setObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority
{
    int	ownerIndex;
	//Keep priority in bounds
	if (priority < Highest_Priority || priority > Lowest_Priority) priority = Medium_Priority;
	
	//Remove any existing objects from this owner
	ownerIndex = [ownerArray indexOfObject:inOwner];
	if (ownerArray && (ownerIndex != NSNotFound)) {
		[ownerArray removeObjectAtIndex:ownerIndex];
		[contentArray removeObjectAtIndex:ownerIndex];
		[priorityArray removeObjectAtIndex:ownerIndex];
	}
	
	//Add the new object
	if (anObject) {
		//If we haven't created arrays yet, do so now
		if (!ownerArray) [self _createArrays];
		
		//Add the object
        [ownerArray addObject:inOwner];
        [contentArray addObject:anObject];
        [priorityArray addObject:[NSNumber numberWithFloat:priority]];
	}

	//Our array may no longer have the return value sorted to the front, clear this flag so it can be sorted again
	valueIsSortedToFront = NO;
	
	if (delegate && delegateRespondsToDidSetObjectWithOwnerPriorityLevel) {
		[delegate mutableOwnerArray:self didSetObject:anObject withOwner:inOwner priorityLevel:priority];
	}	
}

//The method the delegate would implement, here to make the compiler happy.
- (void)mutableOwnerArray:(AIMutableOwnerArray *)mutableOwnerArray didSetObject:(id)anObject withOwner:(id)inOwner {};

//Value Retrieval ------------------------------------------------------------------------------------------------------
#pragma mark Value Retrieval
/*!
 * @brief Highest priority object
 *
 * @result The object with the highest priority, performing no other comparison
 */
- (id)objectValue
{
    return ((ownerArray && [ownerArray count]) ? [self _objectWithHighestPriority] : nil);
}

/*!
 * @brief Greatest NSNumber value
 *
 * Assumes the <tt>AIMutableOwnerArray</tt> contains NSNumber instances
 * @result Returns the greatest (highest value) contained <tt>NSNumber</tt> value.
 */
- (NSNumber *)numberValue
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest int value and move it to the front
		if (count != 1 && !valueIsSortedToFront) {
			NSNumber 	*currentMax = [NSNumber numberWithInt:0];
			int			indexOfMax = 0;
			int			index = 0;
			
			//Find the object with the largest int value
			for (index = 0;index < count;index++) {
				NSNumber	*value = [contentArray objectAtIndex:index];

				if ([value compare:currentMax] == NSOrderedDescending) {
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return currentMax;
		} else {
			return [contentArray objectAtIndex:0];
		}
	}
	return 0;
}

/*!
 * @brief Greatest integer value
 *
 * Assuming the <tt>AIMutableOwnerArray</tt> contains <tt>NSNumber</tt> instances, returns the intValue of the greatest (highest-valued) one.
 * @return  Returns the greatest contained integer value.
 */
- (int)intValue
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest int value and move it to the front
		if (count != 1 && !valueIsSortedToFront) {
			int 	currentMax = 0;
			int		indexOfMax = 0;
			int		index = 0;
			
			//Find the object with the largest int value
			for (index = 0;index < count;index++) {
				int	value = [[contentArray objectAtIndex:index] intValue];
				
				if (value > currentMax) {
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return currentMax;
		} else {
			return [[contentArray objectAtIndex:0] intValue];
		}
	}
	return 0;
}

/*!
 * @brief Greatest double value
 *
 * Assuming the <tt>AIMutableOwnerArray</tt> contains <tt>NSNumber</tt> instances, returns the doubleValue of the greatest (highest-valued) one.
 * @return  Returns the greatest contained double value.
 */
- (double)doubleValue
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest double value and move it to the front
		if (count != 1 && !valueIsSortedToFront) {
			double  currentMax = 0;
			int		indexOfMax = 0;
			int		index = 0;
			
			//Find the object with the largest double value
			for (index = 0;index < count;index++) {
				double	value = [[contentArray objectAtIndex:index] doubleValue];
				
				if (value > currentMax) {
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return currentMax;
		} else {
			return [[contentArray objectAtIndex:0] doubleValue];
		}
	}
	
	return 0;
}

/*!
 * @brief Earliest date
 *
 * Assuming the <tt>AIMutableOwnerArray</tt> contains <tt>NSDate</tt> instances, returns the earliest one.
 * @return  Returns the earliest contained date.
 */
- (NSDate *)date
{
	int count;
	if (ownerArray && (count = [ownerArray count])) {
		//If we have more than one object and the object we want is not already in the front of our arrays, 
		//we need to find the object with largest double value and move it to the front
		if (count != 1 && !valueIsSortedToFront) {
			NSDate  *currentMax = nil;
			int		indexOfMax = 0;
			int		index = 0;
			
			//Find the object with the earliest date
			for (index = 0;index < count;index++) {
				NSDate	*value = [contentArray objectAtIndex:index];
				
				if ([currentMax timeIntervalSinceDate:value] > 0) {
					currentMax = value;
					indexOfMax = index;
				}
			}
			
			//Move the object to the front, so we don't have to find it next time
			[self _moveObjectToFront:indexOfMax];
			
			return currentMax;
		} else {
			return [contentArray objectAtIndex:0];
		}
	}
	return nil;
}

/*!
 * @brief Retrieve object by owner
 *
 * Retrieve the object within the <tt>AIMutableOwnerArray</tt> owned by the specified owner.
 * @param inOwner An owner
 * @return  Returns the object owned by <i>inOwner</i>.
 */
- (id)_objectWithHighestPriority
{
	//If we have more than one object and the object we want is not already in the front of our arrays, 
	//we need to find the object with highest priority and move it to the front
	if ([priorityArray count] != 1 && !valueIsSortedToFront) {
		NSEnumerator	*enumerator = [priorityArray objectEnumerator];
		NSNumber		*priority;
		float			currentMax = Lowest_Priority;
		int				indexOfMax = 0;
		int				index = 0;
		
		//Find the object with highest priority
		while ((priority = [enumerator nextObject])) {
			float	value = [priority floatValue];
			if (value < currentMax) {
				currentMax = value;
				indexOfMax = index;
			}
			index++;
		}

		//Move the object to the front, so we don't have to find it next time
		[self _moveObjectToFront:indexOfMax];
	}

	return [contentArray objectAtIndex:0]; 
}

//Move an object to the front of our arrays
- (void)_moveObjectToFront:(int)objectIndex
{
	if (objectIndex != 0) {
		[contentArray exchangeObjectAtIndex:objectIndex withObjectAtIndex:0];
		[ownerArray exchangeObjectAtIndex:objectIndex withObjectAtIndex:0];
		[priorityArray exchangeObjectAtIndex:objectIndex withObjectAtIndex:0];
	}
	valueIsSortedToFront = YES;
}


//Returns an object with the specified owner
- (id)objectWithOwner:(id)inOwner
{
    if (ownerArray && contentArray) {
        int	index = [ownerArray indexOfObject:inOwner];
        if (index != NSNotFound) return [contentArray objectAtIndex:index];
    }
    
    return nil;
}

/*! 
 * @brief Retrieve priority by owner
 *
 * Retrieve the priority of the object within the <tt>AIMutableOwnerArray</tt> owned by the specified owner.
 * @param inOwner An owner
 * @return  Returns the priority of the object owned by <i>inOwner</i>, or 0 if no object is owned by the owner.
 */
- (float)priorityOfObjectWithOwner:(id)inOwner
{
	if (ownerArray && priorityArray) {
        int	index = [ownerArray indexOfObject:inOwner];
		if (index != NSNotFound) return [[priorityArray objectAtIndex:index] floatValue];
	}
	return 0.0;
}

/*!
 * @brief Retrieve owner by object
 *
 * Retrieve the owner within the <tt>AIMutableOwnerArray</tt> which owns the specified object.  If multiple owners own a single object, returns the one with the highest priority.
 * @param anObject An object
 * @return  Returns the owner which owns <i>anObject</i>.
 */
- (id)ownerWithObject:(id)inObject
{
    if (ownerArray && contentArray) {
        int	index = [contentArray indexOfObject:inObject];
        if (index != NSNotFound) return [ownerArray objectAtIndex:index];
    }
    
    return nil;
}

/*! 
 * @brief Retrieve priority by object
 *
 * Retrieve the priority of an object within the <tt>AIMutableOwnerArray</tt>.
 * @param inObject An object
 * @return Returns the priority of the object, or 0 if the object is not in the array.
 */
- (float)priorityOfObject:(id)inObject
{
	if (contentArray && priorityArray) {
        int	index = [contentArray indexOfObject:inObject];
		if (index != NSNotFound) return [[priorityArray objectAtIndex:index] floatValue];
	}
	return 0.0;
}

/*!
 * @brief Retrive enumerator for objects
 * 
 * Retrieve an <tt>NSEnumerator</tt> for all objects in the <tt>AIMutableOwnerArray</tt>. Order is not guaranteed.
 * @return  Returns <tt>NSEnumerator</tt> for all objects.
 */
- (NSEnumerator *)objectEnumerator
{
	return [contentArray objectEnumerator];
}

/*!
 * @brief Retrieve array of values
 * 
 * Retrieve an <tt>NSArray</tt> for all objects in the <tt>AIMutableOwnerArray</tt>. Order is not guaranteed.
 * @return  Returns <tt>NSArray</tt> for all objects.
 */
- (NSArray *)allValues
{
	return contentArray;
}

/*!
 * @brief Retrieve number of objects
 * 
 * Retrieve the number of objects in the <tt>AIMutableOwnerArray</tt>.
 * @return  Returns an unsigned of the number of objects.
 */
- (unsigned)count
{
    return [contentArray count];
}

//Array creation / Destruction -----------------------------------------------------------------------------------------
#pragma mark Array creation / Destruction
//We don't actually create our arrays until needed.  There are many places where a mutable owner array
//is created and not actually used to store anything, so this saves us a bit of ram.
//Create our storage arrays
- (void)_createArrays
{
    contentArray = [[NSMutableArray alloc] init];
    priorityArray = [[NSMutableArray alloc] init];
    ownerArray = [[NSMutableArray alloc] init];
}

//Destroy our storage arrays
- (void)_destroyArrays
{
    [contentArray release]; contentArray = nil;
    [priorityArray release]; priorityArray = nil;
	[ownerArray release]; ownerArray = nil;
}

//Delegation -----------------------------------------------------------------------------------------
#pragma mark Delegation
/*!
 * @brief Set the delegate
 * 
 * The delegate may implement:<br>
 * <tt>- (void)mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority</tt><br>
 * to be notified with the AIMutableOwnerArray is modified.
 * @param inDelegate The delegate
 */
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
	
	delegateRespondsToDidSetObjectWithOwnerPriorityLevel = [delegate respondsToSelector:@selector(mutableOwnerArray:didSetObject:withOwner:priorityLevel:)];
}

/*!
 * @brief Retrieve the delegate.
 *
 * Retrieve the delegate.
 * @return Returns the delegate.
 */
- (id)delegate
{
	return delegate;
}
@end
