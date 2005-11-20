/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIMetaContact.h"
#import "AIContactController.h"
#import "AIListContact.h"
#import "AIListGroup.h"
#import "AIService.h"
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIArrayAdditions.h>

#define	KEY_CONTAINING_OBJECT_ID	@"ContainingObjectInternalObjectID"
#define	OBJECT_STATUS_CACHE			@"Object Status Cache"

@interface AIMetaContact (PRIVATE)
- (void)_updateCachedStatusOfObject:(AIListObject *)inObject;
- (void)_removeCachedStatusOfObject:(AIListObject *)inObject;
- (BOOL)_cacheStatusValue:(id)inObject forObject:(id)inOwner key:(NSString *)key notify:(BOOL)notify;

- (id)_statusObjectForKey:(NSString *)key containedObjectSelector:(SEL)containedObjectSelector;
- (void)_determineIfWeShouldAppearToContainOnlyOneContact;

- (void)_addListContacts:(NSArray *)inContacts toArray:(NSMutableArray *)listContacts uniqueObjectIDs:(NSMutableArray *)uniqueObjectIDs;

- (void)restoreGrouping;
@end

@implementation AIMetaContact

int containedContactSort(AIListContact *objectA, AIListContact *objectB, void *context);

//init
- (id)initWithObjectID:(NSNumber *)inObjectID
{
	objectID = [inObjectID retain];
	statusCacheDict = [[NSMutableDictionary alloc] init];
	_preferredContact = nil;
	_listContacts = nil;

	[super initWithUID:[objectID stringValue] service:nil];

	containedObjects = [[NSMutableArray alloc] init];
	
	containsOnlyOneUniqueContact = YES;
	containsOnlyOneService = YES;
	expanded = YES;
	containedObjectsNeedsSort = NO;
	delayContainedObjectSorting = NO;
	saveGroupingChanges = YES;
	
	largestOrder = 1.0;
	smallestOrder = 1.0;
		
	return self;
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

//
- (NSString *)internalObjectID
{
	if (!internalObjectID) {
		internalObjectID = [[AIMetaContact internalObjectIDFromObjectID:objectID] retain];
	}
	return internalObjectID;
}

+ (NSString *)internalObjectIDFromObjectID:(NSNumber *)inObjectID
{
	return ([NSString stringWithFormat:@"MetaContact-%i",[inObjectID intValue]]);
}

//A metaContact's internalObjectID is completely unique to it, so return that for interalUniqueObjectID
- (NSString *)internalUniqueObjectID
{
	return [self internalObjectID];
}

//Return the account of this metaContact, which we may treat as the preferredContact's account
- (AIAccount *)account
{
	return [[self preferredContact] account];
}

//Return the service of our preferred contact, so we will display the service icon of our preferred contact on the list
- (AIService *)service
{
	return [[self preferredContact] service];
}

//When called, cache the internalObjectID of the new group so we can restore it immediately next time.
- (void)setContainingObject:(AIListObject <AIContainingObject> *)inGroup
{
	NSString	*inGroupInternalObjectID = [inGroup internalObjectID];
	
	//Save the change of containing object so it can be restored on launch next time if we are using groups.
	//We don't save if we are not using groups as this set will be for the contact list root and probably not desired permanently.
	if ([[adium contactController] useContactListGroups] &&
		![inGroupInternalObjectID isEqualToString:[self preferenceForKey:KEY_CONTAINING_OBJECT_ID
																   group:OBJECT_STATUS_CACHE
												   ignoreInheritedValues:YES]]) {

		[self setPreference:inGroupInternalObjectID
					 forKey:KEY_CONTAINING_OBJECT_ID
					  group:OBJECT_STATUS_CACHE];
	}

	[super setContainingObject:inGroup];
}

//Restore the AIListGroup grouping into which this object was last manually placed
- (void)restoreGrouping
{
	BOOL			useContactListGroups;
	
	useContactListGroups = [[adium contactController] useContactListGroups];

	if (useContactListGroups) {
		NSString		*oldContainingObjectID;
		AIListObject	*oldContainingObject;

		oldContainingObjectID = [self preferenceForKey:KEY_CONTAINING_OBJECT_ID
												 group:OBJECT_STATUS_CACHE];
		oldContainingObject = [[adium contactController] existingListObjectWithUniqueID:oldContainingObjectID];
		
		if (oldContainingObject &&
			[oldContainingObject isKindOfClass:[AIListGroup class]]) {
			//A previous grouping is saved; restore it
			[[adium contactController] _moveContactLocally:self
												   toGroup:(AIListGroup *)oldContainingObject];
		} else {
			/* This metaContact doesn't have a group assigned to it... if any contained object has a group,
			 * use that group as a best-guess for the proper destination.
			 */
			NSString		*bestGuessRemoteGroup = nil;
			AIListContact	*containedContact;
			NSEnumerator	*enumerator;
			
			enumerator = [[self listContacts] objectEnumerator];
			
			//Find the first contact with a group
			while ((containedContact = [enumerator nextObject]) &&
				   (bestGuessRemoteGroup = [containedContact remoteGroupName]));

			//Put this metacontact in that group
			if (bestGuessRemoteGroup) {
				[[adium contactController] _moveContactLocally:self
													   toGroup:[[adium contactController] groupWithUID:bestGuessRemoteGroup]];
			}
		}
	}
	
}

//A metaContact should never be a stranger
- (BOOL)isStranger
{
	return NO;
}

//Object Storage -------------------------------------------------------------------------------------------------------
#pragma mark Object Storage
/*!
 * @brief Add an object to this meta contact
 *
 * Should only be called by AIContactController
 *
 * @result YES if the object was added (that is, was not already present)
 */
- (BOOL)addObject:(AIListObject *)inObject
{
	BOOL	success = NO;

	if (![containedObjects containsObjectIdenticalTo:inObject]) {

		//Before we add our first object, restore our grouping
		if ([containedObjects count] == 0) {
			[self restoreGrouping];	
		}
		
		[inObject setContainingObject:self];
		[containedObjects addObject:inObject];
		containedObjectsNeedsSort = YES;
		
		[_listContacts release]; _listContacts = nil;
		
		//If we were unique before, check if we will still be unique after adding this contact.
		//If we were not, no checking needed.
		if (containsOnlyOneUniqueContact) {
			[self _determineIfWeShouldAppearToContainOnlyOneContact];
		}
		
		//Add the object from our status cache, notifying of the changes (silently) as appropriate
		[self _updateCachedStatusOfObject:inObject];
		
		success = YES;
	}
	
	return success;
}

/*!
 * @brief Remove an object from this meta contact
 *
 * Should only be called by AIContactController.
 */
- (void)removeObject:(AIListObject *)inObject
{
	if ([containedObjects containsObjectIdenticalTo:inObject]) {
		
		[inObject retain];
		
		[containedObjects removeObject:inObject];
		
		if ([inObject isKindOfClass:[AIListContact class]] && [(AIListContact *)inObject remoteGroupName]) {
			//Reset it to its remote group
			[inObject setContainingObject:nil];
			[[adium contactController] listObjectRemoteGroupingChanged:(AIListContact *)inObject];
		} else {
			[inObject setContainingObject:[self containingObject]];
		}
		
		[_listContacts release]; _listContacts = nil;
		
		//Only need to check if we are now unique if we weren't unique before, since we've either become
		//unique are stayed the same.
		if (!containsOnlyOneUniqueContact) {
			[self _determineIfWeShouldAppearToContainOnlyOneContact];
		}

		//Remove all references to the object from our status cache; notifying of the changes as appropriate
		[self _removeCachedStatusOfObject:inObject];

		[inObject release];
	}
}

/*!
 * @brief Return the preferred contact to use within this metaContact
 *
 * Respecting the objectArray's order, find the first available contact. Failing that,
 * find the first online contact.  Failing that,
 * find the first contact.
 *
 * Only contacts which are in the array returned by [self listContacts] are eligible.
 * @see listContacts
 *
 * @result The <tt>AIListContact</tt> which is considered the best for interacting with this metaContact
 */
- (AIListContact *)preferredContact
{
	if (!_preferredContact) {
		NSArray			*theContainedObjects = [self listContacts];
		AIListContact   *preferredContact = nil;
		AIListContact   *thisContact;
		unsigned		index;
		unsigned		count = [theContainedObjects count];
		
		//Search for an available contact who is not mobile
		for (index = 0; index < count; index++) {
			thisContact = [theContainedObjects objectAtIndex:index];
			if (([thisContact statusSummary] == AIAvailableStatus) &&
				(![thisContact isMobile])) {
				preferredContact = thisContact;
				break;
			}
		}
		
		//If no available contacts, find the first online contact
		if (!preferredContact) {
			for (index = 0; index < count; index++) {
				thisContact = [theContainedObjects objectAtIndex:index];
				if ([thisContact online]) {
					preferredContact = thisContact;
					break;
				}
			}
		}

		//If no online contacts, find the first contact
		if (!preferredContact && (count != 0)) {
			preferredContact = [theContainedObjects objectAtIndex:0];
		}
		
		_preferredContact = preferredContact;
	}
	
	return _preferredContact;
}

/*!
 * @brief The perferred contact on a given service
 *
 * Same as [self preferredContact] but only looks at contacts on the specified service
 */
- (AIListContact *)preferredContactWithService:(AIService *)inService
{
	AIListContact   *returnContact = nil;
	
	if (inService) {
		NSArray			*listContactsArray = [self listContacts];
		AIListContact   *thisContact;
		unsigned		index;
		unsigned		count = [listContactsArray count];
		
		//Search for an available contact who is not mobile
		for (index = 0; index < count; index++) {
			thisContact = [listContactsArray objectAtIndex:index];
			if (([thisContact service] == inService) &&
				([thisContact statusSummary] == AIAvailableStatus) &&
				(![thisContact isMobile])) {
				returnContact = thisContact;
				break;
			}
		}			
		
		//If no available contacts, find the first online contact
		if (!returnContact) {
			for (index = 0; index < count; index++) {
				thisContact = [listContactsArray objectAtIndex:index];
				if (([thisContact online]) && 
					([thisContact service] == inService)) {
					returnContact = thisContact;
					break;
				}
			}
		}
		
		if (!returnContact) {
			for (index = 0; index < count; index++) {
				thisContact = [listContactsArray objectAtIndex:index];
				if ([thisContact service] == inService) {
					returnContact = thisContact;
					break;
				}
			}
		}
	} else {
		returnContact = [self preferredContact];
	}
	
	return (returnContact);
}

/*!
 * @brief Return a flat array of contacts to be displayed to the user
 *
 * This only returns one of each 'unique' contact, whereas the containedObjects potentially contains multiple contacts
 * which appear the same to the user but are unique to Adium, since each account on the proper service will have its own
 * instance of AIListContact for a given contact.
 *
 * This also only returns contacts which are listed on online accounts.
 */
- (NSArray *)listContacts
{
	if (!_listContacts) {
		NSMutableArray	*listContacts = [[NSMutableArray alloc] init];
		NSMutableArray	*uniqueObjectIDs = [NSMutableArray array];
		unsigned		count;
		
		[self _addListContacts:[self containedObjects] toArray:listContacts uniqueObjectIDs:uniqueObjectIDs];

		_listContacts = listContacts;

		/* Only notify if there is a change.
		 * Use super's implementation as we don't need to be searching our contained objects...
		 */
		count = [listContacts count];
		if ([super integerStatusObjectForKey:@"VisibleObjectCount"] != count) {
			[self setStatusObject:(count ? [NSNumber numberWithInt:count] : nil)
						   forKey:@"VisibleObjectCount"
						   notify:NotifyNow];
		}
	}
	
	return _listContacts;
}

/*!
 * @brief Dictionary of service classes and list contacts
 *
 * @result A dictionary whose keys are serviceClass strings and whose objects are arrays of contained contacts on that serviceClass.
 */
- (NSDictionary *)dictionaryOfServiceClassesAndListContacts
{
	NSMutableDictionary *contactsDict = [NSMutableDictionary dictionary];
	NSString			*serviceClass;
	NSMutableArray		*contactArray;
	NSArray				*listContacts = [self listContacts];
	AIListObject		*listContact;
	unsigned			i, listContactsCount;
	
	listContactsCount = [listContacts count];
	for (i = 0; i < listContactsCount; i++) {

		listContact = [listContacts objectAtIndex:i];
		serviceClass = [[listContact service] serviceClass];
		
		// Is there already an entry for this service?
		if ((contactArray = [contactsDict objectForKey:serviceClass])) {
			[contactArray addObject:listContact];
			
		} else {
			contactArray = [NSMutableArray arrayWithObject:listContact];
			[contactsDict setObject:contactArray forKey:serviceClass];
		}
	}
	
	return contactsDict;
}

- (NSArray *)servicesOfContainedObjects
{
	NSMutableArray	*services = [[NSMutableArray alloc] init];
	NSEnumerator	*enumerator = [containedObjects objectEnumerator];
	AIListObject	*listObject;
	
	while ((listObject = [enumerator nextObject])) {
		if (![services containsObject:[listObject service]]) [services addObject:[listObject service]];
	}
	
	return [services autorelease];
}




- (unsigned)uniqueContainedObjectsCount
{
	return [[self listContacts] count];
}

- (AIListObject *)uniqueObjectAtIndex:(int)index
{
	return [[self listContacts] objectAtIndex:index];
}

- (void)_addListContacts:(NSArray *)inContacts toArray:(NSMutableArray *)listContacts uniqueObjectIDs:(NSMutableArray *)uniqueObjectIDs
{
	unsigned		index;
	unsigned		count = [inContacts count];
	
	//Search for an available contact
	for (index = 0; index < count; index++) {
		AIListObject	*listObject = [inContacts objectAtIndex:index];
		if (([listObject isKindOfClass:[AIMetaContact class]]) && (listObject != self)) {
			//Parse the contained metacontact recrusively
			[self _addListContacts:[(AIMetaContact *)listObject containedObjects]
						   toArray:listContacts
				   uniqueObjectIDs:uniqueObjectIDs];
			
		} else if (([listObject isKindOfClass:[AIListContact class]]) &&
				 ([(AIListContact *)listObject remoteGroupName] != nil)) {
			NSString	*listObjectInternalObjectID = [listObject internalObjectID];
			unsigned int listContactIndex = [uniqueObjectIDs indexOfObject:listObjectInternalObjectID];
			
			if (listContactIndex == NSNotFound) {
				//This contact isn't in the array yet, so add it
				[listContacts addObject:listObject];
				[uniqueObjectIDs addObject:listObjectInternalObjectID];
				
			} else {
				//If it is found, but it is offline and this contact is online, swap 'em out so our array
				//has the best possible listContacts (making display elsewhere more straightforward)
				if (![[listContacts objectAtIndex:listContactIndex] online] &&
					[listObject online]) {
					
					[listContacts replaceObjectAtIndex:listContactIndex
											withObject:listObject];
				}
			}
		}
	}
}

- (BOOL)containsOnlyOneUniqueContact
{
	return containsOnlyOneUniqueContact;
}

- (BOOL)containsOnlyOneService
{
	return containsOnlyOneService;
}

- (void)containedMetaContact:(AIMetaContact *)containedMetaContact didChangeContainsOnlyOneUniqueContact:(BOOL)inContainsOnlyOneUniqueContact
{
	if (inContainsOnlyOneUniqueContact != containsOnlyOneUniqueContact) {
		[self _determineIfWeShouldAppearToContainOnlyOneContact];
	}
}

//When the listContacts array has a single member, we only contain one unique contact.
- (void)_determineIfWeShouldAppearToContainOnlyOneContact
{
	BOOL oldOnlyOne = containsOnlyOneUniqueContact;
	unsigned listContactsCount;

	//Clear our preferred contact so the next call to it will update the preferred contact
	_preferredContact = nil;
	
	[_listContacts release]; _listContacts = nil;
	listContactsCount = [[self listContacts] count];

	containsOnlyOneUniqueContact = (listContactsCount < 2);

	//If it changed, do stuff
	if (oldOnlyOne != containsOnlyOneUniqueContact) {
		if ([containingObject isKindOfClass:[AIMetaContact class]]) {
			//Shouldn't be needed as of 0.8
			[(AIMetaContact *)containingObject containedMetaContact:self
							  didChangeContainsOnlyOneUniqueContact:containsOnlyOneUniqueContact];
		}

		[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
												  object:self
												userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																					 forKey:@"Notify"]];
	}
}

- (void)remoteGroupingOfContainedObject:(AIListObject *)inListObject changedTo:(NSString *)inRemoteGroupName
{
	AILog(@"AIMetaContact: Remote grouping of %@ changed to %@",inListObject,inRemoteGroupName);

	//When a contact has its remote grouping changed, this may mean it is now listed on an online account.
	//We therefore update our containsOnlyOneContact boolean.
	[self _determineIfWeShouldAppearToContainOnlyOneContact];
}

//Status Object Handling -----------------------------------------------------------------------------------------------
#pragma mark Status Object Handling
//Update our status cache as object we contain change status
- (void)object:(id)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(NotifyTiming)notify
{
	//Clear our cached _preferredContact if a contained object's online, away, or idle status changed
	BOOL	shouldNotify = NO;
	
	//If the online status of a contained object changed, we should also check if our one-contact-only
	//in terms of online contacts has changed
	if ([key isEqualToString:@"Online"]) {
		[self _determineIfWeShouldAppearToContainOnlyOneContact];
		shouldNotify = YES;
	}
	
	if ([key isEqualToString:@"StatusType"] ||
	   [key isEqualToString:@"IdleSince"] ||
	   [key isEqualToString:@"IsIdle"] ||
	   [key isEqualToString:@"IsMobile"]) {
		_preferredContact = nil;
		shouldNotify = YES;
	}
	
	/* Only tell super that we changed if _cacheStatusValue returns YES indicating we did or if our
	 * preferred contact changed. */
	if ([self _cacheStatusValue:value forObject:inObject key:key notify:notify] ||
	   shouldNotify) {
		[super object:self didSetStatusObject:value forKey:key notify:notify];
	}
}

//---- Default status object behavior ----
//Retrieve a status key for this object - return the value of our preferredContact, 
//returning nil if our preferredContact returns nil.

- (id)statusObjectForKey:(NSString *)key
{
	return [self statusObjectForKey:key fromAnyContainedObject:YES];
}
- (int)integerStatusObjectForKey:(NSString *)key
{
	return [self integerStatusObjectForKey:key fromAnyContainedObject:YES];
}
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key
{
	return [self earliestDateStatusObjectForKey:key fromAnyContainedObject:YES];
}
- (NSNumber *)numberStatusObjectForKey:(NSString *)key
{
	return [self numberStatusObjectForKey:key fromAnyContainedObject:YES];
}
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key
{
	return [self stringFromAttributedStringStatusObjectForKey:key fromAnyContainedObject:YES];
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
	return [self _statusObjectForKey:key containedObjectSelector:(fromAnyContainedObject ? @selector(date) : nil)];
}

//NSNumber
- (NSNumber *)numberStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self _statusObjectForKey:key containedObjectSelector:(fromAnyContainedObject ? @selector(numberValue) : nil)];
}

//Integer (uses numberStatusObjectForKey:)
- (int)integerStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	NSNumber *returnValue = [self numberStatusObjectForKey:key fromAnyContainedObject:fromAnyContainedObject];
	
    return returnValue ? [returnValue intValue] : 0;
}

//String from attributed string (uses statusObjectForKey:)
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [[self statusObjectForKey:key fromAnyContainedObject:fromAnyContainedObject] string];
}

//Returns the status object from our object.
//If no such object is found, return the status object from the preferredContact for a given key.
//If no such object is found, and containedObjectSelector is not nil, 
//queries the entire mutableOwnerArray using that selector.
- (id)_statusObjectForKey:(NSString *)key containedObjectSelector:(SEL)containedObjectSelector
{
	id					returnValue;

	if (!(returnValue = [super statusObjectForKey:key])) {
		AIMutableOwnerArray *keyArray = [statusCacheDict objectForKey:key];
		
		returnValue = [keyArray objectWithOwner:[self preferredContact]];
		
		//If we got nil and we want to look at our contained objects, return the objectValue
		if (!returnValue && containedObjectSelector) {
			returnValue = [keyArray performSelector:containedObjectSelector];
		}
	}
	
	return returnValue;
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
	
	while ((key = [enumerator nextObject])) {
		id value = [inObject statusObjectForKey:key];

		//Only tell super that we changed if _cacheStatusValue returns YES indicating we did
		if ([self _cacheStatusValue:value forObject:inObject key:key notify:NotifyLater]) {
			[super object:self didSetStatusObject:value forKey:key notify:NotifyLater];
		}
	}
	
	[self notifyOfChangedStatusSilently:YES];
}

//Flush all status values of the passed object from our cache
- (void)_removeCachedStatusOfObject:(AIListObject *)inObject
{
	NSEnumerator	*enumerator = [inObject statusKeyEnumerator];
	NSString		*key;
	
	while ((key = [enumerator nextObject])) {
		//Only tell super that we changed if _cacheStatusValue returns YES indicating we did
		if ([self _cacheStatusValue:nil forObject:inObject key:key notify:NotifyLater]) {
			[super object:self didSetStatusObject:[self statusObjectForKey:key] forKey:key notify:NotifyLater];
		}
	}
	
	[self notifyOfChangedStatusSilently:YES];
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
	
	if (!array) {
		array = [[AIMutableOwnerArray alloc] init];
		[statusCacheDict setObject:array forKey:key];
		[array release];
	}
	
	//Store the new value in our mutableOwnerArray for this key
	[array setObject:inObject withOwner:inOwner];
	
	//Retrieve the new object value
	newObjectValue = [array objectValue];

	if (newObjectValue != previousObjectValue) {
		changed = YES;
	}
	
	[previousObjectValue release];
	
	return changed;
}


//Preferences -------------------------------------------------------------------------------------------------
#pragma mark Preferences

//Retrieve a preference value (with the option of ignoring inherited values)
//If we don't find a preference, query our preferredContact to take its preference as our own.
//We could potentially query all the objects.. but that's possibly overkill.
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName ignoreInheritedValues:(BOOL)ignore
{
	id returnValue;
	
	if (!ignore) {
		returnValue = [self preferenceForKey:inKey group:groupName];
		
	} else {
		returnValue = [super preferenceForKey:inKey group:groupName ignoreInheritedValues:YES];
		
		//Look to our first contained object
		if (!returnValue && [containedObjects count]) {
			returnValue = [[self preferredContact] preferenceForKey:inKey group:groupName ignoreInheritedValues:YES];

			//Move the preference to us so we will have it next time and the contact won't (lazy migration)
			if (returnValue) {
				[self setPreference:returnValue forKey:inKey group:groupName];
				[[self preferredContact] setPreference:nil forKey:inKey group:groupName];
			}
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
	if (!returnValue && [containedObjects count]) {
		returnValue = [[self preferredContact] preferenceForKey:inKey
														  group:groupName 
										  ignoreInheritedValues:YES];
	}
	
	//Finally, do the recursive lookup starting with our containing group
	if (!returnValue) {
		returnValue = [[self containingObject] preferenceForKey:inKey group:groupName];
	}

	return returnValue;
}

#pragma mark User Icon
/* 
 * @brief Return the user icon for this metaContact
 *
 * We always want to provide a userIcon if at all possible.
 * First, call displayUserIcon. See below for details.
 * If that returns nil, look at our preferredContact's userIcon.
 * If that returns nil, find any userIcon of a containedContact.
 *
 * @result The <tt>NSImage</tt> to associate with this metaContact
 */
- (NSImage *)userIcon
{
	NSImage *userIcon = [self displayUserIcon];
	if (!userIcon) {
		userIcon = [[self preferredContact] userIcon];
	}
	if (!userIcon) {
		NSArray		*theContainedObjects = [self containedObjects];
		
		unsigned int count = [theContainedObjects count];
		unsigned int i = 0;
		while ((i < count) && !userIcon) {
			userIcon = [[theContainedObjects objectAtIndex:i] userIcon];
			i++;
		}
	}

	return userIcon;
}

/* @brief Return a medium-priority or better user icon from this specific meta contact's display array
 *
 * If the meta contact has a medium-priority or better user icon, such as a user-specified icon or an address book
 * supplied icon with the "prefer address book icon images" preference, return it.  Otherwise, return nil, indicating
 * that contained contacts should be queried for a better, more preferred icon.
 *
 * @result An <tt>NSImage</tt> of medium priority or higher (note that a lower float value is a higher priority)
 */
- (NSImage *)displayUserIcon
{
	AIMutableOwnerArray	*userIconArray = [self displayArrayForKey:KEY_USER_ICON create:NO];
	NSImage	*displayUserIcon = [userIconArray objectValue];
	if ([userIconArray priorityOfObject:displayUserIcon] < Medium_Priority)
		return displayUserIcon;
	else
		return nil;
}

- (NSString *)displayName
{
	NSString	*displayName = [[self displayArrayForKey:@"Display Name"] objectValue];
	
	if (!displayName) {
		displayName = [[self preferredContact] ownDisplayName];
	}

	return displayName;
}

- (NSString *)phoneticName
{
	NSString	*phoneticName = [[self displayArrayForKey:@"Phonetic Name"] objectValue];
	
	if (!phoneticName) {
		phoneticName = [[self preferredContact] ownPhoneticName];
	}
	
	return phoneticName;
}

//FormattedUID will return nil if we have multiple different UIDs contained within us
- (NSString *)formattedUID
{
	if (containsOnlyOneUniqueContact) {
		return [[self preferredContact] formattedUID];
	} else {
		return nil;
	}
}

- (NSString *)longDisplayName
{
	NSString	*longDisplayName = [[self displayArrayForKey:@"Long Display Name"] objectValue];

	if (!longDisplayName) {
		longDisplayName = [[self preferredContact] longDisplayName];
	}

	//    return [longDisplayName stringByAppendingString:[NSString stringWithFormat:@"-Meta-%i",[self containedObjectsCount]]];
	return longDisplayName;
}

#pragma mark Status
- (NSString *)statusName
{
	return [[self preferredContact] statusObjectForKey:@"StatusName"];
}

- (AIStatusType)statusType
{
	NSNumber		*statusTypeNumber = [[self preferredContact] statusObjectForKey:@"StatusType"];
	AIStatusType	statusType = (statusTypeNumber ?
								  [statusTypeNumber intValue] :
								  AIAvailableStatusType);
	
	return statusType;
}

/*!
 * @brief Determine the status message to be displayed in the contact list
 *
 * @result <tt>NSAttributedString</tt> which will be the message for this contact in the contact list, after modifications
 */
- (NSAttributedString *)contactListStatusMessage
{
	NSEnumerator		*enumerator;
	NSAttributedString	*contactListStatusMessage = nil;
	AIListContact		*listContact;
	
	enumerator = [[self listContacts] objectEnumerator];
	while (!contactListStatusMessage && (listContact = [enumerator nextObject])) {
		contactListStatusMessage = [listContact contactListStatusMessageIgnoringStatusName];
	}

	if (!contactListStatusMessage)
		contactListStatusMessage = [self statusMessage];
	
	return contactListStatusMessage;
}

//Object Storage ---------------------------------------------------------------------------------------------
#pragma mark Object Storage
//Return our contained objects
- (NSArray *)containedObjects
{
	//Sort the containedObjects if the flag tells us it's needed
	if (containedObjectsNeedsSort && !delayContainedObjectSorting) {
		containedObjectsNeedsSort = NO;
		[containedObjects sortUsingFunction:containedContactSort context:nil];
	}
	
	return containedObjects;
}

//Number of containd objects
- (unsigned)containedObjectsCount
{
    return [containedObjects count];
}

//Test for the presence of an object in our group
- (BOOL)containsObject:(AIListObject *)inObject
{
	return [containedObjects containsObject:inObject];
}

//Retrieve an object by index
- (id)objectAtIndex:(unsigned)index
{
    return [[self listContacts] objectAtIndex:index];
}

//Retrieve the index of an object
- (int)indexOfObject:(AIListObject *)inObject
{
    return [[self listContacts] indexOfObject:inObject];
}

//Return an enumerator of our content
- (NSEnumerator *)objectEnumerator
{
    return [[self containedObjects] objectEnumerator];
}

- (NSEnumerator *)listContactsEnumerator
{
	return [[self listContacts] objectEnumerator];
}

//Remove all the objects from this group (PRIVATE: For contact controller only)
- (void)removeAllObjects
{
	//Remove all the objects
	while ([containedObjects count]) {
		[self removeObject:[containedObjects objectAtIndex:0]];
	}
}

- (AIListObject *)objectWithService:(AIService *)inService UID:(NSString *)inUID
{
	NSEnumerator	*enumerator = [[self containedObjects] objectEnumerator];
	AIListObject	*object;
	
	while ((object = [enumerator nextObject])) {
		if ([inUID isEqualToString:[object UID]] && [object service] == inService) break;
	}
	
	return object;
}

//Expanded State -------------------------------------------------------------------------------------------------------
#pragma mark Expanded State
//Set the expanded/collapsed state of this group (PRIVATE: For the contact list view to let us know our state)
- (void)setExpanded:(BOOL)inExpanded
{
    expanded = inExpanded;
}
//Returns the current expanded/collapsed state of this group
- (BOOL)isExpanded
{
    return expanded;
}

//Order index
- (void)listObject:(AIListObject *)listObject didSetOrderIndex:(float)inOrderIndex
{
	if (inOrderIndex > largestOrder) {
		largestOrder = inOrderIndex;
	} else if (inOrderIndex < smallestOrder) {
		smallestOrder = inOrderIndex;
	}

	//We're no longer positive of our preferredContact, so clear the cache
	containedObjectsNeedsSort = YES;
	_preferredContact = nil;
	[_listContacts release]; _listContacts = nil;
}

- (float)smallestOrder
{
	return smallestOrder;
}

- (float)largestOrder
{
	return largestOrder;
}

#pragma mark Contained Contact sorting

- (void)setDelayContainedObjectSorting:(BOOL)flag
{
	delayContainedObjectSorting = flag;
	
	if (!delayContainedObjectSorting) {
		//Clear our preferred contact so the next call to it will update the preferred contact
		_preferredContact = nil;
		
		[_listContacts release]; _listContacts = nil;
	}
}

/*!
 * @brief Sort contained contacts, first by order index and then by internalUniqueObjectID
 */
int containedContactSort(AIListContact *objectA, AIListContact *objectB, void *context)
{
	float orderIndexA = [objectA orderIndex];
	float orderIndexB = [objectB orderIndex];
	if (orderIndexA > orderIndexB) {
		return NSOrderedDescending;
		
	} else if (orderIndexA < orderIndexB) {
		return NSOrderedAscending;
		
	} else {
		return [[objectA internalUniqueObjectID] caseInsensitiveCompare:[objectB internalUniqueObjectID]];
	}
}

//Visibility -----------------------------------------------------------------------------------------------------------
#pragma mark Visibility
/*!
 * @brief Returns the number of visible objects in this metaContact, which is the same as the count of listContacts
 */
- (unsigned)visibleCount
{
    return [[self listContacts] count];
}

#pragma mark Debugging
- (NSString *)description
{
	NSMutableArray *subobjectDescs = [[NSMutableArray alloc] initWithCapacity:[containedObjects count]];

	NSEnumerator *containedObjectsEnum = [containedObjects objectEnumerator];
	AIListObject *subobject;
	while((subobject = [containedObjectsEnum nextObject]))
		[subobjectDescs addObject:[subobject description]];

	NSString *subobjectDescsDesc = [subobjectDescs description];
	[subobjectDescs release];

	return [NSString stringWithFormat:@"%@:%@:%@", [super description], [self internalObjectID], subobjectDescsDesc];
}

@end
