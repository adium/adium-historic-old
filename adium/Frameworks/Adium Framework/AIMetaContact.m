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

#import "AIMetaContact.h"

@interface AIMetaContact (PRIVATE)
- (void)_updateCachedStatusOfObject:(AIListObject *)inObject;
- (void)_removeCachedStatusOfObject:(AIListObject *)inObject;
- (void)_cacheStatusValue:(id)inObject forObject:(id)inOwner key:(NSString *)key;
@end

@implementation AIMetaContact

//init
- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
	objectArray = [[NSMutableArray alloc] init];
	statusCacheDict = [[NSMutableDictionary alloc] init];

	[super initWithUID:inUID serviceID:inServiceID];
	
	return(self);
}

//dealloc
- (void)dealloc
{
	[objectArray release];
	[statusCacheDict release];
	
	[super dealloc];
}


//Object Storage -------------------------------------------------------------------------------------------------------
#pragma mark Object Storage
//Add an object to this meta contact
- (void)addObject:(AIListContact *)inObject
{
	if(![objectArray containsObject:inObject]){
		[inObject setContainingGroup:(AIListGroup *)self];
		[objectArray addObject:inObject];
		[self _updateCachedStatusOfObject:inObject];
	}
}

//Remove an object from this meta contact
- (void)removeObject:(AIListContact *)inObject
{
	if([objectArray containsObject:inObject]){
		[self _removeCachedStatusOfObject:inObject];
		[inObject setContainingGroup:nil];
		[objectArray removeObject:inObject];
	}
}

//Return an enumerator of our content
- (NSEnumerator *)objectEnumerator
{
    return([objectArray objectEnumerator]);
}

//Retrieve an object by index
- (id)objectAtIndex:(unsigned)index
{	
	
    return([objectArray objectAtIndex:index]);
}

//Return our contained objects
- (NSArray *)containedObjects
{
	return(objectArray);
}

//Number of objects we contain
- (unsigned)count
{
	return([objectArray count]);
}


//Status Object Handling -----------------------------------------------------------------------------------------------
#pragma mark Status Object Handling
//Called when the visibility of an object in this group changes
- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible
{

}

//Update our status cache as object we contain change status
- (void)listObject:(AIListObject *)inObject didSetStatusObject:(id)value forKey:(NSString *)key
{
	[self _cacheStatusValue:value forObject:inObject key:key];
	
	[super listObject:self didSetStatusObject:value forKey:key];
}

//Retrieve a status key for this object
- (id)statusObjectForKey:(NSString *)key
{
	return ([[statusCacheDict objectForKey:key] objectValue]);
}
- (int)integerStatusObjectForKey:(NSString *)key
{
	AIMutableOwnerArray *array = [statusCacheDict objectForKey:key];
    return(array ? [array intValue] : 0);
}
- (double)doubleStatusObjectForKey:(NSString *)key
{
	AIMutableOwnerArray *array = [statusCacheDict objectForKey:key];
    return(array ? [array doubleValue] : 0);
}
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key
{
	return ([[statusCacheDict objectForKey:key] date]);	
}


//Sorting --------------------------------------------------------------------------------------------------------------
#pragma mark Sorting
//Sort one of our containing objects
- (void)sortListObject:(AIListObject *)inObject sortController:(AISortController *)sortController
{
	//A meta contact should never receive this method, but it doesn't hurt to implement it just in case
}

//Returns our desired placement within a group
- (float)orderIndex
{
	return([[objectArray objectAtIndex:0] orderIndex]);
}

//Alter the placement of this object in a group (PRIVATE: These are for AIListGroup ONLY)
- (void)setOrderIndex:(float)inIndex
{
	NSEnumerator	*enumerator = [objectArray objectEnumerator];
	AIListObject	*object;
	
	while(object = [enumerator nextObject]){
		[object setOrderIndex:inIndex];
	}
}


//Contained object status cache ----------------------------------------------------------------------------------------
//We maintain a chache of the status of the objects we contain.  This cache is updated whenever one of those objects
//changed status and when objects are added and removed from us.
#pragma mark Contained object status cache
//Update our cache with the newest status of the passed object
- (void)_updateCachedStatusOfObject:(AIListObject *)inObject
{
	NSEnumerator	*enumerator = [inObject statusKeyEnumerator];
	NSString		*key;
	
	while(key = [enumerator nextObject]){
		[self _cacheStatusValue:[inObject statusObjectForKey:key] forObject:inObject key:key];
	}
}

//Flush all status values of the passed object from our cache
- (void)_removeCachedStatusOfObject:(AIListObject *)inObject
{
	NSEnumerator	*enumerator = [inObject statusKeyEnumerator];
	NSString		*key;
	
	while(key = [enumerator nextObject]){
		[self _cacheStatusValue:nil  forObject:inObject key:key];
	}
}

//Update a value in our status cache
- (void)_cacheStatusValue:(id)inObject forObject:(id)inOwner key:(NSString *)key
{
	AIMutableOwnerArray *array = [statusCacheDict objectForKey:key];
	if(!array){
		array = [[AIMutableOwnerArray alloc] init];
		[statusCacheDict setObject:array forKey:key];
		[array release];
	}
	[array setObject:inObject withOwner:inOwner];
}

@end

