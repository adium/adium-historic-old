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
- (BOOL)_cacheStatusValue:(id)inObject forObject:(id)inOwner key:(NSString *)key notify:(BOOL)notify;

- (id)_statusObjectForKey:(NSString *)key containedObjectSelector:(SEL)containedObjectSelector;
- (void)_determineIfWeShouldAppearToContainOnlyOneContact;
@end

@implementation AIMetaContact

//init
- (id)initWithObjectID:(NSNumber *)inObjectID
{
	objectID = [inObjectID retain];
	statusCacheDict = [[NSMutableDictionary alloc] init];
	_preferredContact = nil;
	
	[super initWithUID:[objectID stringValue] serviceID:nil];

	containedObjects = [[NSMutableArray alloc] init];
	
	containsOnlyOneUniqueContact = YES;
	
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
		
		//Check if we will still be unique after adding this contact
		if (containsOnlyOneUniqueContact){
			//If the new object's formattedUID isn't the same as ours, we no longer can claim to only have one
			//unique contact
			NSString	*currentUID = [self formattedUID];
			NSString	*currentService = [self displayServiceID];
			
			NSString	*newUID = [inObject formattedUID];
			NSString	*newService = [inObject displayServiceID];
			
			//If newUID is nil, then the containedContact is a metaContact with multiple unique contacts... 
			//so we are no longer unique.
			//If we have a currentUID, and it's not the same as the new one, we are no longer unique.
			//Similarly, if we have a currentUID and our serviceID isn't the same as the new one, we are no longer unique.
			if ((newUID == nil) ||
				(currentUID && (![currentUID isEqualToString:newUID] || ![currentService isEqualToString:newService]))){
				
				containsOnlyOneUniqueContact = NO;
				
				//We're no longer positive of our preferredContact, so clear the cache
				_preferredContact = nil;
			
				if ([containingObject isKindOfClass:[AIMetaContact class]]){
					[(AIMetaContact *)containingObject containedMetaContact:self
									  didChangeContainsOnlyOneUniqueContact:containsOnlyOneUniqueContact];
				}
				
			}
		}
		
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
		
		//Only need to check if we are now unique if we weren't unique before, since we've either become
		//unique are stayed the same.
		if (!containsOnlyOneUniqueContact){
			[self _determineIfWeShouldAppearToContainOnlyOneContact];
		}
	}
}

//Respecting the objectArray's order, find the first available contact. Failing that,
//find the first online contact.  Failing that,
//find the first contact.
- (AIListContact *)preferredContact
{
	if (!_preferredContact){
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
		
		_preferredContact = preferredContact;
	}
	
	return _preferredContact;
}

- (AIListContact *)preferredContactWithServiceID:(NSString *)inServiceID
{
	AIListContact   *returnContact = nil;
	
	if (_preferredContact && [[_preferredContact serviceID] isEqualToString:inServiceID]){
		//First try to use our preferredContact
		returnContact = _preferredContact;
		
	}else{
		AIListContact   *thisContact;
		unsigned		index;
		unsigned		count = [containedObjects count];
		
		//Search for an available contact
		for (index = 0; index < count; index++){
			thisContact = [containedObjects objectAtIndex:index];
			if (([[thisContact serviceID] isEqualToString:inServiceID]) &&
				([thisContact statusSummary] == AIAvailableStatus)){
				returnContact = thisContact;
				break;
			}
		}			
		
		//If no available contacts, find the first online contact
		if (!returnContact){
			for (index = 0; index < count; index++){
				thisContact = [containedObjects objectAtIndex:index];
				if (([thisContact online]) && 
					([[thisContact serviceID] isEqualToString:inServiceID])){
					returnContact = thisContact;
					break;
				}
			}
		}

		if (!returnContact){
			for (index = 0; index < count; index++){
				thisContact = [containedObjects objectAtIndex:index];
				if ([[thisContact serviceID] isEqualToString:inServiceID]){
					returnContact = thisContact;
					break;
				}
			}
		}
	}

	return (returnContact);
}

- (NSArray *)listContacts
{
	return [self containedObjects];
}

- (BOOL)containsOnlyOneUniqueContact
{
	return containsOnlyOneUniqueContact;
}

- (NSString *)formattedUID
{
	if (containsOnlyOneUniqueContact){
		return([[self preferredContact] formattedUID]);
	}else{
		return nil;
	}
}


- (NSString *)displayServiceID
{
	if (containsOnlyOneUniqueContact){
		return([[self preferredContact] displayServiceID]);
	}else{
		return nil;
	}
}

- (void)containedMetaContact:(AIMetaContact *)containedMetaContact didChangeContainsOnlyOneUniqueContact:(BOOL)inContainsOnlyOneUniqueContact
{
	//If the contained meta contact's status isn't the same as our current one - i.e.
	//It now contains multiple contacts, but we currently think we are unique
	//--OR--
	//It now contains only one contact, but currently think we are not unique
	//
	//then we need to redetermine our uniqueness.
//	NSLog(@"%i: %@ changed to %i",containsOnlyOneUniqueContact,containedMetaContact,inContainsOnlyOneUniqueContact);
	if (inContainsOnlyOneUniqueContact != containsOnlyOneUniqueContact){
		[self _determineIfWeShouldAppearToContainOnlyOneContact];
	}
}

//When do we claim to contain only one contact?
//		- When all online contacts within the metaContact have the same UID and service
//			-OR-
//		- When all contacts within the metaContact are offline and have the same UID and service
//This makes the UID and service information presented to the user as accurate as possible for at-a-glance
//knowlege of the metaContact's effective contents
- (void)_determineIfWeShouldAppearToContainOnlyOneContact
{
	unsigned int count = [self containedObjectsCount];
	
	if (count > 1){
		NSString	*formattedUIDToMatch = nil;
		NSString	*serviceIDToMatch = nil;
		
		NSString	*offline_formattedUIDToMatch = nil;
		NSString	*offline_serviceIDToMatch = nil;
		
		unsigned int i;
		for (i = 0; i < count; i++){
			AIListContact   *thisContact = [self objectAtIndex:i];
			
			NSString	*thisContactFormattedUID;
			NSString	*thisContactServiceID;
			
			thisContactFormattedUID = [thisContact formattedUID];
			thisContactServiceID = [thisContact displayServiceID];
			
			if ([thisContact online]){
//				NSLog(@"%@ is online (%@)",thisContact,thisContactFormattedUID);
				//If this contact has no formattedUID, it isn't unique, so break
				if (!thisContactFormattedUID)
					break;
				
				//If we don't have a set of data to match yet, this contact is our target
				if (!formattedUIDToMatch){
					formattedUIDToMatch = thisContactFormattedUID;
					serviceIDToMatch = thisContactServiceID;
//					NSLog(@"ONLINE: Going to match %@",formattedUIDToMatch);
				}else{
					//Otherwise, compare this contact to our target
					if ((![thisContactFormattedUID isEqualToString:formattedUIDToMatch]) ||
						(![thisContactServiceID isEqualToString:serviceIDToMatch])){
//						NSLog(@"%@ doesn't match %@ so breaking",thisContactFormattedUID,thisContactServiceID);
						break;
					}
				}
			}else{
//				NSLog(@"%@ is offline",thisContact);
				//If we're not searching for a match, we haven't found an online contact yet
				if (!formattedUIDToMatch){
					//If we don't have a set of data for an offline contact to match yet,
					//this offline contact is our target, which will be needed only if we find no
					//online targets
					if (!offline_formattedUIDToMatch){
						offline_formattedUIDToMatch = thisContactFormattedUID;
						offline_serviceIDToMatch = thisContactServiceID;
//						NSLog(@"OFFLINE: Going to match %@",offline_formattedUIDToMatch);

					}else{
						//Otherwise, compare this contact to our target
						if ((![thisContactFormattedUID isEqualToString:offline_formattedUIDToMatch]) ||
							(![thisContactServiceID isEqualToString:offline_serviceIDToMatch])){
							
							//This offline contact does not match our previous offline contact.
							//We will no work on the assumption that we do not contain only one unique contact.
							//If all the online contacts match, however, this flag will be changed to YES
							//once the search is complete.
							containsOnlyOneUniqueContact = NO;
						}
					}		
				}
			}
		}
		
		/*
		 If we made it all the way through the loop, and we were looking at online contacts
		 (and hence formattedUIDToMatch != nil), all our contacts have the same formattedUID
		 */
//		NSLog(@"i: %i, count: %i, formattedUIDToMatch: %@, was %i",i,count,formattedUIDToMatch,containsOnlyOneUniqueContact);
		if ((i == count) && formattedUIDToMatch){
			containsOnlyOneUniqueContact = YES;
		}else{
			containsOnlyOneUniqueContact = NO;	
		}
//		NSLog(@"Now %i",containsOnlyOneUniqueContact);
		
	}else{
		
		if (count == 1) {
			//With only one contact, we are as unique as the contact we contain...
			containsOnlyOneUniqueContact = ([[self objectAtIndex:0] formattedUID] != nil);
		}else{
			containsOnlyOneUniqueContact = YES;
		}
	}	
	
	//Clear our preferred contact so the next call to it will update the preferred contact
	_preferredContact = nil;
}


//Status Object Handling -----------------------------------------------------------------------------------------------
#pragma mark Status Object Handling
//Update our status cache as object we contain change status
- (void)object:(id)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
{
	//Clear our cached _preferredContact if a contained object's online, away, or idle status changed
	{
		//If the online status of a contained object changed, we should also check if our one-contact-only
		//in terms of online contacts has changed
		if ([key isEqualToString:@"Online"]){
//			NSLog(@"%@ is %@",[inObject formattedUID],([value boolValue] ? @"** Online" : @"== Offline"));
			[self _determineIfWeShouldAppearToContainOnlyOneContact];
		}
		
		if([key isEqualToString:@"Away"] ||
		   [key isEqualToString:@"IdleSince"]){
//			NSLog(@"%@: Clear preferred contact",self);
			_preferredContact = nil;
		}
	}
//	NSLog(@"%@: %@ set %@ for %@ (%i)",self,inObject,value,key,notify);
	//Only tell super that we changed if _cacheStatusValue returns YES indicating we did
	if([self _cacheStatusValue:value forObject:inObject key:key notify:notify]){
		[super object:self didSetStatusObject:value forKey:key notify:notify];
	}
}

//---- Default status object behavior ----
//Retrieve a status key for this object - return the value of our preferredContact, 
//returning nil if our preferredContact returns nil.

- (id)statusObjectForKey:(NSString *)key
{
	return([self statusObjectForKey:key fromAnyContainedObject:NO]);
}
- (int)integerStatusObjectForKey:(NSString *)key
{
	return([self integerStatusObjectForKey:key fromAnyContainedObject:NO]);
}
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key
{
	return([self earliestDateStatusObjectForKey:key fromAnyContainedObject:NO]);
}
- (NSNumber *)numberStatusObjectForKey:(NSString *)key
{
	return([self numberStatusObjectForKey:key fromAnyContainedObject:NO]);
}
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key
{
	return([self stringFromAttributedStringStatusObjectForKey:key fromAnyContainedObject:NO]);
}

//---- fromAnyContainedObject status object behavior ----
//If fromAnyContainedObject is YES, return the best value from any contained object if the preferred object returns nil.
//If it is NO, only look at the preferred object.

//General status object
- (id)statusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self _statusObjectForKey:key containedObjectSelector:(fromAnyContainedObject ? @selector(objectValue) : nil)];
}

//NSDate
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	NSDate *returnValue = [self _statusObjectForKey:key containedObjectSelector:(fromAnyContainedObject ? @selector(date) : nil)];
	
	return([[statusCacheDict objectForKey:key] date]);
}

//NSNumber
- (NSNumber *)numberStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return([self _statusObjectForKey:key containedObjectSelector:(fromAnyContainedObject ? @selector(numberValue) : nil)]);
}

//Integer (uses numberStatusObjectForKey:)
- (int)integerStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	NSNumber *returnValue = [self numberStatusObjectForKey:key fromAnyContainedObject:fromAnyContainedObject];
	
    return(returnValue ? [returnValue intValue] : 0);
}

//String from attributed string (uses statusObjectForKey:)
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return([[self statusObjectForKey:key fromAnyContainedObject:fromAnyContainedObject] string]);
}

//Returns the status object from the preferredContact for a given key.  If no such object is found, and containedObjectSelector is not nil,
//queries the entire mutableOwnerArray using that selector
- (id)_statusObjectForKey:(NSString *)key containedObjectSelector:(SEL)containedObjectSelector
{
	AIMutableOwnerArray *keyArray = [statusCacheDict objectForKey:key];
	id					returnValue;
	
	returnValue = [keyArray objectWithOwner:[self preferredContact]];
	
	//If we got nil and we want to look at our contained objects, return the objectValue
	if (!returnValue && containedObjectSelector){
		returnValue = [keyArray performSelector:containedObjectSelector];
	}
	
	return (returnValue);
}
//Sorting --------------------------------------------------------------------------------------------------------------
#pragma mark Sorting
//Sort one of our containing objects
- (void)sortListObject:(AIListObject *)inObject sortController:(AISortController *)sortController
{
	//A meta contact should never receive this method, but it doesn't hurt to implement it just in case
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
		[self _cacheStatusValue:[inObject statusObjectForKey:key] forObject:inObject key:key notify:YES];
	}
}

//Flush all status values of the passed object from our cache
- (void)_removeCachedStatusOfObject:(AIListObject *)inObject
{
	NSEnumerator	*enumerator = [inObject statusKeyEnumerator];
	NSString		*key;
	
	while(key = [enumerator nextObject]){
		[self _cacheStatusValue:nil forObject:inObject key:key notify:YES];
	}
}

//Update a value in our status cache
- (BOOL)_cacheStatusValue:(id)inObject forObject:(id)inOwner key:(NSString *)key notify:(BOOL)notify
{
	AIMutableOwnerArray *array = [statusCacheDict objectForKey:key];
	id					previousObjectValue;
	id					newObjectValue;
	BOOL				changed = NO;
	
	//Retrieve the current object value (before the caching) - retain since the set method might release the value
	previousObjectValue = [[array objectValue] retain];
	
	if(!array){
		array = [[AIMutableOwnerArray alloc] init];
		[statusCacheDict setObject:array forKey:key];
		[array release];
	}
	
	//Store the new value in our mutableOwnerArray for this key
	[array setObject:inObject withOwner:inOwner];
	
	//Retrieve the new object value
	newObjectValue = [array objectValue];

	if (newObjectValue != previousObjectValue){
		changed = YES;
	}
	
	[previousObjectValue release];
	
	return(changed);
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
		returnValue = [[self preferredContact] preferenceForKey:inKey
														  group:groupName 
										  ignoreInheritedValues:YES];
	}
	
	//Finally, do the recursive lookup starting with our containing group
	if (!returnValue){
		returnValue = [[self containingObject] preferenceForKey:inKey group:groupName];
	}

	return returnValue;
}

#pragma mark User Icon
//We always want to provide a userIcon if at all possible.
//First get our userIcon as normal.
//If that returns nil, look at our preferredContact's userIcon.
//If that returns nil, find any userIcon of a containedContact.
- (NSImage *)userIcon
{
	NSImage *userIcon = [super userIcon];
	if (!userIcon){
		userIcon = [[self preferredContact] userIcon];
	}
	if (!userIcon){
		unsigned int count = [self containedObjectsCount];
		unsigned int i = 0;
		while ((i < count) && !userIcon){
			userIcon = [[self objectAtIndex:i] userIcon];
			i++;
		}
	}

	return userIcon;
}

#warning debugging
- (NSString *)displayName
{
	return [[super displayName] stringByAppendingString:[NSString stringWithFormat:@"-Meta-%i",[self containedObjectsCount]]];
}

- (NSString *)longDisplayName
{
    NSString	*outName = [[self displayArrayForKey:@"Long Display Name"] objectValue];
    return(outName ? [outName stringByAppendingString:[NSString stringWithFormat:@"-Meta-%i",[self containedObjectsCount]]] : [self displayName]);
}

@end
