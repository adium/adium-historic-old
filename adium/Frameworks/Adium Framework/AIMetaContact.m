/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
- (id)initWithObjectID:(NSNumber *)inObjectID
{
	objectID = [inObjectID retain];
	statusCacheDict = [[NSMutableDictionary alloc] init];

	[super initWithUID:[objectID stringValue] serviceID:nil];

	containedObjects = [[NSMutableArray alloc] init];

	return(self);
}

//dealloc
- (void)dealloc
{
	[statusCacheDict release];
	
	[super dealloc];
}

- (NSNumber *)objectID
{
	return objectID;
}

//Our unique object ID is the number associated with this account
- (NSString *)uniqueObjectID
{
	if (!uniqueObjectID){
		uniqueObjectID = [[NSString stringWithFormat:@"MetaContact-%i",[objectID intValue]] retain];
	}
	return(uniqueObjectID);
}

//Object Storage -------------------------------------------------------------------------------------------------------
#pragma mark Object Storage
//Add an object to this meta contact (PRIVATE: For contact controller only)
//Returns YES if the object was added (that is, was not already present)
- (BOOL)addObject:(AIListObject *)inObject
{
	BOOL	success = NO;
	
	if(![containedObjects containsObject:inObject]){
		[inObject setContainingObject:self];
		[containedObjects addObject:inObject];
		[self _updateCachedStatusOfObject:inObject];
		
		success = YES;
	}
	
	return success;
}

//Remove an object from this meta contact (PRIVATE: For contact controller only)
- (void)removeObject:(AIListObject *)inObject
{
	if([containedObjects containsObject:inObject]){
		[self _removeCachedStatusOfObject:inObject];
		[inObject setContainingObject:[self containingObject]];
		[containedObjects removeObject:inObject];
	}
}

//Respecting the objectArray's order, find the first available contact. Failing that,
//find the first online contact.  Failing that,
//find the first contact.
- (AIListContact *)preferredContact
{
	AIListContact   *preferredContact = nil;
	AIListContact   *thisContact;
	unsigned		index;
	unsigned		count = [containedObjects count];
	
	//Search for an available contact
	for (index = 0; index < count; index++){
		thisContact = [containedObjects objectAtIndex:index];
		if ([thisContact statusSummary] == AIAvailableStatus){
			preferredContact = thisContact;
			break;
		}
	}			
	
	//If no available contacts, find the first online contact
	if (!preferredContact){
		for (index = 0; index < count; index++){
			thisContact = [containedObjects objectAtIndex:index];
			if ([thisContact online]){
				preferredContact = thisContact;
				break;
			}
		}
	}
	
	//If no online contacts, find the first contact
	if (!preferredContact && (count != 0)){
		preferredContact = [containedObjects objectAtIndex:0];
	}
	
	return preferredContact;
}

//Status Object Handling -----------------------------------------------------------------------------------------------
#pragma mark Status Object Handling
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
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key
{
	return([[statusCacheDict objectForKey:key] date]);	
}
- (NSNumber *)numberStatusObjectForKey:(NSString *)key
{
	return([[statusCacheDict objectForKey:key] numberValue]);
}
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key
{
	return([[[statusCacheDict objectForKey:key] objectValue] string]);
}

//Sorting --------------------------------------------------------------------------------------------------------------
#pragma mark Sorting
//Sort one of our containing objects
- (void)sortListObject:(AIListObject *)inObject sortController:(AISortController *)sortController
{
	//A meta contact should never receive this method, but it doesn't hurt to implement it just in case
}

#warning Do we actually need a special order index method now?
/*
//Returns our desired placement within a group
- (float)orderIndex
{
	return([[self preferredContact] orderIndex]);
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
*/

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

//Preferences -------------------------------------------------------------------------------------------------
#pragma mark Preferences

//Retrieve a preference value (with the option of ignoring inherited values)
//If we don't find a preference, query our preferredContact to take its preference as our own.
//We could potentially query all the objects.. but that's possibly overkill.
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName ignoreInheritedValues:(BOOL)ignore
{
	id returnValue;
	
	if (!ignore){
		returnValue = [self preferenceForKey:inKey group:groupName];
		
	}else{
		returnValue = [super preferenceForKey:inKey group:groupName ignoreInheritedValues:YES];
		
		//Look to our first contained object
		if (!returnValue && [containedObjects count]){
			returnValue = [[self preferredContact] preferenceForKey:inKey group:groupName ignoreInheritedValues:YES];
		}
	}
	
	return returnValue;
}

//Retrieve a preference value
//If we don't find a preference, query our first contained object to 'inherit' its preference before going on to the recrusive lookup.
//We could potentially query all the objects.. but that's possibly overkill.
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName
{
	id returnValue;
	
	//First, look at ourself (no recursion)
	returnValue = [super preferenceForKey:inKey group:groupName ignoreInheritedValues:YES];
	
	//Then, look at our preferredContact (no recursion)
	if (!returnValue && [containedObjects count]){
		returnValue = [[self preferredContact] preferenceForKey:inKey group:groupName ignoreInheritedValues:YES];
	}
	
	//Finally, do the recursive lookup starting with our containing group
	if (!returnValue){
		returnValue = [[self containingObject] preferenceForKey:inKey group:groupName];
	}

	return returnValue;
}

@end
