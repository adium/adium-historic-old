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

// $Id: AIContactController.m,v 1.165 2004/08/04 04:08:54 dchoby98 Exp $

#import "AIContactController.h"
#import "AIAccountController.h"
#import "AIContactInfoWindowController.h"

#define PREF_GROUP_CONTACT_LIST		@"Contact List"			//Contact list preference group
#define KEY_FLAT_GROUPS				@"FlatGroups"			//Group storage
#define KEY_FLAT_CONTACTS			@"FlatContacts"			//Contact storage
#define KEY_FLAT_METACONTACTS		@"FlatMetaContacts"		//Metacontact objectID storage

#define VIEW_CONTACTS_INFO  		AILocalizedString(@"View Contact's Info",nil)
#define VIEW_INFO	    			AILocalizedString(@"View Info",nil)
#define ALTERNATE_GET_INFO_MASK		(NSCommandKeyMask | NSShiftKeyMask | NSAlternateKeyMask)

#define UPDATE_CLUMP_INTERVAL		1.0

#define TOP_METACONTACT_ID			@"TopMetaContactID"
#define KEY_IS_METACONTACT			@"isMetaContact"
#define KEY_OBJECTID				@"objectID"
#define KEY_METACONTACT_OWNERSHIP   @"MetaContact Ownership"
#define CONTACT_DEFAULT_PREFS		@"ContactPrefs"

#warning Nested metaContacts make a coding mess.. probably should avoid them if at all possible.

@interface AIContactController (PRIVATE)
- (AIListGroup *)processGetGroupNamed:(NSString *)serverGroup;
- (void)processCorrectlyPositionContact:(AIListContact *)contact;
- (void)breakDownContactList;
- (void)breakDownGroup:(AIListGroup *)inGroup;
- (float)_setOrderIndexOfKey:(NSString *)key to:(float)index;
- (void)_addDelayedUpdate;
- (void)_performDelayedUpdates:(NSTimer *)timer;
- (void)loadContactList;
- (void)saveContactList;
- (NSArray *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSArray *)modifiedKeys silent:(BOOL)silent;
- (void)_updateAllAttributesOfObject:(AIListObject *)inObject;
- (void)prepareContactInfo;

- (NSMenu *)menuOfAllContactsInGroup:(AIListGroup *)inGroup withTarget:(id)target firstLevel:(BOOL)firstLevel;
- (void)_menuOfAllGroups:(NSMenu *)menu forGroup:(AIListGroup *)group withTarget:(id)target level:(int)level;

- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector;
- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector conformingToProtocol:(Protocol *)protocol;

- (NSArray *)_arrayRepresentationOfListObjects:(NSArray *)listObjects;
- (NSDictionary *)_compressedOrderingOfObject:(AIListObject *)inObject;
- (void)_applyCompressedOrdering:(NSDictionary *)orderDict toObject:(AIListObject *)inObject;
- (void)_loadContactsFromArray:(NSArray *)array;
- (void)_loadGroupsFromArray:(NSArray *)array;

- (void)_listChangedGroup:(AIListObject *)group object:(AIListObject *)object;

- (void)_positionObject:(AIListObject *)listObject atIndex:(int)index inGroup:(AIListGroup *)group;
- (void)_moveObject:(AIListObject *)listObject toGroup:(AIListGroup *)group;
- (void)_renameGroup:(AIListGroup *)listGroup to:(NSString *)newName;

//MetaContacts
- (AIMetaContact *)metaContactWithObjectID:(NSNumber *)inObjectID;
- (void)_restoreContactsToMetaContact:(AIMetaContact *)metaContact;
- (void)addListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact;
- (BOOL)_performAddListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact;
- (void)removeListObject:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact;
- (NSArray *)allMetaContactsInGroup:(AIListGroup *)inGroup;
- (void)_loadMetaContactsFromArray:(NSArray *)array;
- (void)_saveMetaContacts:(NSDictionary *)allMetaContactsDict;

- (NSArray *)allContactsWithService:(NSString *)inServiceID UID:(NSString *)inUID;

@end

//Used to suppress compiler warnings
@interface NSObject (_RESPONDS_TO_LIST_OBJECT)
- (AIListObject *)listObject;
@end

DeclareString(ServiceID);
DeclareString(AccountID);
DeclareString(UID);

@implementation AIContactController

//init
- (void)initController
{
    InitString(ServiceID,@"ServiceID");
	InitString(AccountID,@"AccountID");
	InitString(UID,@"UID");
	
	//Default account preferences
	[[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:CONTACT_DEFAULT_PREFS 
																		forClass:[self class]]
										  forGroup:PREF_GROUP_CONTACT_LIST];
    //
    contactObserverArray = [[NSMutableArray alloc] init];
    sortControllerArray = [[NSMutableArray alloc] init];
    activeSortController = nil;
    delayedStatusChanges = 0;
	delayedModifiedStatusKeys = [[NSMutableSet alloc] init];
	delayedAttributeChanges = 0;
	delayedModifiedAttributeKeys = [[NSMutableSet alloc] init];
    delayedContactChanges = 0;
	delayedUpdateRequests = 0;
	updatesAreDelayed = NO;
	
	//
	contactDict = [[NSMutableDictionary alloc] init];
	groupDict = [[NSMutableDictionary alloc] init];
	metaContactDict = [[NSMutableDictionary alloc] init];
	contactToMetaContactLookupDict = [[NSMutableDictionary alloc] init];
	
	contactList = [[AIListGroup alloc] initWithUID:ADIUM_ROOT_GROUP_NAME];
	largestOrder = 1.0;
	smallestOrder = 1.0;

	//
	[self prepareContactInfo];
	
	// AIContactStatusEvents Stuff
    onlineDict = [[NSMutableDictionary alloc] init];
    awayDict = [[NSMutableDictionary alloc] init];
    idleDict = [[NSMutableDictionary alloc] init];
}

//finish initing
- (void)finishIniting
{
	[self loadContactList];
	[self sortContactList];
}

//close
- (void)closeController
{
	[self saveContactList];
}

//dealloc
- (void)dealloc
{
    [contactList release];
    [contactObserverArray release]; contactObserverArray = nil;
//    [contactInfoCategory release];

    [super dealloc];
}

//Local Contact List Storage -------------------------------------------------------------------------------------------
#pragma mark Local Contact List Storage
//Load the contact list
- (void)loadContactList
{	
	//We must load all the groups before loading contacts for the ordering system to work correctly.
	[self _loadGroupsFromArray:[[owner preferenceController] preferenceForKey:KEY_FLAT_GROUPS
																		group:PREF_GROUP_CONTACT_LIST]];
	[self _loadContactsFromArray:[[owner preferenceController] preferenceForKey:KEY_FLAT_CONTACTS
																		  group:PREF_GROUP_CONTACT_LIST]];
	[self _loadMetaContactsFromArray:[[owner preferenceController] preferenceForKey:KEY_FLAT_METACONTACTS
																			  group:PREF_GROUP_CONTACT_LIST]];
}

//Save the contact list
- (void)saveContactList
{
	[[owner preferenceController] setPreference:[self _arrayRepresentationOfListObjects:[groupDict allValues]]
										 forKey:KEY_FLAT_GROUPS
										  group:PREF_GROUP_CONTACT_LIST];	
	[[owner preferenceController] setPreference:[self _arrayRepresentationOfListObjects:[contactDict allValues]]
										 forKey:KEY_FLAT_CONTACTS
										  group:PREF_GROUP_CONTACT_LIST];
}

//Return the current largest order index + 1
//- (float)largestOrderIndex
//{
//	largestOrder += 1;
//	return(largestOrder);
//}

//List objects from flattened array
- (void)_loadContactsFromArray:(NSArray *)array
{
	NSEnumerator	*enumerator = [array objectEnumerator];
	NSDictionary	*infoDict;
	
	NSString	*Ordering = @"Ordering";
	
	while(infoDict = [enumerator nextObject]){
		AIListObject	*object = nil;
		
		//Object
		object = [self contactWithService:[infoDict objectForKey:ServiceID]
								accountID:[infoDict objectForKey:AccountID]
									  UID:[infoDict objectForKey:UID]];
		//Ordering
		if(object){
			float orderIndex = [[infoDict objectForKey:Ordering] floatValue];
			
			if(orderIndex > largestOrder) largestOrder = orderIndex;
			if(orderIndex < smallestOrder) smallestOrder = orderIndex;
			
			[object setOrderIndex:orderIndex];
		}
	}
}

//List objects from flattened array
- (void)_loadGroupsFromArray:(NSArray *)array
{
	NSEnumerator	*enumerator = [array objectEnumerator];
	NSDictionary	*infoDict;
	
	NSString	*Expanded = @"Expanded";
	NSString	*Ordering = @"Ordering";
	
	while(infoDict = [enumerator nextObject]){
		AIListObject	*object = nil;
		
		object = [self groupWithUID:[infoDict objectForKey:UID]];
		[(AIListGroup *)object setExpanded:[[infoDict objectForKey:Expanded] boolValue]];
		
		//Ordering
		float orderIndex = [[infoDict objectForKey:Ordering] floatValue];
		
		if(orderIndex > largestOrder) largestOrder = orderIndex;
		if(orderIndex < smallestOrder) smallestOrder = orderIndex;
		
		[object setOrderIndex:orderIndex];
	}
}

- (void)_loadMetaContactsFromArray:(NSArray *)array
{
	NSEnumerator	*enumerator = [array objectEnumerator];
	NSString		*identifier;
		
	while (identifier = [enumerator nextObject]){
		NSNumber *objectID = [NSNumber numberWithInt:[[[identifier componentsSeparatedByString:@"-"] objectAtIndex:1] intValue]];
		[self metaContactWithObjectID:objectID];
	}
}

//Flattened array of the contact list content
- (NSArray *)_arrayRepresentationOfListObjects:(NSArray *)listObjects
{
	NSMutableArray	*array = [NSMutableArray array];
	NSEnumerator	*enumerator = [listObjects objectEnumerator];;
	AIListObject	*object;
	
	
	//Create temporary strings outside the loop
	NSString	*Contact = @"Contact";
	NSString	*Group = @"Group";
	NSString	*Type = @"Type";
	NSString	*Ordering = @"Ordering";
	NSString	*Expanded = @"Expanded";
	
	while(object = [enumerator nextObject]){
		if([object isKindOfClass:[AIListContact class]]){
			[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				Contact, Type,
				[object UID], UID,
				[(AIListContact *)object accountID], AccountID,
				[object serviceID], ServiceID,
				[NSNumber numberWithFloat:[object orderIndex]], Ordering,
				nil]];
			
		}else if([object isKindOfClass:[AIListGroup class]]){
			[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				Group, Type,
				[object UID], UID,
				[NSNumber numberWithBool:[(AIListGroup *)object isExpanded]], Expanded,
				[NSNumber numberWithFloat:[object orderIndex]], Ordering,
				nil]];
		}
	}
	
	return(array);
}


//Status and Display updates -------------------------------------------------------------------------------------------
#pragma mark Status and Display updates
//These delay Contact_ListChanged, ListObject_AttributesChanged, Contact_OrderChanged notificationsDelays, 
//sorting and redrawing to prevent redundancy when making a large number of changes
//Explicit delay.  Call endListObjectNotificationsDelay to end
- (void)delayListObjectNotifications
{
	delayedUpdateRequests++;
	updatesAreDelayed = YES;
}

//End an explicit delay
- (void)endListObjectNotificationsDelay
{
	delayedUpdateRequests--;
	if(delayedUpdateRequests == 0 && !delayedUpdateTimer){
		[self _performDelayedUpdates:nil];
	}
}

//Delay all list object notifications until a period of inactivity occurs.  This is useful for accounts that do not
//know when they have finished connecting but still want to mute events.
- (void)delayListObjectNotificationsUntilInactivity
{
    if(!delayedUpdateTimer){
		updatesAreDelayed = YES;
		delayedUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:UPDATE_CLUMP_INTERVAL 
															   target:self
															 selector:@selector(_performDelayedUpdates:) 
															 userInfo:nil 
															  repeats:YES] retain];
    }else{
		//Reset the timer
		[delayedUpdateTimer invalidate]; [delayedUpdateTimer release]; delayedUpdateTimer = nil;
		
		delayedUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:UPDATE_CLUMP_INTERVAL 
															   target:self
															 selector:@selector(_performDelayedUpdates:) 
															 userInfo:nil 
															  repeats:YES] retain];
	}
}

//Update the status of a list object.  This will update any information that is otherwise too expensive to update
//automatically, such as their profile.
- (void)updateListContactStatus:(AIListContact *)inContact
{
	//If we're dealing with a meta contact, update the status of the contacts contained within it
	if([inContact isKindOfClass:[AIMetaContact class]]){
		NSEnumerator	*enumerator = [(AIMetaContact *)inContact objectEnumerator];
		AIListContact	*contact;
		
		while(contact = [enumerator nextObject]){
			[self updateListContactStatus:contact];
		}
		
	}else{
		AIAccount	*account = [[owner accountController] accountWithObjectID:[inContact accountID]];
		
		[account updateContactStatus:inContact];

	}
}

//Compare containing groups to remote groups, and sync the local groups as necessary to match remote.
- (void)listObjectRemoteGroupingChanged:(AIListContact *)inObject
{
	NSString			*remoteGroup = [inObject remoteGroupName];
	AIListObject		*containingObject;
	AIListObject		*existingObject;
	
	containingObject = [inObject containingObject];

	if ([containingObject isKindOfClass:[AIMetaContact class]]){
		//If the object's 'group' is a metaContact, and that metaContact isn't in our list yet
		//use the object's remote grouping as our grouping.
		if (![containingObject containingObject] && [remoteGroup length]){
			//If no similar objects exist, we add this contact directly to the list
			AIListGroup *targetGroup = [self groupWithUID:remoteGroup];
			NSLog(@"****Putting %@ into %@",containingObject,targetGroup);
			[targetGroup addObject:containingObject]; 
			[self _listChangedGroup:targetGroup object:containingObject];
		}
		
	}else{
		//Remove this object from any local groups we have it in currently
		if(containingObject){
			//Remove the object
			[inObject retain];
			[(AIListGroup *)containingObject removeObject:inObject];
			
			[self _listChangedGroup:(AIListGroup *)containingObject object:inObject];
			[inObject release];
		}
		
		//Add this object to its new group
		if(remoteGroup){
			//Fun :)
			//remoteGroup = [NSString stringWithFormat:@"%@:%@",[inObject accountUID],remoteGroup];
			AIListGroup *localGroup;
			NSString	*inObjectServiceID = [inObject serviceID];
			NSString	*inObjectUID = [inObject UID];
			BOOL		performedGrouping = NO;
			
			localGroup = [self groupWithUID:remoteGroup];
			existingObject = [localGroup objectWithServiceID:inObjectServiceID UID:inObjectUID];

			if(existingObject){
				//If an object exists in this group with the same UID and serviceID, create a MetaContact
				//for the two.
				[self groupListContacts:[NSArray arrayWithObjects:inObject,existingObject,nil]];
				performedGrouping = YES;
				
			}else{
				//If no object exists in this group which matches, we should check if there is already
				//a MetaContact holding a matching ListContact, since we should include this contact in it
				
				NSEnumerator	*enumerator = [[self allMetaContactsInGroup:localGroup] objectEnumerator];
				AIMetaContact   *metaContact;
				while (metaContact = [enumerator nextObject]){
					if ([metaContact objectWithServiceID:inObjectServiceID
													 UID:inObjectUID]){
						break;
					}	
				}
				
				//If we found a metaContact to which we should add, do it.
				if (metaContact){
					[self addListObject:inObject toMetaContact:metaContact];
					performedGrouping = YES;
				}
				
			}
			
			if (!performedGrouping){
				//If no similar objects exist, we add this contact directly to the list
				[localGroup addObject:inObject];
				
				//Add
				[self _listChangedGroup:localGroup object:inObject];

			}
		}
	}
	
	//Update the stranger status of this object (Contacts are strangers if they exist in no group)
	[inObject setStatusObject:(remoteGroup == nil ? [NSNumber numberWithBool:YES] : nil) forKey:@"Stranger" notify:YES];
}

//Post a list grouping changed notification for the object and group
- (void)_listChangedGroup:(AIListObject *)group object:(AIListObject *)object
{
	if(updatesAreDelayed){
		delayedContactChanges++;
	}else{
		[[owner notificationCenter] postNotificationName:Contact_ListChanged 
												  object:object
												userInfo:(group ? [NSDictionary dictionaryWithObject:group forKey:@"containingObject"] : nil)];
	}
}

//Called after modifying a contact's status
// Silent: Silences all events, notifications, sounds, overlays, etc. that would have been associated with this status change
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    NSArray			*modifiedAttributeKeys;
	
    //Let all observers know the contact's status has changed before performing any sorting or further notifications
	modifiedAttributeKeys = [self _informObserversOfObjectStatusChange:inObject withKeys:inModifiedKeys silent:silent];

    //Resort the contact list
	if(updatesAreDelayed){
		delayedStatusChanges++;
		[delayedModifiedStatusKeys addObjectsFromArray:inModifiedKeys];
	}else{
		//We can safely skip sorting if we know the modified attributes will invoke a resort later
		if(![[self activeSortController] shouldSortForModifiedAttributeKeys:modifiedAttributeKeys] &&
		   [[self activeSortController] shouldSortForModifiedStatusKeys:inModifiedKeys]){
			[self sortListObject:inObject];
		}
	}
    
    //Post an attributes changed message (if necessary)
    if([modifiedAttributeKeys count]){
		[self listObjectAttributesChanged:inObject modifiedKeys:modifiedAttributeKeys];
    }
	
	//If this object is within a meta contact, we'll process the meta contact for these status changes
    AIListObject	*containingObject = [inObject containingObject];
    if(containingObject && [containingObject isKindOfClass:[AIMetaContact class]]){
		[self listObjectStatusChanged:containingObject modifiedStatusKeys:inModifiedKeys silent:silent];
	}
}

//Call after modifying an object's display attributes
//(When modifying display attributes in response to a status change, this is not necessary)
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSArray *)inModifiedKeys
{	
	if(updatesAreDelayed){
		delayedAttributeChanges++;
		[delayedModifiedAttributeKeys addObjectsFromArray:inModifiedKeys];
	}else{
        //Resort the contact list if necessary
        if([[self activeSortController] shouldSortForModifiedAttributeKeys:inModifiedKeys]){
			[self sortListObject:inObject];
        }
		
        //Post an attributes changed message
		[[owner notificationCenter] postNotificationName:ListObject_AttributesChanged
												  object:inObject
												userInfo:(inModifiedKeys ? [NSDictionary dictionaryWithObject:inModifiedKeys forKey:@"Keys"] : nil)];
	}
}

//Performs any delayed list object/handle updates
- (void)_performDelayedUpdates:(NSTimer *)timer
{
	BOOL	updatesOccured = (delayedStatusChanges || delayedAttributeChanges || delayedContactChanges);
	
	//Send out global attribute & status changed notifications (to cover any delayed updates)
	if(updatesOccured){
		BOOL shouldSort = NO;
		
		//Inform observers of any changes
		if(delayedContactChanges){
			[[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
			delayedContactChanges = 0;
			shouldSort = YES;
		}
		if (delayedStatusChanges){
			if([[self activeSortController] shouldSortForModifiedStatusKeys:[delayedModifiedStatusKeys allObjects]]){
				shouldSort = YES;
			}
			[delayedModifiedStatusKeys removeAllObjects];
			delayedStatusChanges = 0;
		}
		if(delayedAttributeChanges){
			if([[self activeSortController] shouldSortForModifiedAttributeKeys:[delayedModifiedAttributeKeys allObjects]]){
				shouldSort = YES;
			}			
			[[owner notificationCenter] postNotificationName:ListObject_AttributesChanged object:nil];
			[delayedModifiedAttributeKeys removeAllObjects];
			delayedAttributeChanges = 0;
		}
		
		//Sort only if necessary
		if (shouldSort){
			[self sortContactList];
		}
	}
	
    //If no more updates are left to process, disable the update timer
	//If there are no delay update requests, remove the hold
	if(!delayedUpdateTimer || !updatesOccured){
		if(delayedUpdateTimer){
			[delayedUpdateTimer invalidate];
			[delayedUpdateTimer release];
			delayedUpdateTimer = nil;
		}
		if(delayedUpdateRequests == 0){
			updatesAreDelayed = NO;
		}		
    }
}

#pragma mark Meta contacts
//Returns a metaContact with the specified object ID.  Pass nil to create a new, unique metaContact
- (AIMetaContact *)metaContactWithObjectID:(NSNumber *)inObjectID
{	
	AIMetaContact   *metaContact;
	BOOL			shouldRestoreContacts = YES;
	
	//If no object ID is provided, use the next available object ID
	//(MetaContacts should always have an individually unique object id)
	if(!inObjectID){
		int topID = [[[owner preferenceController] preferenceForKey:TOP_METACONTACT_ID
															  group:PREF_GROUP_CONTACT_LIST] intValue];
		inObjectID = [NSNumber numberWithInt:topID];
		[[owner preferenceController] setPreference:[NSNumber numberWithInt:([inObjectID intValue] + 1)]
											 forKey:TOP_METACONTACT_ID
											  group:PREF_GROUP_CONTACT_LIST];
		
		//No reason to waste time restoring contacts when none are in the meta contact yet.
		shouldRestoreContacts = NO;
	}
	
	//Look for a metacontact with this object ID.  If none is found, create one
	//and add its contained contacts to it.
	metaContact = [metaContactDict objectForKey:[inObjectID stringValue]];
	if (!metaContact){
		metaContact = [[[AIMetaContact alloc] initWithObjectID:inObjectID] autorelease];
		[metaContactDict setObject:metaContact forKey:[inObjectID stringValue]];
		
		if (shouldRestoreContacts){
			[self _restoreContactsToMetaContact:metaContact];
		}
	}
	
	return (metaContact);
}

- (void)_restoreContactsToMetaContact:(AIMetaContact *)metaContact
{
	NSDictionary	*allMetaContactsDict = [[owner preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																					group:PREF_GROUP_CONTACT_LIST];
	NSArray			*containedContactsArray = [allMetaContactsDict objectForKey:[metaContact uniqueObjectID]];
	NSDictionary	*containedContact;
	AIListContact	*listContact = nil;
	NSEnumerator	*enumerator = [containedContactsArray objectEnumerator];
	
	while (containedContact = [enumerator nextObject]){
		if ([[containedContact objectForKey:KEY_IS_METACONTACT] boolValue]){
			//This contained contact is a meta contact, so it'll just have an objectID
			listContact = [self metaContactWithObjectID:[containedContact objectForKey:KEY_OBJECTID]];
			[self _performAddListObject:listContact toMetaContact:metaContact];

	 	}else{
			//This contained contact is a regular AIListContact uniqueObjectID.  Get all matching contacts on all accounts.
			
			NSEnumerator	*contactEnumerator;
			contactEnumerator = [[self allContactsWithService:[containedContact objectForKey:ServiceID]
														  UID:[containedContact objectForKey:UID]] objectEnumerator];
			
			while (listContact = [contactEnumerator nextObject]){
				[self _performAddListObject:listContact toMetaContact:metaContact];
			}
		}
	}
}


//Add a list object to a meta contact, setting preferences and such 
//so the association is lasting across program launches.
- (void)addListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact
{
	AIMetaContact		*oldMetaContact;
	
	//Obtain any metaContact this listObject is current within, so we can remove it later
	oldMetaContact = [contactToMetaContactLookupDict objectForKey:[listObject ultraUniqueObjectID]];
	
	if ([self _performAddListObject:listObject toMetaContact:metaContact]){
		NSDictionary		*containedContactDict;
		NSMutableDictionary	*allMetaContactsDict;
		NSMutableArray		*containedContactsArray;
		
		NSString			*metaContactUniqueObjectID = [metaContact uniqueObjectID];

		//Get the dictionary of all metaContacts
		allMetaContactsDict = [[[[owner preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																		 group:PREF_GROUP_CONTACT_LIST] mutableCopy] autorelease];
		if (!allMetaContactsDict){
			allMetaContactsDict = [NSMutableDictionary dictionary];
		}
		
		if (metaContact != oldMetaContact){
			
			//Remove the list object from any other metaContact it is in at present
			if (oldMetaContact){
				[self removeListObject:listObject fromMetaContact:oldMetaContact];
			}
			
			//Load the array for the new metaContact
			containedContactsArray = [[[allMetaContactsDict objectForKey:metaContactUniqueObjectID] mutableCopy] autorelease];
			if (!containedContactsArray) containedContactsArray = [NSMutableArray array];
			containedContactDict = nil;
			
			//Create the dictionary describing this list object
			if ([listObject isKindOfClass:[AIMetaContact class]]){
				containedContactDict = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithBool:YES],KEY_IS_METACONTACT,
					[(AIMetaContact *)listObject objectID],KEY_OBJECTID,nil];
				
			}else if ([listObject isKindOfClass:[AIListContact class]]){
				containedContactDict = [NSDictionary dictionaryWithObjectsAndKeys:
					[listObject serviceID],ServiceID,
					[listObject UID],UID,nil];
			}
			
			//Only add if this dict isn't already in the array
			if (containedContactDict && ([containedContactsArray indexOfObject:containedContactDict] == NSNotFound)){
				[containedContactsArray addObject:containedContactDict];
				[allMetaContactsDict setObject:containedContactsArray forKey:metaContactUniqueObjectID];
				
				//Save
				[self _saveMetaContacts:allMetaContactsDict];
				
				[[owner contactAlertsController] mergeAndMoveContactAlertsFromListObject:listObject 
																		  intoListObject:metaContact];				
			}			
		}
	}
}

//Actually adds a list object to a meta contact. No preferences are changed.
//Attempts to add the list object, causing group reassignment and updates our contactToMetaContactLookupDict
//for quick lookup of the MetaContact given a AIListContact uniqueObjectID if successful.
- (BOOL)_performAddListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact
{
	BOOL success;
	
	AIListObject *localGroup = [listObject containingObject];

	//AIMetaContact will handle reassigning the list object's grouping to being itself
	if (success = [metaContact addObject:listObject]){
		[contactToMetaContactLookupDict setObject:metaContact forKey:[listObject ultraUniqueObjectID]];
				
		//Remove the object from its previous containing group
		if (localGroup){
			[localGroup removeObject:listObject];
			[self _listChangedGroup:localGroup object:listObject];
		}
		
		//Update the meta contact's attributes
		[self _updateAllAttributesOfObject:metaContact];
		
		//If the metaContact isn't in a group yet, use the group of the object we just added
		if ((![metaContact containingObject]) && localGroup){ 
			//Add the new meta contact to our list
			[localGroup addObject:metaContact];
			[self _listChangedGroup:localGroup object:metaContact];
		}
	}
	
	return success;
}

- (void)removeListObject:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact
{
	NSEnumerator		*enumerator;
	NSArray				*containedContactsArray;
	NSDictionary		*containedContactDict;
	NSMutableDictionary	*allMetaContactsDict;
	NSString			*metaContactUniqueObjectID = [metaContact uniqueObjectID];

	//Get the dictionary of all metaContacts
	allMetaContactsDict = [[owner preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																	 group:PREF_GROUP_CONTACT_LIST];
	
	
	//Load the array for the metaContact
	containedContactsArray = [allMetaContactsDict objectForKey:metaContactUniqueObjectID];
	
	//Enumerate it, looking only for the appropriate type of containedContactDict
	enumerator = [containedContactsArray objectEnumerator];
	
	if ([listObject isKindOfClass:[AIMetaContact class]]){
		NSNumber	*listObjectObjectID = [(AIMetaContact *)listObject objectID];
		
		while (containedContactDict = [enumerator nextObject]){
			if (([[containedContactDict objectForKey:KEY_IS_METACONTACT] boolValue]) &&
				(([(NSNumber *)[containedContactDict objectForKey:KEY_OBJECTID] compare:listObjectObjectID]) == 0)){
				break;
			}
		}
		
	}else if ([listObject isKindOfClass:[AIListContact class]]){
		
		NSString	*listObjectUID = [listObject UID];
		NSString	*listObjectServiceID = [listObject serviceID];
		
		while (containedContactDict = [enumerator nextObject]){
			if ([[containedContactDict objectForKey:UID] isEqualToString:listObjectUID] &&
				[[containedContactDict objectForKey:ServiceID] isEqualToString:listObjectServiceID]){
				break;
			}
		}
	}
	
	//If we found a matching dict (referring to our contact in the old metaContact), remove it and store the result
	if (containedContactDict){
		NSMutableArray *newContainedContactsArray;
		
		newContainedContactsArray = [[containedContactsArray mutableCopy] autorelease];
		[newContainedContactsArray removeObjectIdenticalTo:containedContactDict];
		
		[allMetaContactsDict setObject:newContainedContactsArray
								forKey:metaContactUniqueObjectID];
		
		[self _saveMetaContacts:allMetaContactsDict];
	}
	
	//The listObject can be within the metaContact without us finding a containedContactDict if we are removing multiple
	//listContacts referring to the same UID & serviceID combination - that is, on multiple accounts on the same service.
	//We therefore request removal of the object regardless of the if (containedContactDict) check above.
	[metaContact removeObject:listObject];
}


/*
 UIDsArray and servicesArray should be a paired set of arrays, with each index corresponding to
 a UID and a service, respectively, which together define a contact which should be included in the grouping

 Assumption: This is only called after the contact list is finished loading, which occurs via
 -(void)finishIniting above.
 */
- (AIMetaContact *)groupUIDs:(NSArray *)UIDsArray forServices:(NSArray *)servicesArray
{
	NSMutableArray  *contactsToGroupArray = [NSMutableArray array];
	
	int				count = [UIDsArray count];
	int				i;
	
	//Build an array of all contacts matching this description (multiple accounts on the same service listing
	//the same UID mean that we can have multiple AIListContact objects with a UID/service combination)
	for (i = 0; i < count; i++){
		[contactsToGroupArray addObjectsFromArray:[self allContactsWithService:[servicesArray objectAtIndex:i]
																		   UID:[UIDsArray objectAtIndex:i]]];
	}

	return([self groupListContacts:contactsToGroupArray]);
}

//Group an NSArray of AIListContacts, returning the meta contact into which they are added.
//This will reuse an existing metacontact (for one of the contacts in the array) if possible.
- (AIMetaContact *)groupListContacts:(NSArray *)contactsToGroupArray
{
	NSLog(@"groupListcontacts: Grouping %@",contactsToGroupArray);
	NSEnumerator	*enumerator;
	AIListContact   *listContact;
	AIMetaContact   *metaContact = nil;
	
	//Look for an existing MetaContact we can use.  The first one we find is the lucky winner.
	//
	//It is possible for one listContact to be currently within the metaContact while its twin sister on another
	//account is not, in the case that the latter account just signed on for the first time.  This is why we look
	//at the ultraUniqueObjectID, which is account-specific, causing a relatively cheap increase in computational
	//demands in terms of the search but a better behavior overall.
	enumerator = [contactsToGroupArray objectEnumerator];
	while ((listContact = [enumerator nextObject]) && (metaContact == nil)){
		metaContact = [contactToMetaContactLookupDict objectForKey:[listContact ultraUniqueObjectID]];
	}
	
	//Create a new MetaContact is we didn't find one.
	if (!metaContact) metaContact = [self metaContactWithObjectID:nil];
	
	//Add all these contacts to our MetaContact (some may already be present,
	//but that's fine, as nothing will happen).
	enumerator = [contactsToGroupArray objectEnumerator];
	while (listContact = [enumerator nextObject]){
		[self addListObject:listContact toMetaContact:metaContact];
	}
	
	return(metaContact);
}

- (void)breakdownAndRemoveMetaContact:(AIMetaContact *)metaContact
{
	//Remove the objects within it from being inside it
	NSArray				*containedObjects = [[[metaContact containedObjects] copy] autorelease];
	NSEnumerator		*metaEnumerator = [containedObjects objectEnumerator];
	AIListObject		*containingObject = [metaContact containingObject];
	AIListObject		*object;
	
	NSMutableDictionary *allMetaContactsDict = [[[[owner preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																						  group:PREF_GROUP_CONTACT_LIST] mutableCopy] autorelease];
	
	while (object = [metaEnumerator nextObject]){
		[self removeListObject:object fromMetaContact:metaContact];
	}
	
	//Then, procede to remove the metaContact
	
	//Protect!
	[metaContact retain];
	
	//Remove it from its containing group
	[containingObject removeObject:metaContact];
	
	NSString	*metaContactUniqueObjectID = [metaContact uniqueObjectID];
	
	//Remove our reference to it internally
	[metaContactDict removeObjectForKey:metaContactUniqueObjectID];
	
	//Remove it from the preferences dictionary
	[allMetaContactsDict removeObjectForKey:metaContactUniqueObjectID];
	
	//Post the list changed notification for the old containingObject
	[self _listChangedGroup:containingObject object:metaContact];
	
	//Protection is overrated.
	[metaContact release];
	
	//Save the updated allMetaContactsDict which no longer lists the metaContact
	[self _saveMetaContacts:allMetaContactsDict];
}

- (void)_saveMetaContacts:(NSDictionary *)allMetaContactsDict
{
//	[[owner preferenceController] delayPreferenceChangedNotifications:YES];

	[[owner preferenceController] setPreference:allMetaContactsDict
										 forKey:KEY_METACONTACT_OWNERSHIP
										  group:PREF_GROUP_CONTACT_LIST];
	[[owner preferenceController] setPreference:[allMetaContactsDict allKeys]
										 forKey:KEY_FLAT_METACONTACTS
										  group:PREF_GROUP_CONTACT_LIST];
//	[[owner preferenceController] delayPreferenceChangedNotifications:NO];
}

- (NSMenu *)menuOfContainedContacts:(AIListObject *)inContact forService:(NSString *)service withTarget:(id)target
{
	NSMenu		*contactMenu = [[NSMenu alloc] initWithTitle:@""];
	int			i;
	
	// If service is nil, get ALL contained contacts
	if( service ) {
		
		NSArray		*contactArray = [inContact containedObjects];
		NSImage *serviceImage = [[[[owner accountController] serviceControllerWithIdentifier:service] handleServiceType] menuImage];

		for( i = 0; i < [contactArray count]; i++ ) {
			AIListObject *current = [contactArray objectAtIndex:i];
			if( [[current serviceID] isEqualToString:service] ) {
				NSMenuItem *tempItem = [[NSMenuItem alloc] initWithTitle:[current displayName]
																  target:target
																  action:@selector(selectContainedContact:)
														   keyEquivalent:@""];
				[tempItem setRepresentedObject:current];
				[tempItem setImage:serviceImage];
				[contactMenu addItem:tempItem];
				[tempItem release];
			}
		}
		
	} else {
		NSDictionary	*serviceDict = [inContact dictionaryOfServicesAndContainedObjects];
		NSEnumerator	*enumerator = [serviceDict keyEnumerator];
		NSString		*currentID;
		
		// Run through each key (i.e. service id)
		while( currentID = [enumerator nextObject] ) {
			NSArray *contactArray = [serviceDict objectForKey:currentID];
			NSImage *serviceImage = [[[[owner accountController] serviceControllerWithIdentifier:currentID] handleServiceType] menuImage];

			for( i = 0; i < [contactArray count]; i++ ) {
				AIListObject *contact = [contactArray objectAtIndex:i];
				NSMenuItem *tempItem = [[NSMenuItem alloc] initWithTitle:[contact displayName]
															  target:target
															  action:@selector(selectContainedContact:)
													   keyEquivalent:@""];
				[tempItem setRepresentedObject:contact];
				[tempItem setImage:serviceImage];
				[contactMenu addItem:tempItem];
				[tempItem release];
			}
			
			[contactMenu addItem:[NSMenuItem separatorItem]];
		}
		
		// Remove the last separator
		[contactMenu removeItemAtIndex:([contactMenu numberOfItems]-1)];
		
	}
	
	return contactMenu;
}

- (NSMenu *)menuOfContainedContacts:(AIListObject *)inContact withTarget:(id)target
{
	return( [self menuOfContainedContacts:inContact forService:nil withTarget:target] );
}

//Contact Info --------------------------------------------------------------------------------
#pragma mark Contact Info
//Show info for the selected contact
- (IBAction)showContactInfo:(id)sender
{
	AIListObject *listObject = nil;
	
	if ((sender == menuItem_getInfoContextualContact) || (sender == menuItem_getInfoContextualGroup)){
		listObject = [[owner menuController] contactualMenuContact];
	}else{
		listObject = [self selectedListObject];
	}
	
	if (listObject){
		[AIContactInfoWindowController showInfoWindowForListObject:listObject];
	}
}

//Add a contact info view
- (void)addContactInfoPane:(AIContactInfoPane *)inPane
{
    [contactInfoPanes addObject:inPane];
}

//Prepare the contact info menu and toolbar items
- (void)prepareContactInfo
{
	contactInfoPanes = [[NSMutableArray alloc] init];
	
	//Install the Get Info menu item
//	menuItem_getInfo = [[NSMenuItem alloc] initWithTitle:VIEW_CONTACTS_INFO
//												  target:self
//												  action:@selector(showContactInfo:)
//										   keyEquivalent:@"i"];
//	[menuItem_getInfo setKeyEquivalentModifierMask:(NSCommandKeyMask | NSShiftKeyMask)];
//	[[owner menuController] addMenuItem:menuItem_getInfo toLocation:LOC_Contact_Manage];
	
	//Add our get info contextual menu item
	menuItem_getInfoContextualContact = [[NSMenuItem alloc] initWithTitle:VIEW_INFO
															target:self
															action:@selector(showContactInfo:) 
													 keyEquivalent:@""];
	[[owner menuController] addContextualMenuItem:menuItem_getInfoContextualContact
									   toLocation:Context_Contact_Manage];
	
	menuItem_getInfoContextualGroup = [[NSMenuItem alloc] initWithTitle:VIEW_INFO
																   target:self
																   action:@selector(showContactInfo:) 
															keyEquivalent:@""];
	[[owner menuController] addContextualMenuItem:menuItem_getInfoContextualGroup
									   toLocation:Context_Group_Manage];
	
	if([NSApp isOnPantherOrBetter]) {
		//Install the alternate Get Info menu item which will let us mangle the shortcut as desired
        menuItem_getInfoAlternate = [[NSMenuItem alloc] initWithTitle:VIEW_CONTACTS_INFO 
															   target:self 
															   action:@selector(showContactInfo:)
														keyEquivalent:@"i"];
        [menuItem_getInfoAlternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
        [menuItem_getInfoAlternate setAlternate:YES];
        [[owner menuController] addMenuItem:menuItem_getInfoAlternate toLocation:LOC_Contact_Editing];      
        
        //Register for the contact list notifications
        [[owner notificationCenter] addObserver:self selector:@selector(contactListDidBecomeMain:) 
										   name:Interface_ContactListDidBecomeMain 
										 object:nil];
        [[owner notificationCenter] addObserver:self selector:@selector(contactListDidResignMain:)
										   name:Interface_ContactListDidResignMain 
										 object:nil];
		
		//Watch changes in viewContactInfoMenuItem_alternate's menu so we can maintain its alternate status
		//(it will expand into showing both the normal and the alternate items when the menu changes)
		[[owner notificationCenter] addObserver:self selector:@selector(menuChanged:)
										   name:Menu_didChange 
										 object:[menuItem_getInfoAlternate menu]];
		
    }
		
	//Add our get info toolbar item
	NSToolbarItem   *toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"ShowInfo"
																		   label:@"Info"
																	paletteLabel:@"Show Info"
																		 toolTip:@"Show Info"
																		  target:self
																 settingSelector:@selector(setImage:)
																	 itemContent:[NSImage imageNamed:@"info" forClass:[self class]]
																		  action:@selector(showContactInfo:)
																			menu:nil];
	[[owner toolbarController] registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
}

//Always be able to show the inspector
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	if((menuItem == menuItem_getInfo) || (menuItem == menuItem_getInfoAlternate)){
		return([self selectedListObject] != nil);
	}else if ((menuItem == menuItem_getInfoContextualContact) || 
			  (menuItem == menuItem_getInfoContextualGroup)){
		return([[owner menuController] contactualMenuContact] != nil);
	}
	
	return YES;
}

//
- (NSArray *)contactInfoPanes
{
	return(contactInfoPanes);
}

- (void)contactListDidBecomeMain:(NSNotification *)notification
{
    [[owner menuController] removeItalicsKeyEquivalent];
    [menuItem_getInfoAlternate setKeyEquivalentModifierMask:(NSCommandKeyMask)];
	[menuItem_getInfoAlternate setAlternate:YES];
}

- (void)contactListDidResignMain:(NSNotification *)notification
{
    //set our alternate modifier mask back to the obscure combination
    [menuItem_getInfoAlternate setKeyEquivalent:@"i"];
    [menuItem_getInfoAlternate setKeyEquivalentModifierMask:ALTERNATE_GET_INFO_MASK];
    [menuItem_getInfoAlternate setAlternate:YES];
    //Now give the italics its combination back
    [[owner menuController] restoreItalicsKeyEquivalent];
}

- (void)menuChanged:(NSNotification *)notification
{
	[NSMenu updateAlternateMenuItem:menuItem_getInfoAlternate];
}

//Selected contact ------------------------------------------------
#pragma mark Selected contact
//Returns the "selected"(represented) contact (By finding the first responder that returns a contact)
//If no listObject is found, try to find a list object selected in a group chat
- (AIListObject *)selectedListObject
{
	AIListObject *listObject = [self _performSelectorOnFirstAvailableResponder:@selector(listObject)];
	if( !listObject) {
		listObject = [self _performSelectorOnFirstAvailableResponder:@selector(preferredListObject)];
	}
	return listObject;
}
- (AIListObject *)selectedListObjectInContactList
{
	return([self _performSelectorOnFirstAvailableResponder:@selector(listObject) conformingToProtocol:@protocol(ContactListOutlineView)]);
}
- (NSArray *)arrayOfSelectedListObjectsInContactList
{
	return([self _performSelectorOnFirstAvailableResponder:@selector(arrayOfListObjects) conformingToProtocol:@protocol(ContactListOutlineView)]);	
}

- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector
{
    NSResponder	*responder = [[[NSApplication sharedApplication] mainWindow] firstResponder];
    //Check the first responder
    if([responder respondsToSelector:selector]){
        return([responder performSelector:selector]);
    }
	
    //Search the responder chain
    do{
        responder = [responder nextResponder];
        if([responder respondsToSelector:selector]){
            return([responder performSelector:selector]);
        }
        
    } while(responder != nil);
	
    //None found, return nil
    return(nil);
}
- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector conformingToProtocol:(Protocol *)protocol
{
	NSResponder *responder = [[[NSApplication sharedApplication] mainWindow] firstResponder];
	//Check the first responder
	if([responder conformsToProtocol:protocol] && [responder respondsToSelector:selector]){
		return([responder performSelector:selector]);
	}
	
    //Search the responder chain
    do{
        responder = [responder nextResponder];
        if([responder conformsToProtocol:protocol] && [responder respondsToSelector:selector]){
            return([responder performSelector:selector]);
        }
        
    } while(responder != nil);
	
    //None found, return nil
    return(nil);
}




//Contact Sorting --------------------------------------------------------------------------------
#pragma mark Contact Sorting
//Register sorting code
- (void)registerListSortController:(AISortController *)inController
{
    [sortControllerArray addObject:inController];
}
- (NSArray *)sortControllerArray
{
    return(sortControllerArray);
}

//Set and get the active sort controller
- (void)setActiveSortController:(AISortController *)inController
{
    activeSortController = inController;
	
	[activeSortController didBecomeActive];
	
    //Resort the list
    [self sortContactList];
}
- (AISortController *)activeSortController
{
    return(activeSortController);
}

//Sort the entire contact list
- (void)sortContactList
{
    [contactList sortGroupAndSubGroups:YES sortController:activeSortController];
	[[owner notificationCenter] postNotificationName:Contact_OrderChanged object:nil];
}

//Sort an individual object
- (void)sortListObject:(AIListObject *)inObject
{
	if(updatesAreDelayed){
		delayedContactChanges++;
	}else{
		AIListObject		*group = [inObject containingObject];
		
		//Sort the groups containing this object
		[group sortListObject:inObject sortController:activeSortController];
		[[owner notificationCenter] postNotificationName:Contact_OrderChanged object:inObject];
	}
}


//List object observers ------------------------------------------------------------------------------------------------
#pragma mark List object observers
//Registers code to observe handle status changes
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver
{
	//Add the observer
    [contactObserverArray addObject:inObserver];
	
    //Let the new observer process all existing objects
	[self updateAllListObjectsForObserver:inObserver];
}

- (void)unregisterListObjectObserver:(id)inObserver
{
    [contactObserverArray removeObject:inObserver];
	[self sortContactList];
}

//Instructs a controller to update all available list objects
- (void)updateAllListObjectsForObserver:(id <AIListObjectObserver>)inObserver
{
	NSEnumerator	*enumerator;
	AIListObject	*listObject;
	
	[self delayListObjectNotifications];
		
    //Reset all contacts
	enumerator = [contactDict objectEnumerator];
	while(listObject = [enumerator nextObject]){
		NSArray	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if(attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];

		//If this contact is within a meta contact, update the meta contact too
		AIListObject	*containingObject = [listObject containingObject];
		if(containingObject && [containingObject isKindOfClass:[AIMetaContact class]]){
			NSArray	*attributes = [inObserver updateListObject:containingObject
														  keys:nil
														silent:YES];
			if(attributes) [self listObjectAttributesChanged:containingObject
												modifiedKeys:attributes];
		}
	}

    //Reset all groups
	enumerator = [groupDict objectEnumerator];
	while(listObject = [enumerator nextObject]){
		NSArray	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if(attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];
	}
	
	//
	[self endListObjectNotificationsDelay];
}

//Notify observers of a status change.  Returns the modified attribute keys
- (NSArray *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSArray *)modifiedKeys silent:(BOOL)silent
{
	NSMutableArray				*attrChange = nil;
	NSEnumerator				*enumerator;
    id <AIListObjectObserver>	observer;
	
	//Let our observers know
	enumerator = [contactObserverArray objectEnumerator];
	while((observer = [enumerator nextObject])){
		NSArray	*newKeys;
		
		if((newKeys = [observer updateListObject:inObject keys:modifiedKeys silent:silent])){
			if (!attrChange) attrChange = [NSMutableArray array];
			[attrChange addObjectsFromArray:newKeys];
		}
	}
	
	//Send out the notification for other observers
	[[owner notificationCenter] postNotificationName:ListObject_StatusChanged
											  object:inObject
											userInfo:(modifiedKeys ? [NSDictionary dictionaryWithObject:modifiedKeys 
																								 forKey:@"Keys"] : nil)];
	
	return(attrChange);
}

//Command all observers to apply their attributes to an object
- (void)_updateAllAttributesOfObject:(AIListObject *)inObject
{
	NSEnumerator				*enumerator = [contactObserverArray objectEnumerator];
    id <AIListObjectObserver>	observer;
	
	while((observer = [enumerator nextObject])){
		[observer updateListObject:inObject keys:nil silent:YES];
	}
}



//Contact List ---------------------------------------------------------------------------------------------------------
#pragma mark Contact List
//Returns the main contact list group
- (AIListGroup *)contactList
{
    return(contactList);
}

//Return a flat array of all the objects in a group on an account (and all subgroups, if desired)
- (NSMutableArray *)allContactsInGroup:(AIListGroup *)inGroup subgroups:(BOOL)subGroups onAccount:(AIAccount *)inAccount
{
	NSMutableArray	*contactArray = [NSMutableArray array];
	NSEnumerator	*enumerator;
    AIListObject	*object;
	
	if(inGroup == nil) inGroup = contactList;  //Passing nil scans the entire contact list
	
	enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isMemberOfClass:[AIMetaContact class]] || [object isMemberOfClass:[AIListGroup class]]){
            if(subGroups){
				[contactArray addObjectsFromArray:[self allContactsInGroup:(AIListGroup *)object
																 subgroups:subGroups
																 onAccount:inAccount]];
			}
		}else if([object isMemberOfClass:[AIListContact class]]){
			if(!inAccount || 
			   ([[(AIListContact *)object serviceID] isEqualToString:[inAccount serviceID]] &&
				[[(AIListContact *)object accountID] isEqualToString:[inAccount uniqueObjectID]])){
				[contactArray addObject:object];
			}
		}
	}
	
	return(contactArray);
}

- (NSArray *)allMetaContactsInGroup:(AIListGroup *)inGroup
{
	NSMutableArray	*metaContactArray = [NSMutableArray array];
	NSEnumerator	*enumerator;
    AIListObject	*object;
	
	if(inGroup == nil) inGroup = contactList;  //Passing nil scans the entire contact list
	
	enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isMemberOfClass:[AIListGroup class]]){
			[metaContactArray addObjectsFromArray:[self allMetaContactsInGroup:(AIListGroup *)object]];
			
		}else if([object isMemberOfClass:[AIMetaContact class]]){
			[metaContactArray addObject:object];
		}
	}
	
	return(metaContactArray);	
}

//Returns a menu containing all the groups within a group
//- Selector called on group selection is selectGroup:
//- The menu items represented object is the group it represents
- (NSMenu *)menuOfAllGroupsInGroup:(AIListGroup *)inGroup withTarget:(id)target
{
	NSMenu	*menu = [[NSMenu alloc] initWithTitle:@""];
	[menu setAutoenablesItems:NO];
	[self _menuOfAllGroups:menu forGroup:inGroup withTarget:target level:0];
	return([menu autorelease]);
}
- (void)_menuOfAllGroups:(NSMenu *)menu forGroup:(AIListGroup *)group withTarget:(id)target level:(int)level
{
	NSEnumerator	*enumerator;
	AIListObject	*object;
	
	//Passing nil scans the entire contact list
	if(group == nil) group = contactList;
	
	//Enumerate this group and process all groups we find within it
	enumerator = [group objectEnumerator];
	while(object = [enumerator nextObject]){
		if([object isKindOfClass:[AIListGroup class]]){
			NSMenuItem	*menuItem = [[[NSMenuItem alloc] initWithTitle:[object displayName]
																target:target
																action:@selector(selectGroup:)
														 keyEquivalent:@""] autorelease];
			[menuItem setRepresentedObject:object];
			if([menuItem respondsToSelector:@selector(setIndentationLevel:)]){
				[menuItem setIndentationLevel:level];
			}
			[menu addItem:menuItem];
			
			[self _menuOfAllGroups:menu forGroup:(AIListGroup *)object withTarget:target level:level+1];
		}
	}
}


//Returns a menu containing all the objects in a group on an account
//- Selector called on contact selection is selectContact:
//- The menu item's represented object is the contact it represents
- (NSMenu *)menuOfAllContactsInGroup:(AIListGroup *)inGroup withTarget:(id)target{
	return([self menuOfAllContactsInGroup:inGroup withTarget:target firstLevel:YES]);
}
- (NSMenu *)menuOfAllContactsInGroup:(AIListGroup *)inGroup withTarget:(id)target firstLevel:(BOOL)firstLevel
{
    NSEnumerator				*enumerator;
    AIListObject				*object;
	
	//Prepare our menu
	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];

	//Passing nil scans the entire contact list
	if(inGroup == nil) inGroup = contactList;

	//The pull down menu needs an extra item at the top of it's root menu to handle the selection.
	if(firstLevel) [menu addItemWithTitle:@"" action:nil keyEquivalent:@""];

	//All menu items for all contained objects
	enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIListGroup class]]){
			NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:[object displayName]
															target:nil 
															action:nil
													 keyEquivalent:@""] autorelease];
			[item setSubmenu:[self menuOfAllContactsInGroup:(AIListGroup *)object withTarget:target firstLevel:NO]];
			[menu addItem:item];

		}else if([object isKindOfClass:[AIListContact class]]){
			NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:[object displayName]
															target:target 
															action:@selector(selectContact:) 
													 keyEquivalent:@""] autorelease];
			[item setRepresentedObject:object];
			[menu addItem:item];

		}
	}

	return([menu autorelease]);
}

//Retrieve a contact from the contact list (Creating if necessary)
- (AIListContact *)contactWithService:(NSString *)inServiceID accountID:(NSString *)inAccountID UID:(NSString *)inUID
{
	AIListContact	*contact = nil;
	
	if([inUID length] && [inServiceID length]){ //Ignore invalid requests
		NSString		*key = [NSString stringWithFormat:@"%@.%@.%@", inServiceID, inAccountID, inUID];
		
		contact = [contactDict objectForKey:key];
		if(!contact){
			//Create
			contact = [[[AIListContact alloc] initWithUID:inUID accountID:inAccountID serviceID:inServiceID] autorelease];
			
			//Place new contacts at the bottom of our list (by giving them the largest ordering index)
			largestOrder += 1.0;
			[contact setOrderIndex:largestOrder];
			
			//Add
			[self _updateAllAttributesOfObject:contact];
			[contactDict setObject:contact forKey:key];
		}
	}
	
	return(contact);
}

- (AIListContact *)existingContactWithService:(NSString *)inServiceID accountID:(NSString *)inAccountUID UID:(NSString *)inUID
{	
	if([inServiceID length] && [inUID length]){
		return([contactDict objectForKey:[NSString stringWithFormat:@"%@.%@.%@", inServiceID, inAccountUID, inUID]]);
	}else{
		return(nil);
	}
}

- (NSArray *)allContactsWithService:(NSString *)inServiceID UID:(NSString *)inUID
{	
	NSString		*uniqueObjectID = [AIListObject uniqueObjectIDForUID:inUID serviceID:inServiceID];
	NSMutableArray  *returnContactArray = nil;
	
	NSEnumerator	*enumerator;
	AIListObject	*listObject;

	//Contact
	enumerator = [contactDict objectEnumerator];
	while(listObject = [enumerator nextObject]){
		if([[listObject uniqueObjectID] isEqualToString:uniqueObjectID]){
			
			if (!returnContactArray) returnContactArray = [NSMutableArray array];
			[returnContactArray addObject:listObject];
		}
	}
	
	return (returnContactArray);
}

- (AIListObject *)existingListObjectWithUniqueID:(NSString *)uniqueID
{
	NSEnumerator	*enumerator;
	AIListObject	*listObject;
	
	//Contact
	enumerator = [contactDict objectEnumerator];
	while(listObject = [enumerator nextObject]){
		if([[listObject uniqueObjectID] isEqualToString:uniqueID]) return(listObject);
	}
		
	//Group
	enumerator = [groupDict objectEnumerator];
	while(listObject = [enumerator nextObject]){
		if([[listObject uniqueObjectID] isEqualToString:uniqueID]) return(listObject);
	}
	
	return(nil);
}

- (AIListContact *)preferredContactForContentType:(NSString *)inType forListContact:(AIListContact *)inContact
{
	AIListContact   *returnContact = nil;
	AIAccount		*account;
	
	if ([inContact isKindOfClass:[AIMetaContact class]]){		
		returnContact = [(AIMetaContact *)inContact preferredContact];
		
		//Recurse into metacontacts if necessary
		if ([returnContact isKindOfClass:[AIMetaContact class]]){
			returnContact = [self preferredContactForContentType:inType
												  forListContact:returnContact];
		}
		
	} else{
		
		//We have a flat contact; find the best account for talking to this contact,
		//and return an AIListContact on that account
		account = [[owner accountController] preferredAccountForSendingContentType:inType
																	  toListObject:inContact];
		if (account) {
			returnContact = [self contactWithService:[inContact serviceID]
										   accountID:[account uniqueObjectID] 
												 UID:[inContact UID]];
		}
 	}
	
	return(returnContact);
}

//Retrieve a list contact matching the UID and serviceID of the passed contact but on the specified account.
//In many cases this will be the same as inContact.
- (AIListContact *)contactOnAccount:(AIAccount *)account fromListContact:(AIListContact *)inContact
{
	AIListContact   *returnContact = nil;
	
	if (account){
		returnContact = [self contactWithService:[inContact serviceID]
									   accountID:[account uniqueObjectID] 
											 UID:[inContact UID]];
	}else{
		returnContact = inContact;
	}
	
	return returnContact;
}

#warning This is ridiculous.
- (AIListContact *)preferredContactWithUID:(NSString *)inUID andServiceID:(NSString *)inServiceID forSendingContentType:(NSString *)inType
{
	AIListObject	*tempListObject = [[AIListObject alloc] initWithUID:inUID serviceID:inServiceID];
	AIAccount		*account = [[owner accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE 
																				   toListObject:tempListObject];
	[tempListObject release];
	
	return ([self contactWithService:inServiceID
						   accountID:[account uniqueObjectID]
								 UID:inUID]);
}

//Retrieve a group from the contact list (Creating if necessary)
- (AIListGroup *)groupWithUID:(NSString *)groupUID
{
	AIListGroup		*group;
	
	if(!groupUID || ![groupUID length] || [groupUID isEqualToString:ADIUM_ROOT_GROUP_NAME]){
		//Return our root group if it is requested
		group = contactList;
	}else{
		if(!(group = [groupDict objectForKey:groupUID])){
			//NSArray		*groupNest = [groupUID componentsSeparatedByString:@":"];
			//NSString	*groupName = [groupNest lastObject];
			//AIListGroup *targetGroup;	
			
			//Create
			group = [[[AIListGroup alloc] initWithUID:groupUID] autorelease];
			//[group setStatusObject:groupName forKey:@"FormattedUID" notify:YES];
			
			//Place new groups at the bottom of our list (by giving them the largest ordering index)
			largestOrder += 1.0;
			[group setOrderIndex:largestOrder];
			
			//add
			[self _updateAllAttributesOfObject:group];
			[groupDict setObject:group forKey:groupUID];
			
			//Add to target group
			//if([groupNest count] == 1){
			//	targetGroup = contactList;
			//}else{
			//	targetGroup = [self groupWithUID:[groupUID substringToIndex:[groupUID length] - ([groupName length] + 1)]];
			//}
			[/*targetGroup*/contactList addObject:group];
			[self _listChangedGroup:/*targetGroup*/contactList object:group];
		}
	}
	
	return(group);
}


//Contact list editing -------------------------------------------------------------------------------------------------
#pragma mark Contact list editing
- (void)removeListObjects:(NSArray *)objectArray
{
	NSEnumerator	*enumerator = [objectArray objectEnumerator];
	AIListObject	*listObject;
	
	while(listObject = [enumerator nextObject]){
		if([listObject isKindOfClass:[AIMetaContact class]]){
			[self breakdownAndRemoveMetaContact:(AIMetaContact *)listObject];

		}else if([listObject isKindOfClass:[AIListGroup class]]){
			AIListObject	*containingObject = [listObject containingObject];
			
			//If this is a group, delete all the objects within it
			[self removeListObjects:[(AIListGroup *)listObject containedObjects]];
			
			//Then, procede to delete the group
			[listObject retain];
			[containingObject removeObject:listObject];
			[groupDict removeObjectForKey:[listObject UID]];
			[self _listChangedGroup:containingObject object:listObject];
			[listObject release];
			
		}else{
			AIAccount	*account = [[owner accountController] accountWithObjectID:[(AIListContact *)listObject accountID]];
			
			if([account conformsToProtocol:@protocol(AIAccount_List)]){
				[(AIAccount<AIAccount_List> *)account removeContacts:[NSArray arrayWithObject:listObject]];
			}
		}
	}
}

- (void)addContacts:(NSArray *)contactArray toGroup:(AIListGroup *)group
{
	NSEnumerator	*enumerator;
	AIListContact	*listObject;
	
	enumerator = [contactArray objectEnumerator];
	while(listObject = [enumerator nextObject]){
		AIAccount	*account = [[owner accountController] accountWithObjectID:[listObject accountID]];
		
		if([account conformsToProtocol:@protocol(AIAccount_List)]){
			[(AIAccount<AIAccount_List> *)account addContacts:[NSArray arrayWithObject:listObject] toGroup:group];
		}
	}
}

- (void)requestAddContactWithUID:(NSString *)contactUID serviceID:(NSString *)inServiceID
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		contactUID,UID,
		inServiceID,@"serviceID",nil];
	
	[[owner notificationCenter] postNotificationName:Contact_AddNewContact
											  object:nil
											userInfo:userInfo];
}

- (void)moveListObjects:(NSArray *)objectArray toGroup:(AIListGroup *)group index:(int)index
{
	NSEnumerator	*enumerator;
	AIListContact	*listObject;

	enumerator = [objectArray objectEnumerator];
	while(listObject = [enumerator nextObject]){
		//Set the new index / position of the object
		[self _positionObject:listObject atIndex:index inGroup:group];

		//Move the object to the new group if necessary
		if(group != [listObject containingObject]){			

			if([listObject isKindOfClass:[AIMetaContact class]]){
				//This is a meta contact, move the objects within it
				NSEnumerator	*metaEnumerator = [[(AIMetaContact *)listObject containedObjects] objectEnumerator];
				AIListObject	*metaObject;
				
				while(metaObject = [metaEnumerator nextObject]){
					[self _moveObject:metaObject toGroup:group];
				}
			}else if([listObject isKindOfClass:[AIListContact class]]){
				//Move the object 
				[self _moveObject:listObject toGroup:group];
			}else if([listObject isKindOfClass:[AIListGroup class]]){
//				NSString	*newNestName = [[[listObject UID] componentsSeparatedByString:@":"] lastObject];
//				while(group && group != contactList){
//					NSArray		*groupNest = [[group UID] componentsSeparatedByString:@":"];
//					newNestName = [[groupNest lastObject] stringByAppendingFormat:@":%@",newNestName];
//				
//					group = [group containingObject];
//				}
//				
//				//Rename the group to re-nest it
//				[self _renameGroup:(AIListGroup *)listObject to:newNestName];
			}

		}
			
		//Resort to update for the new positioning
		[[owner contactController] sortListObject:listObject];
	}
}

//Move an object to another group
- (void)_moveObject:(AIListObject *)listObject toGroup:(AIListGroup *)group
{
	AIAccount	*account = [[owner accountController] accountWithObjectID:[(AIListContact *)listObject accountID]];
	if([account conformsToProtocol:@protocol(AIAccount_List)]){
		[(AIAccount<AIAccount_List> *)account moveListObjects:[NSArray arrayWithObject:listObject] toGroup:group];
	}
}

//Rename a group
- (void)_renameGroup:(AIListGroup *)listGroup to:(NSString *)newName
{
	NSEnumerator	*enumerator = [[[owner accountController] accountArray] objectEnumerator];
	AIAccount		*account;
	
	//Since Adium has no memory of what accounts a group is on, we have to send this message to all available accounts
	//The accounts without this group will just ignore it
	while(account = [enumerator nextObject]){
		if([account conformsToProtocol:@protocol(AIAccount_List)]){
			[(AIAccount<AIAccount_List> *)account renameGroup:listGroup to:newName];
		}
	}
	
	//Remove the old group if it's empty
	if([listGroup containedObjectsCount] == 0){
		[self removeListObjects:[NSArray arrayWithObject:listGroup]];
	}
}

//Position a list object within a group
- (void)_positionObject:(AIListObject *)listObject atIndex:(int)index inGroup:(AIListGroup *)group
{
	if(index == 0){		
		//Moved to the top of a group.  New index is between 0 and the lowest current index
		smallestOrder /= 2.0;
		[listObject setOrderIndex:smallestOrder];
		
	}else if(index >= [group visibleCount]){
		//Moved to the bottom of a group.  New index is one higher than the highest current index
		largestOrder += 1.0;
		[listObject setOrderIndex:largestOrder];
		
	}else{
		//Moved somewhere in the middle.  New index is the average of the next largest and smallest index
		float nextLowest = [[group objectAtIndex:index-1] orderIndex];
		float nextHighest = [[group objectAtIndex:index] orderIndex];
		
		//To avoid stepping on any existing placements within that range, we will move the nextLowest value
		//to the closest existing order below nextHighest.
		AIListObject	*scanObject;
		NSEnumerator	*enumerator = enumerator = [contactDict objectEnumerator];
		while(scanObject = [enumerator nextObject]){
			float	scanIndex = [scanObject orderIndex];
			if(scanIndex > nextLowest && scanIndex < nextHighest) nextLowest = scanIndex;
		}
		
		//
		[listObject setOrderIndex:((nextHighest + nextLowest) / 2.0)];
	}
}

@end


