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

#import <Adium/AIMetaContact.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIService.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIAccount.h>
#import <Adium/AIAbstractListController.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIArrayAdditions.h>

#define	KEY_CONTAINING_OBJECT_ID	@"ContainingObjectInternalObjectID"
#define	OBJECT_STATUS_CACHE			@"Object Status Cache"

#define	KEY_IS_EXPANDABLE					@"IsExpandable"
#define	KEY_EXPANDED						@"IsExpanded"

@interface AIMetaContact (PRIVATE)
- (void)_updateCachedStatusOfObject:(AIListObject *)inObject;
- (void)_removeCachedStatusOfObject:(AIListObject *)inObject;
- (BOOL)_cacheStatusValue:(id)inObject forObject:(id)inOwner key:(NSString *)key notify:(BOOL)notify determineIfChanged:(BOOL)determineIfChanged;

- (id)_valueForProperty:(NSString *)key containedObjectSelector:(SEL)containedObjectSelector;
- (void)_determineIfWeShouldAppearToContainOnlyOneContact;

- (NSArray *)uniqueContainedListContactsIncludingOfflineAccounts:(BOOL)includeOfflineAccounts;

- (void)updateDisplayName;
- (void)restoreGrouping;
@end

@implementation AIMetaContact

int containedContactSort(AIListContact *objectA, AIListContact *objectB, void *context);

//init
- (id)initWithObjectID:(NSNumber *)inObjectID
{
	objectID = [inObjectID retain];

	if ((self = [super initWithUID:[inObjectID stringValue] service:nil])) {
		statusCacheDict = [[NSMutableDictionary alloc] init];
		_preferredContact = nil;
		_listContacts = nil;
		_listContactsIncludingOfflineAccounts = nil;
		
		containedObjects = [[NSMutableArray alloc] init];
		
		isExpandable = [[self preferenceForKey:KEY_IS_EXPANDABLE
										 group:OBJECT_STATUS_CACHE] boolValue];

		expanded = [[self preferenceForKey:KEY_EXPANDED
									 group:OBJECT_STATUS_CACHE] boolValue];

		containsOnlyOneUniqueContact = NO;
		containsOnlyOneService = YES;
		containedObjectsNeedsSort = NO;
		delayContainedObjectSorting = NO;
		saveGroupingChanges = YES;
		
		largestOrder = 1.0;
		smallestOrder = 1.0;
	}
	return self;
}

//dealloc
- (void)dealloc
{
	[statusCacheDict release];
	[containedObjects release];

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
		inGroupInternalObjectID &&
		![inGroupInternalObjectID isEqualToString:[self preferenceForKey:KEY_CONTAINING_OBJECT_ID
																   group:OBJECT_STATUS_CACHE
												   ignoreInheritedValues:YES]] &&
		(inGroup != [[adium contactController] offlineGroup])) {

		[self setPreference:inGroupInternalObjectID
					 forKey:KEY_CONTAINING_OBJECT_ID
					  group:OBJECT_STATUS_CACHE];
	}

	[super setContainingObject:inGroup];
}

/*!
 * @brief Restore the AIListGroup grouping into which this object was last manually placed
 *
 * If the contact is offline and we are using the offline group, place it there.
 * If no manual placement has been performed previously, use the first remote grouping of a contained contact.
 */
- (void)restoreGrouping
{
	if ([[adium contactController] useContactListGroups]) {
		AIListGroup		*targetGroup = nil;

		if (![self online] &&
			[[adium contactController] useOfflineGroup]) {
			targetGroup = [[adium contactController] offlineGroup];

		} else {
			NSString		*oldContainingObjectID;
			AIListObject	*oldContainingObject;

			oldContainingObjectID = [self preferenceForKey:KEY_CONTAINING_OBJECT_ID
													 group:OBJECT_STATUS_CACHE];
			//Get the group's UID out of the internal object ID by taking the substring after "Group."
			oldContainingObject = ((oldContainingObjectID  && [oldContainingObjectID hasPrefix:@"Group."]) ?
								   [[adium contactController] groupWithUID:[oldContainingObjectID substringFromIndex:6]] :
								   nil);
			
			if (oldContainingObject &&
				[oldContainingObject isKindOfClass:[AIListGroup class]] &&
				oldContainingObject != [[adium contactController] contactList]) {
				//A previous grouping (to a non-root group) is saved; restore it
				targetGroup = (AIListGroup *)oldContainingObject;

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
					   !(bestGuessRemoteGroup = [containedContact remoteGroupName]));
				
				//Put this metacontact in that group
				if (bestGuessRemoteGroup) {
					targetGroup = [[adium contactController] groupWithUID:bestGuessRemoteGroup];
				}
			}
		}

		if (targetGroup) {
			[[adium contactController] _moveContactLocally:self
												   toGroup:targetGroup];
		}
	} else {
		[[adium contactController] _moveContactLocally:self
											   toGroup:[[adium contactController] contactList]];		
	}
}

//A metaContact should never be a stranger
- (BOOL)isStranger
{
	return NO;
}

/*!
 * @brief Are all the contacts in this meta blocked?
 *
 * @result Boolean flag indicating if all the listContacts are blocked
 */
- (BOOL)isBlocked
{
	BOOL			allContactsBlocked = ([[self listContacts] count] ? YES : NO);
	NSEnumerator	*enumerator = [[self listContacts] objectEnumerator];
	AIListContact	*currentContact = nil;
	
	while ((currentContact = [enumerator nextObject])) {
		//find any unblocked contacts
		if (![currentContact isBlocked]) {
			allContactsBlocked = NO;
			break;
		}
	}
	
	return allContactsBlocked;
}

/*!
 * @brief Block each contact contained in the meta
 */
- (void)setIsBlocked:(BOOL)yesOrNo updateList:(BOOL)addToPrivacyLists
{
	NSEnumerator	*contactEnumerator = [[self listContacts] objectEnumerator];
	AIListContact	*currentContact = nil;
	
	//attempt to block entire meta
	while ((currentContact = [contactEnumerator nextObject])) {
		[currentContact setIsBlocked:yesOrNo updateList:addToPrivacyLists];
	}
	
	//update property if we are completely blocked
	[self setValue:([self isBlocked] ? [NSNumber numberWithBool:YES] : nil)
				   forProperty:KEY_IS_BLOCKED 
				   notify:NotifyNow];
}

//Object Storage -------------------------------------------------------------------------------------------------------
#pragma mark Object Storage
- (void)clearContainedObjectInfoCache
{
	_preferredContact = nil;
	[_listContacts release]; _listContacts = nil;
	[_listContactsIncludingOfflineAccounts release]; _listContactsIncludingOfflineAccounts = nil;
	
	//Our effective icon may have changed
	[AIUserIcons flushCacheForObject:self];
}

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
		
		[self clearContainedObjectInfoCache];
		
		//If we were unique before, check if we will still be unique after adding this contact.
		//If we were not, no checking needed.
		if (containsOnlyOneUniqueContact) {
			[self _determineIfWeShouldAppearToContainOnlyOneContact];
		}

		//Add the object from our status cache, notifying of the changes (silently) as appropriate
		[self _updateCachedStatusOfObject:inObject];

		if ([inObject isKindOfClass:[AIListContact class]] && [(AIListContact *)inObject remoteGroupName]) {
			//Force an immediate update of our listContacts list, which will also update our visible count
			[self listContacts];
		}
		
		//Update the object's display name to be the same as ours if we have one set, otherwise clear it
		if ([[self displayArrayForKey:@"Display Name"] objectValue]) {
			[inObject setDisplayName:[self displayName]];
		} else {
			[inObject setDisplayName:nil];
		}

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
		BOOL	noteRemoteGroupingChanged = NO;

		[inObject retain];
		
		[containedObjects removeObject:inObject];
		
		if ([inObject isKindOfClass:[AIListContact class]] && [(AIListContact *)inObject remoteGroupName]) {
			//Reset it to its remote group
			if ([inObject containingObject] == self)
				[inObject setContainingObject:nil];
			noteRemoteGroupingChanged = YES;
		} else {
			[inObject setContainingObject:[self containingObject]];
		}

		[self clearContainedObjectInfoCache];

		//Only need to check if we are now unique if we weren't unique before, since we've either become
		//unique are stayed the same.
		if (!containsOnlyOneUniqueContact) {
			[self _determineIfWeShouldAppearToContainOnlyOneContact];
		}

		//Remove all references to the object from our status cache; notifying of the changes as appropriate
		[self _removeCachedStatusOfObject:inObject];

		//If we remove our list object, don't continue to show up in the contact list
		if ([containedObjects count] == 0) {
			[self setContainingObject:nil];
		}

		/* Now that we're done reconfigured ourselves and the recently removed object,
		 * tell the contactController about the change in the removed object.
		 */
		if (noteRemoteGroupingChanged) {
			[[adium contactController] listObjectRemoteGroupingChanged:(AIListContact *)inObject];
		}

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
		NSArray			*listContacts = [self listContacts];
		AIListContact   *preferredContact = nil;
		AIListContact   *thisContact;
		unsigned		index;
		unsigned		count = [listContacts count];
		
		//Search for an available contact who is not mobile
		for (index = 0; index < count; index++) {
			thisContact = [listContacts objectAtIndex:index];
			if (([thisContact statusSummary] == AIAvailableStatus) &&
				(![thisContact isMobile])) {
				preferredContact = thisContact;
				break;
			}
		}
		
		//If no available contacts, find the first online contact
		if (!preferredContact) {
			for (index = 0; index < count; index++) {
				thisContact = [listContacts objectAtIndex:index];
				if ([thisContact online]) {
					preferredContact = thisContact;
					break;
				}
			}
		}

		//If no online contacts, find the first contact
		if (!preferredContact && (count != 0)) {
			preferredContact = [listContacts objectAtIndex:0];
		}

		//If no list contacts at all, try contacts on offline accounts
		if (!preferredContact) {
			if ([[self containedObjects] count]) {
				preferredContact = [[self containedObjects] objectAtIndex:0];
			}
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
- (AIListContact *)preferredContactWithCompatibleService:(AIService *)inService
{
	AIListContact   *returnContact = nil;
	
	if (inService) {
		NSString		*serviceClass = [inService serviceClass];
		NSArray			*listContactsArray = [self listContacts];
		AIListContact   *thisContact;
		unsigned		index;
		unsigned		count = [listContactsArray count];
		
		//Search for an available contact who is not mobile
		for (index = 0; index < count; index++) {
			thisContact = [listContactsArray objectAtIndex:index];
			if (([[[thisContact service] serviceClass] isEqualToString:serviceClass]) &&
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
					([[thisContact serviceClass] isEqualToString:serviceClass])) {
					returnContact = thisContact;
					break;
				}
			}
		}
		
		if (!returnContact) {
			for (index = 0; index < count; index++) {
				thisContact = [listContactsArray objectAtIndex:index];
				if ([[thisContact serviceClass] isEqualToString:serviceClass]) {
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
		unsigned		count;
		
		_listContacts = [[self uniqueContainedListContactsIncludingOfflineAccounts:NO] retain];

		/* Only notify if there is a change.
		 * Use super's implementation as we don't need to be searching our contained objects...
		 */
		count = [_listContacts count];
		if ([super integerValueForProperty:@"VisibleObjectCount"] != count) {
			[self setValue:(count ? [NSNumber numberWithInt:count] : nil)
						   forProperty:@"VisibleObjectCount"
						   notify:NotifyNow];
		}
	}
	
	return _listContacts;
}

- (NSArray *)listContactsIncludingOfflineAccounts
{
	if (!_listContactsIncludingOfflineAccounts) {
		_listContactsIncludingOfflineAccounts = [[self uniqueContainedListContactsIncludingOfflineAccounts:YES] retain];
	}

	return _listContactsIncludingOfflineAccounts;
}

/*!
 * @brief Dictionary of service classes and list contacts
 *
 * @result A dictionary whose keys are serviceClass strings and whose objects are arrays of contained contacts *on online accounts* on that serviceClass.
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

/**
 * @brief Return an array of unique contained list contacts, optionally including those for offline accounts
 *
 * This is a reasonably expensive call; its return value is cached by -[self listContacts] and -[self listContactsIncludingOfflineAccounts],
 * so those are the methods to use externally.
 *
 * Implementation note: uniqueObjectIDs is an array because its indexing matches the indexing of the nascent listContacts array;
 * this allows a fast comparison for existing contacts.
 */
- (NSArray *)uniqueContainedListContactsIncludingOfflineAccounts:(BOOL)includeOfflineAccounts
{
	NSArray			*myContainedObjects = [self containedObjects];
	NSMutableArray	*listContacts = [[NSMutableArray alloc] init];
	NSMutableArray	*uniqueObjectIDs = [[NSMutableArray alloc] initWithCapacity:[myContainedObjects count]];
	unsigned		index;
	unsigned		count = [myContainedObjects count];
	
	//Search for an available contact
	for (index = 0; index < count; index++) {
		AIListObject	*listObject = [myContainedObjects objectAtIndex:index];

		if (([listObject isKindOfClass:[AIListContact class]]) &&
			([(AIListContact *)listObject remoteGroupName] || includeOfflineAccounts)) {

			NSString        *listObjectInternalObjectID = [listObject internalObjectID]; 
			unsigned int listContactIndex = [uniqueObjectIDs indexOfObject:listObjectInternalObjectID]; 
			
			if (listContactIndex == NSNotFound) { 
				//This contact isn't in the array yet, so add it 
				[listContacts addObject:listObject]; 
				[uniqueObjectIDs addObject:listObjectInternalObjectID]; 
				
			} else { 
				/* If it is found, but it is offline and this contact is online, swap 'em out so our array 
				 * has the best possible listContacts (making display elsewhere more straightforward) 
				 */ 
				if (![[listContacts objectAtIndex:listContactIndex] online] && 
					[listObject online]) { 
					
					[listContacts replaceObjectAtIndex:listContactIndex 
											withObject:listObject]; 
				}
            }
		}
	}
	
	[uniqueObjectIDs release];
	
	return [listContacts autorelease];
}

- (BOOL)containsOnlyOneUniqueContact
{
	return containsOnlyOneUniqueContact;
}

- (BOOL)containsOnlyOneService
{
	containsOnlyOneService = YES;

	NSEnumerator	*enumerator = [[self listContacts] objectEnumerator];
	AIListObject	*listObject = [enumerator nextObject];
	AIService		*firstService = [listObject service];

	//If any of the services are different from the initial service, then we have multiple contained services
	while ((listObject = [enumerator nextObject])) {
		if ([listObject service] != firstService) {
			containsOnlyOneService = NO;
			break;
		}
	}
	
	return containsOnlyOneService;
}

- (BOOL)canContainOtherContacts {
    return YES;
}

//When the listContacts array has a single member, we only contain one unique contact.
- (void)_determineIfWeShouldAppearToContainOnlyOneContact
{
	BOOL oldOnlyOne = containsOnlyOneUniqueContact;
	unsigned listContactsCount;

	//Clear our preferred contact so the next call to it will update the preferred contact
	[self clearContainedObjectInfoCache];

	listContactsCount = [[self listContacts] count];

	containsOnlyOneUniqueContact = (listContactsCount < 2);

	//If it changed, do stuff
	if (oldOnlyOne != containsOnlyOneUniqueContact) {
		[self updateDisplayName];
	}
}

- (void)remoteGroupingOfContainedObject:(AIListObject *)inListObject changedTo:(NSString *)inRemoteGroupName
{
#ifdef META_GROUPING_DEBUG
	AILog(@"AIMetaContact: Remote grouping of %@ changed to %@",inListObject,inRemoteGroupName);
#endif
	
	//When a contact has its remote grouping changed, this may mean it is now listed on an online account.
	//We therefore update our containsOnlyOneContact boolean.
	[self _determineIfWeShouldAppearToContainOnlyOneContact];
	
	//It's possible we didn't know to be in a group before if all our contained contacts were also groupless.
	if (![self containingObject] ||
		(![[adium contactController] useContactListGroups] && ([self containingObject] != [[adium contactController] contactList]))) {
		[self restoreGrouping];
	}
}

//Property Handling -----------------------------------------------------------------------------------------------
#pragma mark Property Handling
//Update our status cache as object we contain change status
- (void)object:(id)inObject didSetValue:(id)value forProperty:(NSString *)key notify:(NotifyTiming)notify
{
	//Clear our cached _preferredContact if a contained object's online, away, or idle status changed
	BOOL	shouldNotify = NO;
	
	//If the online status of a contained object changed, we should also check if our one-contact-only
	//in terms of online contacts has changed
	if ([key isEqualToString:@"Online"]) {
		_preferredContact = nil;
		[self _determineIfWeShouldAppearToContainOnlyOneContact];
		shouldNotify = YES;
	}
	
	if ([key isEqualToString:@"StatusType"] ||
		[key isEqualToString:@"IdleSince"] ||
		[key isEqualToString:@"IsIdle"] ||
		[key isEqualToString:@"IsMobile"] ||
		[key isEqualToString:@"StatusMessage"]) {
		_preferredContact = nil;
		shouldNotify = YES;
	}
	
	/* Only tell super that we changed if _cacheStatusValue returns YES indicating we did or if our
	 * preferred contact changed. Only deteremine if the cache changed if we're not already planning to notify. */
	if ([self _cacheStatusValue:value forObject:inObject key:key notify:notify determineIfChanged:!shouldNotify] ||
	   shouldNotify) {
		[super object:self didSetValue:value forProperty:key notify:notify];
	}
}

//---- Default property behavior ----
//Retrieve a property for this object - return the value of our preferredContact, 
//returning nil if our preferredContact returns nil.

- (id)valueForProperty:(NSString *)key
{
	return [self valueForProperty:key fromAnyContainedObject:YES];
}
- (int)integerValueForProperty:(NSString *)key
{
	return [self integerValueForProperty:key fromAnyContainedObject:YES];
}
- (NSDate *)earliestDateValueForProperty:(NSString *)key
{
	return [self earliestDateValueForProperty:key fromAnyContainedObject:YES];
}
- (NSNumber *)numberValueForProperty:(NSString *)key
{
	return [self numberValueForProperty:key fromAnyContainedObject:YES];
}
- (NSString *)stringFromAttributedStringValueForProperty:(NSString *)key
{
	return [self stringFromAttributedStringValueForProperty:key fromAnyContainedObject:YES];
}

//---- fromAnyContainedObject property behavior ----
//If fromAnyContainedObject is YES, return the best value from any contained object if the preferred object returns nil.
//If it is NO, only look at the preferred object.

//General property
- (id)valueForProperty:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self _valueForProperty:key containedObjectSelector:(fromAnyContainedObject ? @selector(objectValue) : nil)];
}

//NSDate
- (NSDate *)earliestDateValueForProperty:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self _valueForProperty:key containedObjectSelector:(fromAnyContainedObject ? @selector(date) : nil)];
}

//NSNumber
- (NSNumber *)numberValueForProperty:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [self _valueForProperty:key containedObjectSelector:(fromAnyContainedObject ? @selector(numberValue) : nil)];
}

//Integer (uses numberValueForProperty:)
- (int)integerValueForProperty:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	NSNumber *returnValue = [self numberValueForProperty:key fromAnyContainedObject:fromAnyContainedObject];
	
    return returnValue ? [returnValue intValue] : 0;
}

//String from attributed string (uses valueForProperty:)
- (NSString *)stringFromAttributedStringValueForProperty:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject
{
	return [[self valueForProperty:key fromAnyContainedObject:fromAnyContainedObject] string];
}

//Returns the property from our object.
//If no such object is found, return the property from the preferredContact for a given key.
//If no such object is found, and containedObjectSelector is not nil, 
//queries the entire mutableOwnerArray using that selector.
- (id)_valueForProperty:(NSString *)key containedObjectSelector:(SEL)containedObjectSelector
{
	id					returnValue;

	if (!(returnValue = [super valueForProperty:key])) {
		AIMutableOwnerArray *keyArray = [statusCacheDict objectForKey:key];
		
		returnValue = [keyArray objectWithOwner:[self preferredContact]];
		
		//If we got nil and we want to look at our contained objects, return the objectValue
		if (!returnValue && containedObjectSelector) {
			returnValue = [keyArray performSelector:containedObjectSelector];
		}
	}
	
	return returnValue;
}

#pragma mark Attribute arrays
/**
 * @brief Request that Adium update our display name based on our current information
 */
- (void)updateDisplayName
{
	[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
											  object:self
											userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																				 forKey:@"Notify"]];
}

- (void)listObject:(AIListObject *)listObject mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(AIListObject *)inOwner priorityLevel:(float)priority
{
	if ((listObject != self) &&
		(inArray == [listObject displayArrayForKey:@"Display Name" create:NO]) &&
		(!anObject || ([anObject isEqualToString:[inArray objectValue]]))) {
		/* One of our contained objects changed its display name in such a  way that its Display Name array's objectValue changed. 
		 * Our own display name may need to change in turn.
		 * We used isEqualToString above because the Display Name array contains NSString objects.
		 * 
		 * Wait until the next run loop so that all observers of the changed contained object have done their thing; as a metaContact, our return values
		 * may be based on this contact's values.
		 */
		[self performSelector:@selector(updateDisplayName)
				   withObject:nil
				   afterDelay:0];
	}
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
	NSEnumerator	*enumerator = [inObject propertyEnumerator];
	NSString		*key;
	
	while ((key = [enumerator nextObject])) {
		id value = [inObject valueForProperty:key];

		//Only tell super that we changed if _cacheStatusValue returns YES indicating we did
		if ([self _cacheStatusValue:value forObject:inObject key:key notify:NotifyLater determineIfChanged:YES]) {
			[super object:self didSetValue:value forProperty:key notify:NotifyLater];
		}
	}
	
	[self notifyOfChangedPropertiesSilently:YES];
}

//Flush all status values of the passed object from our cache
- (void)_removeCachedStatusOfObject:(AIListObject *)inObject
{
	NSEnumerator	*enumerator = [inObject propertyEnumerator];
	NSString		*key;
	
	while ((key = [enumerator nextObject])) {
		//Only tell super that we changed if _cacheStatusValue returns YES indicating we did
		if ([self _cacheStatusValue:nil forObject:inObject key:key notify:NotifyLater determineIfChanged:YES]) {
			[super object:self didSetValue:[self valueForProperty:key] forProperty:key notify:NotifyLater];
		}
	}
	
	[self notifyOfChangedPropertiesSilently:YES];
}

//Update a value in our status cache
- (BOOL)_cacheStatusValue:(id)inObject forObject:(id)inOwner key:(NSString *)key notify:(BOOL)notify determineIfChanged:(BOOL)determineIfChanged
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
	if (determineIfChanged) {
		newObjectValue = [array objectWithOwner:[self preferredContact]];
		if (!newObjectValue) newObjectValue = [array objectValue];

		if (newObjectValue != previousObjectValue) {
			changed = YES;
		}
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
/** 
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
	NSImage		 *internalUserIcon = [self internalUserIcon];
	NSImage		 *userIcon = internalUserIcon;
	AIListObject *sourceListObject = self;

	BOOL	useOwnIconAsLastResort = NO;

	id <AIUserIconSource> myUserIconSource = [AIUserIcons userIconSourceForObject:self];
	if (myUserIconSource) {
		if ([myUserIconSource priority] > AIUserIconMediumPriority) {
			/* If our own user iocn if it is at less than medium priority, don't use it unless
			 * we find nothing else; this allows a contact's serverside icon to still be used if desired.
			 */
			useOwnIconAsLastResort = YES;
			userIcon = nil;
			sourceListObject = nil;
		}
	}
	
	if (!userIcon) {
		sourceListObject = [self preferredContact];
		userIcon = [sourceListObject userIcon];
	}
	if (!userIcon) {
		NSArray		*theContainedObjects = [self listContacts];

		unsigned int count = [theContainedObjects count];
		unsigned int i = 0;
		while ((i < count) && !userIcon) {
			sourceListObject = [theContainedObjects objectAtIndex:i];
			userIcon = [sourceListObject userIcon];
			i++;
		}
	}

	if (!userIcon && useOwnIconAsLastResort) {
		sourceListObject = self;
		userIcon = internalUserIcon;
	}

	if (userIcon && (sourceListObject != self)) {
		[AIUserIcons setActualUserIcon:userIcon
							 andSource:[AIUserIcons userIconSourceForObject:sourceListObject]
							 forObject:self];
	}

	return userIcon;
}

- (NSString *)displayName
{
	NSString	*displayName = [[self displayArrayForKey:@"Display Name"] objectValue];
	
	if (!displayName) {
		displayName = [[self preferredContact] ownDisplayName];
	}

	return displayName;
}

/*!
 * @brief Set our display name
 *
 * This also sets the display name of all contained objects to be the same as ours.
 *
 * @param alias The new display name to be set.
 */
- (void)setDisplayName:(NSString *)alias
{
	NSEnumerator		*enumerator = [[self containedObjects] objectEnumerator];
	AIListObject		*listObject;
	
	while ((listObject = [enumerator nextObject])) {
		[listObject setDisplayName:alias];
	}
	
	[super setDisplayName:alias];
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
	return [[self preferredContact] valueForProperty:@"StatusName"];
}

- (AIStatusType)statusType
{
	NSNumber		*statusTypeNumber = [[self preferredContact] valueForProperty:@"StatusType"];
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
	
	//Try to use an actual status message first
	enumerator = [[self listContacts] objectEnumerator];
	while (!contactListStatusMessage && (listContact = [enumerator nextObject])) {
		contactListStatusMessage = [listContact statusMessage];
	}

	if (!contactListStatusMessage) {
		//Next go for any contact list status message, which may include a display name or the name of a status such as "BRB"
		enumerator = [[self listContacts] objectEnumerator];
		while (!contactListStatusMessage && (listContact = [enumerator nextObject])) {
			contactListStatusMessage = [listContact contactListStatusMessage];
		}		
	}

	if (!contactListStatusMessage) {
		return [self statusMessage];
	}

	return contactListStatusMessage;
}

/**
 * @brief Are sounds for this contact muted?
 */
- (BOOL)soundsAreMuted
{
	return [[[[self preferredContact] account] statusState] mutesSound];
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

/*!
 * @brief Are multiple contacts represented by this metacontact?
 */
- (BOOL)containsMultipleContacts
{
    return !containsOnlyOneUniqueContact;
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

- (NSString *)contentsBasedIdentifier
{
	return [self internalObjectID];
}

//Expanded State -------------------------------------------------------------------------------------------------------
#pragma mark Expanded State
//Set the expanded/collapsed state of this group (PRIVATE: For the contact list view to let us know our state)
- (void)setExpanded:(BOOL)inExpanded
{
	if (expanded != inExpanded) {
		expanded = inExpanded;
		
		[self setPreference:[NSNumber numberWithBool:expanded]
					 forKey:KEY_EXPANDED
					  group:OBJECT_STATUS_CACHE];
	
	}
}
//Returns the current expanded/collapsed state of this group
- (BOOL)isExpanded
{
    return expanded;
}

- (void)setExpandable:(BOOL)inExpandable
{
	if (inExpandable != isExpandable) {
		isExpandable = inExpandable;

		[self setPreference:[NSNumber numberWithBool:isExpandable]
					 forKey:KEY_IS_EXPANDABLE
					  group:OBJECT_STATUS_CACHE];
		
		[[adium notificationCenter] postNotificationName:AIDisplayableContainedObjectsDidChange
												  object:self];
	}
}

- (BOOL)isExpandable
{
	return isExpandable && !containsOnlyOneUniqueContact;
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

	[self clearContainedObjectInfoCache];
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
		[self clearContainedObjectInfoCache];		
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

	return [NSString stringWithFormat:@"<%@:%x %@: %@>",NSStringFromClass([self class]), self, [self internalObjectID], subobjectDescsDesc];
}

@end
