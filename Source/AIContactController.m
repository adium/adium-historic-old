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

// $Id$

#import "AIContactController.h"
#import "AIAccountController.h"
#import "AIContactInfoWindowController.h"

#define PREF_GROUP_CONTACT_LIST		@"Contact List"			//Contact list preference group
#define KEY_FLAT_GROUPS				@"FlatGroups"			//Group storage
#define KEY_FLAT_CONTACTS			@"FlatContacts"			//Contact storage
#define KEY_FLAT_METACONTACTS		@"FlatMetaContacts"		//Metacontact objectID storage

#define	OBJECT_STATUS_CACHE			@"Object Status Cache"

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

- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inGroup withTarget:(id)target firstLevel:(BOOL)firstLevel;
- (void)_menuOfAllGroups:(NSMenu *)menu forGroup:(AIListGroup *)group withTarget:(id)target level:(int)level;

- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector;
- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector conformingToProtocol:(Protocol *)protocol;

- (NSArray *)_arrayRepresentationOfListObjects:(NSArray *)listObjects;
- (NSDictionary *)_compressedOrderingOfObject:(AIListObject *)inObject;
- (void)_applyCompressedOrdering:(NSDictionary *)orderDict toObject:(AIListObject *)inObject;
- (void)_loadContactsFromArray:(NSArray *)array;
- (void)_loadGroupsFromArray:(NSArray *)array;

- (void)_listChangedGroup:(AIListObject *)group object:(AIListObject *)object;

- (void)_positionObject:(AIListObject *)listObject atIndex:(int)index inGroup:(AIListObject<AIContainingObject> *)group;
- (void)_moveObjectServerside:(AIListObject *)listObject toGroup:(AIListGroup *)group;
- (void)_renameGroup:(AIListGroup *)listGroup to:(NSString *)newName;

//MetaContacts
- (AIMetaContact *)metaContactWithObjectID:(NSNumber *)inObjectID;
- (void)_restoreContactsToMetaContact:(AIMetaContact *)metaContact;
- (AIMetaContact *)groupListContacts:(NSArray *)contactsToGroupArray;
- (void)addListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact;
- (BOOL)_performAddListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact;
- (void)removeListObject:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact;
- (void)_loadMetaContactsFromArray:(NSArray *)array;
- (void)_saveMetaContacts:(NSDictionary *)allMetaContactsDict;
- (void)breakdownAndRemoveMetaContact:(AIMetaContact *)metaContact;

- (NSArray *)allContactsWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID;

- (void)_addMenuItemsFromArray:(NSArray *)contactArray toMenu:(NSMenu *)contactMenu target:(id)target offlineContacts:(BOOL)offlineContacts;

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
	nextOrderIndex = 1;
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

	//
	[self prepareContactInfo];

	[[owner notificationCenter] addObserver:self 
								   selector:@selector(adiumVersionWillBeUpgraded:) 
									   name:Adium_VersionWillBeUpgraded
									 object:nil];

	//Observe content (for preferredContactForContentType:forListContact:)
    [[owner notificationCenter] addObserver:self
                                   selector:@selector(didSendContent:)
                                       name:Content_DidSendContent
                                     object:nil];	
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

    [super dealloc];
}

- (void)adiumVersionWillBeUpgraded:(NSNotification *)notification
{
	//After 0.63 - metaContacts dictionary changed; old dictionary is very large and quite useless.
	if ([[[notification userInfo] objectForKey:@"lastLaunchedVersion"] floatValue] < 0.682){
		[self clearAllMetaContactData];
	}
	
	[[owner notificationCenter] removeObserver:self
										  name:Adium_VersionWillBeUpgraded
										object:nil];
}

- (void)clearAllMetaContactData
{
	NSString		*path;
	NSDictionary	*metaContactDictCopy = [[metaContactDict copy] autorelease];
	NSEnumerator	*enumerator;
	AIMetaContact	*metaContact;
	
	//Remove all the metaContacts to get any existing objects out of them
	enumerator = [metaContactDictCopy objectEnumerator];
	while (metaContact = [enumerator nextObject]){
		[self breakdownAndRemoveMetaContact:metaContact];
	}

	[metaContactDict release]; metaContactDict = [[NSMutableDictionary alloc] init];
	[contactToMetaContactLookupDict release]; contactToMetaContactLookupDict = [[NSMutableDictionary alloc] init];
	
	//Clear the preferences for good measure
	[[owner preferenceController] setPreference:nil
										 forKey:KEY_FLAT_METACONTACTS
										  group:PREF_GROUP_CONTACT_LIST];
	[[owner preferenceController] setPreference:nil
										 forKey:KEY_METACONTACT_OWNERSHIP
										  group:PREF_GROUP_CONTACT_LIST];
	
	//Clear out old metacontact files
	path = [[[owner loginController] userDirectory] stringByAppendingPathComponent:OBJECT_PREFS_PATH];
	[[NSFileManager defaultManager] removeFilesInDirectory:path
												withPrefix:@"MetaContact"
											 movingToTrash:NO];
	[[NSFileManager defaultManager] removeFilesInDirectory:@"~/Library/Caches/Adium"
												withPrefix:@"MetaContact"
											 movingToTrash:NO];
}

//Local Contact List Storage -------------------------------------------------------------------------------------------
#pragma mark Local Contact List Storage
//Load the contact list
- (void)loadContactList
{	
	//We must load all the groups before loading contacts for the ordering system to work correctly.
	[self _loadGroupsFromArray:[[owner preferenceController] preferenceForKey:KEY_FLAT_GROUPS
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
}

//List objects from flattened array
- (void)_loadGroupsFromArray:(NSArray *)array
{
	NSEnumerator	*enumerator = [array objectEnumerator];
	NSDictionary	*infoDict;
	
	NSString	*Expanded = @"Expanded";
	
	while(infoDict = [enumerator nextObject]){
		AIListObject	*object = nil;
		
		object = [self groupWithUID:[infoDict objectForKey:UID]];
		[(AIListGroup *)object setExpanded:[[infoDict objectForKey:Expanded] boolValue]];
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
	NSString	*Group = @"Group";
	NSString	*Type = @"Type";
	NSString	*Expanded = @"Expanded";
	
	while(object = [enumerator nextObject]){
			[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				Group, Type,
				[object UID], UID,
				[NSNumber numberWithBool:[(AIListGroup *)object isExpanded]], Expanded,
				nil]];
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
		[[inContact account] updateContactStatus:inContact];
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
		
		//Make sure we traverse metaContacts as close to the root as possible; an automatic metaContact may be within
		//a manually created one, for example, in the most common situation.
		containingObject = [self parentContactForListObject:containingObject];
		
		//If the object's 'group' is a metaContact, and that metaContact isn't in our list yet
		//use the object's remote grouping as our grouping.
		if (![containingObject containingObject] && [remoteGroup length]){
			//If no similar objects exist, we add this contact directly to the list
			AIListGroup *targetGroup = [self groupWithUID:remoteGroup];

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
			AIService	*inObjectService = [inObject service];
			NSString	*inObjectUID = [inObject UID];
			BOOL		performedGrouping = NO;
			
			localGroup = [self groupWithUID:remoteGroup];
			existingObject = [localGroup objectWithService:inObjectService UID:inObjectUID];
			NSLog(@"%@ ; %@",localGroup,existingObject);
			if(existingObject){
				//If an object exists in this group with the same UID and serviceID, create a MetaContact
				//for the two.
				[self groupListContacts:[NSArray arrayWithObjects:inObject,existingObject,nil]];
				performedGrouping = YES;
				
			}else{
				AIMetaContact	*metaContact;
				
				//If no object exists in this group which matches, we should check if there is already
				//a MetaContact holding a matching ListContact, since we should include this contact in it
				//If we found a metaContact to which we should add, do it.
				if (metaContact = [contactToMetaContactLookupDict objectForKey:[inObject internalObjectID]]){
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

	[inObject setStatusObject:(remoteGroup ? nil : [NSNumber numberWithBool:YES]) 
					   forKey:@"Stranger"
					   notify:NotifyLater];
	[inObject notifyOfChangedStatusSilently:YES];
}

- (AIListGroup *)remoteGroupForContact:(AIListContact *)inContact
{
	AIListGroup		*group;
	
	if ([inContact isKindOfClass:[AIMetaContact class]]){
		//For a metaContact, the closest we have to a remote group is the group it is within locally
		group = [inContact parentGroup];
		
	}else{
		NSString	*remoteGroup = [inContact remoteGroupName];
		group = (remoteGroup ? [self groupWithUID:remoteGroup] : nil);
	}
	
	return(group);
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
	//If there are no delayed update requests, remove the hold
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
	NSString		*metaContactDictKey;
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
	metaContactDictKey = [AIMetaContact internalObjectIDFromObjectID:inObjectID];
	
	metaContact = [metaContactDict objectForKey:metaContactDictKey];
	if (!metaContact){
		metaContact = [[AIMetaContact alloc] initWithObjectID:inObjectID];
		
		//Keep track of it in our metaContactDict for retrieval by objectID
		[metaContactDict setObject:metaContact forKey:metaContactDictKey];
		
		//Add it to our more general contactDict, as well
		[contactDict setObject:metaContact forKey:[metaContact internalUniqueObjectID]];
		
		if (shouldRestoreContacts){
			[self _restoreContactsToMetaContact:metaContact];
		}
		
		[metaContact release];
	}
	
	return (metaContact);
}

- (void)_restoreContactsToMetaContact:(AIMetaContact *)metaContact
{
	NSDictionary	*allMetaContactsDict = [[owner preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																					group:PREF_GROUP_CONTACT_LIST];
	NSArray			*containedContactsArray = [allMetaContactsDict objectForKey:[metaContact internalObjectID]];
	NSDictionary	*containedContact;
	AIListContact	*listContact = nil;
	NSEnumerator	*enumerator = [containedContactsArray objectEnumerator];
	
	
	[metaContact setDelayContainedObjectSorting:YES];
	
	while (containedContact = [enumerator nextObject]){
		if ([[containedContact objectForKey:KEY_IS_METACONTACT] boolValue]){
			//This contained contact is a meta contact, so it'll just have an objectID
			listContact = [self metaContactWithObjectID:[containedContact objectForKey:KEY_OBJECTID]];
			[self _performAddListObject:listContact toMetaContact:metaContact];

	 	}else{
			//This contained contact is a regular AIListContact uniqueObjectID.  Get all matching contacts on all accounts.
			
			NSEnumerator	*contactEnumerator;
			contactEnumerator = [[self allContactsWithServiceID:[containedContact objectForKey:ServiceID]
															UID:[containedContact objectForKey:UID]] objectEnumerator];
			while (listContact = [contactEnumerator nextObject]){
				[self _performAddListObject:listContact toMetaContact:metaContact];
			}
		}
	}
	
	[metaContact setDelayContainedObjectSorting:NO];
}


//Add a list object to a meta contact, setting preferences and such 
//so the association is lasting across program launches.
- (void)addListObject:(AIListObject *)listObject toMetaContact:(AIMetaContact *)metaContact
{
	if (listObject != metaContact){
		AIMetaContact		*oldMetaContact;
		
		//Obtain any metaContact this listObject is current within, so we can remove it later
		oldMetaContact = [contactToMetaContactLookupDict objectForKey:[listObject internalObjectID]];
		
		if ([self _performAddListObject:listObject toMetaContact:metaContact]){
			
			//If this listObject was not in this metaContact in any form before, store the change
			if (metaContact != oldMetaContact){
				NSDictionary		*containedContactDict;
				NSMutableDictionary	*allMetaContactsDict;
				NSMutableArray		*containedContactsArray;
				
				NSString			*metaContactInternalObjectID = [metaContact internalObjectID];
				
				//Get the dictionary of all metaContacts
				allMetaContactsDict = [[[owner preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																				 group:PREF_GROUP_CONTACT_LIST] mutableCopy];
				if (!allMetaContactsDict){
					allMetaContactsDict = [[NSMutableDictionary alloc] init];
				}
				
				//Remove the list object from any other metaContact it is in at present
				if (oldMetaContact){
					[self removeListObject:listObject fromMetaContact:oldMetaContact];
				}
				
				//Load the array for the new metaContact
				containedContactsArray = [[allMetaContactsDict objectForKey:metaContactInternalObjectID] mutableCopy];
				if (!containedContactsArray) containedContactsArray = [[NSMutableArray alloc] init];
				containedContactDict = nil;
				
				//Create the dictionary describing this list object
				if ([listObject isKindOfClass:[AIMetaContact class]]){
					containedContactDict = [NSDictionary dictionaryWithObjectsAndKeys:
						[NSNumber numberWithBool:YES],KEY_IS_METACONTACT,
						[(AIMetaContact *)listObject objectID],KEY_OBJECTID,nil];
					
				}else if ([listObject isKindOfClass:[AIListContact class]]){
					containedContactDict = [NSDictionary dictionaryWithObjectsAndKeys:
						[[listObject service] serviceID],ServiceID,
						[listObject UID],UID,nil];
				}
				
				//Only add if this dict isn't already in the array
				if (containedContactDict && ([containedContactsArray indexOfObject:containedContactDict] == NSNotFound)){
					[containedContactsArray addObject:containedContactDict];
					[allMetaContactsDict setObject:containedContactsArray forKey:metaContactInternalObjectID];
					
					//Save
					[self _saveMetaContacts:allMetaContactsDict];
					
					[[owner contactAlertsController] mergeAndMoveContactAlertsFromListObject:listObject 
																			  intoListObject:metaContact];				
				}
				
				[allMetaContactsDict release];
				[containedContactsArray release];
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
	
	AIListObject<AIContainingObject> *localGroup = [listObject containingObject];

	//Remove the object from its previous containing group
	if (localGroup && (localGroup != metaContact)){
		[localGroup removeObject:listObject];
		[self _listChangedGroup:localGroup object:listObject];
	}
	
	//AIMetaContact will handle reassigning the list object's grouping to being itself
	if (success = [metaContact addObject:listObject]){
		[contactToMetaContactLookupDict setObject:metaContact forKey:[listObject internalObjectID]];

		[self _listChangedGroup:metaContact object:listObject];
		
		//Update the meta contact's attributes
		[self _updateAllAttributesOfObject:metaContact];
		
		//If the metaContact isn't in a group yet, use the group of the object we just added
		if ((![metaContact containingObject]) && localGroup){ 
			//Add the new meta contact to our list
			[(AIMetaContact *)localGroup addObject:metaContact];
			[self _listChangedGroup:localGroup object:metaContact];
		}
	}
	
	return success;
}

- (void)removeAllListObjectsMatching:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact
{
	NSEnumerator	*enumerator;
	AIListObject	*theObject;
	
	enumerator = [[self allContactsWithService:[listObject service]
										  UID:[listObject UID]] objectEnumerator];

	while (theObject = [enumerator nextObject]){
		[self removeListObject:theObject fromMetaContact:metaContact];
	}
	
	[contactToMetaContactLookupDict removeObjectForKey:[listObject internalObjectID]];
}

- (void)removeListObject:(AIListObject *)listObject fromMetaContact:(AIMetaContact *)metaContact
{
	NSEnumerator		*enumerator;
	NSArray				*containedContactsArray;
	NSDictionary		*containedContactDict = nil;
	NSMutableDictionary	*allMetaContactsDict;
	NSString			*metaContactInternalObjectID = [metaContact internalObjectID];

	//Get the dictionary of all metaContacts
	allMetaContactsDict = [[owner preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																	 group:PREF_GROUP_CONTACT_LIST];
	
	
	//Load the array for the metaContact
	containedContactsArray = [allMetaContactsDict objectForKey:metaContactInternalObjectID];
	
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
		NSString	*listObjectServiceID = [[listObject service] serviceID];
		
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
		
		newContainedContactsArray = [containedContactsArray mutableCopy];
		[newContainedContactsArray removeObjectIdenticalTo:containedContactDict];
		
		[allMetaContactsDict setObject:newContainedContactsArray
								forKey:metaContactInternalObjectID];
		
		[self _saveMetaContacts:allMetaContactsDict];
		
		[newContainedContactsArray release];
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
		[contactsToGroupArray addObjectsFromArray:[self allContactsWithServiceID:[servicesArray objectAtIndex:i]
																			 UID:[UIDsArray objectAtIndex:i]]];
	}

	return([self groupListContacts:contactsToGroupArray]);
}

//Group an NSArray of AIListContacts, returning the meta contact into which they are added.
//This will reuse an existing metacontact (for one of the contacts in the array) if possible.
- (AIMetaContact *)groupListContacts:(NSArray *)contactsToGroupArray
{
	NSEnumerator	*enumerator;
	AIListContact   *listContact;
	AIMetaContact   *metaContact = nil;
	
	//Look for an existing MetaContact we can use.  The first one we find is the lucky winner.
	enumerator = [contactsToGroupArray objectEnumerator];
	while ((listContact = [enumerator nextObject]) && (metaContact == nil)){
		if ([listContact isKindOfClass:[AIMetaContact class]]){
			metaContact = (AIMetaContact *)listContact;
		}else{
			metaContact = [contactToMetaContactLookupDict objectForKey:[listContact internalObjectID]];
		}
	}
	
	//Create a new MetaContact is we didn't find one.
	if (!metaContact) {
		metaContact = [self metaContactWithObjectID:nil];
	}
	
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
	NSArray				*containedObjects = [[metaContact containedObjects] copy];
	NSEnumerator		*metaEnumerator = [containedObjects objectEnumerator];
	AIListObject		*containingObject = [metaContact containingObject];
	AIListObject		*object;
	
	NSMutableDictionary *allMetaContactsDict = [[[owner preferenceController] preferenceForKey:KEY_METACONTACT_OWNERSHIP
																						 group:PREF_GROUP_CONTACT_LIST] mutableCopy];
	
	while (object = [metaEnumerator nextObject]){
		[self removeListObject:object fromMetaContact:metaContact];
	}
	
	//Then, procede to remove the metaContact
	
	//Protect!
	[metaContact retain];
	
	//Remove it from its containing group
	[(AIMetaContact *)containingObject removeObject:metaContact];
	
	NSString	*metaContactInternalObjectID = [metaContact internalObjectID];
	
	//Remove our reference to it internally
	[metaContactDict removeObjectForKey:metaContactInternalObjectID];
	
	//Remove it from the preferences dictionary
	[allMetaContactsDict removeObjectForKey:metaContactInternalObjectID];
	
	//XXX - contactToMetaContactLookupDict
	
	//Post the list changed notification for the old containingObject
	[self _listChangedGroup:containingObject object:metaContact];
	
	//Protection is overrated.
	[metaContact release];
	[containedObjects release];
	[allMetaContactsDict release];
	
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

int contactDisplayNameSort(AIListObject *objectA, AIListObject *objectB, void *context)
{
	return [[objectA displayName] caseInsensitiveCompare:[objectB displayName]];
}

- (NSMenu *)menuOfContainedContacts:(AIListObject *)inContact forService:(AIService *)service withTarget:(id)target includeOffline:(BOOL)includeOffline
{
	NSMenu		*contactMenu = [[NSMenu alloc] initWithTitle:@""];
	NSArray		*contactArray;
		
	if([inContact isKindOfClass:[AIMetaContact class]]){
		if (service){
			contactArray = [[(AIMetaContact *)inContact dictionaryOfServiceClassesAndListContacts] objectForKey:[service serviceClass]];
		}else{
			//If service is nil, get ALL contained contacts
			contactArray = [(AIMetaContact *)inContact listContacts];
		}
	}else{
		contactArray = [NSArray arrayWithObject:inContact];
	}

	//Sort the array by display name
	contactArray = [contactArray sortedArrayUsingFunction:contactDisplayNameSort context:nil];

	[self _addMenuItemsFromArray:contactArray
						  toMenu:contactMenu
						  target:target
				  offlineContacts:NO];
	
	if (includeOffline){
		//Separate the online from the offline
		if ([contactMenu numberOfItems] > 0){
			[contactMenu addItem:[NSMenuItem separatorItem]];
		}
		
		[self _addMenuItemsFromArray:contactArray
							  toMenu:contactMenu
							  target:target
					 offlineContacts:YES];			
	}
	
	return ([contactMenu autorelease]);
}

//Add the contacts from contactArray to the specified menu.  If offlineContacts is NO, only add online ones.
//If offlineContacts is YES, only add offline ones.
- (void)_addMenuItemsFromArray:(NSArray *)contactArray toMenu:(NSMenu *)contactMenu target:(id)target offlineContacts:(BOOL)offlineContacts
{
	NSEnumerator	*enumerator;
	AIListContact	*contact;
	
	enumerator = [contactArray objectEnumerator];
	
	while(contact = [enumerator nextObject]){
		BOOL contactIsOnline = [contact online];
		
		if ((contactIsOnline && !offlineContacts) ||
			(!contactIsOnline && offlineContacts)){
			NSImage			*menuServiceImage;
			NSMenuItem		*menuItem;

			menuServiceImage = [AIUserIcons menuUserIconForObject:contact];
			
			menuItem = [[NSMenuItem alloc] initWithTitle:[contact formattedUID]
												  target:target
												  action:@selector(selectContainedContact:)
										   keyEquivalent:@""];
			[menuItem setRepresentedObject:contact];
			[menuItem setImage:menuServiceImage];
			[contactMenu addItem:menuItem];
			
			[menuItem release];
		}
	}
}

- (NSMenu *)menuOfContainedContacts:(AIListObject *)inContact withTarget:(id)target
{
	return( [self menuOfContainedContacts:inContact forService:nil withTarget:target includeOffline:YES] );
}

//Return either the highest metaContact containing this list object, or the list object itself.  Appropriate for when
//preferences should be read from/to the most generalized contact possible.
- (AIListObject *)parentContactForListObject:(AIListObject *)listObject
{
	if ([listObject isKindOfClass:[AIListContact class]]){
		//Find the highest-up metaContact
		AIListObject	*containingObject;
		while ([(containingObject = [listObject containingObject]) isKindOfClass:[AIMetaContact class]]){
			listObject = (AIMetaContact *)containingObject;
		}
	}
	
	return(listObject);
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
		[NSApp activateIgnoringOtherApps:YES];
		[[[AIContactInfoWindowController showInfoWindowForListObject:listObject] window] makeKeyAndOrderFront:nil];
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
		
		if([group isKindOfClass:[AIListGroup class]]){
			//Sort the groups containing this object
			[(AIListGroup *)group sortListObject:inObject sortController:activeSortController];
			[[owner notificationCenter] postNotificationName:Contact_OrderChanged object:inObject];
		}
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



//Contact List Access --------------------------------------------------------------------------------------------------
#pragma mark Contact List Access
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
			   ([(AIListContact *)object service] == [inAccount service] &&
				[(AIListContact *)object account] == inAccount)){
				[contactArray addObject:object];
			}
		}
	}
	
	return(contactArray);
}

//Contact List Menus- --------------------------------------------------------------------------------------------------
#pragma mark Contact List Menus

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
- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inObject withTarget:(id)target{
	return([self menuOfAllContactsInContainingObject:inObject withTarget:target firstLevel:YES]);
}
- (NSMenu *)menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)inObject withTarget:(id)target firstLevel:(BOOL)firstLevel
{
    NSEnumerator				*enumerator;
    AIListObject				*object;
	
	//Prepare our menu
	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];

	//Passing nil scans the entire contact list
	if(inObject == nil) inObject = contactList;

	//The pull down menu needs an extra item at the top of its root menu to handle the selection.
	if(firstLevel) [menu addItemWithTitle:@"" action:nil keyEquivalent:@""];

	//All menu items for all contained objects
	enumerator = [inObject listContactsEnumerator];
    while((object = [enumerator nextObject])){
		NSImage		*menuServiceImage;
		NSMenuItem	*menuItem;
		BOOL		needToCreateSubmenu;
		BOOL		isGroup = [object isKindOfClass:[AIListGroup class]];
		BOOL		isValidGroup = (isGroup &&
									[[(AIListGroup *)object containedObjects] count]);
		
		//We don't want to include empty groups
		if (!isGroup || isValidGroup){
			
			needToCreateSubmenu = (isValidGroup ||
								   ([object isKindOfClass:[AIMetaContact class]] && ([[(AIMetaContact *)object listContacts] count] > 1)));
			
			
			menuServiceImage = [AIUserIcons menuUserIconForObject:object];
			
			menuItem = [[[NSMenuItem alloc] initWithTitle:(needToCreateSubmenu ? 
														   [object displayName] :
														   [object formattedUID])
												   target:target 
												   action:@selector(selectContact:)
											keyEquivalent:@""] autorelease];
			
			if(needToCreateSubmenu){
				[menuItem setSubmenu:[self menuOfAllContactsInContainingObject:(AIListObject<AIContainingObject> *)object withTarget:target firstLevel:NO]];
			}
			
			[menuItem setRepresentedObject:object];
			[menuItem setImage:menuServiceImage];
			[menu addItem:menuItem];
		}
	}

	return([menu autorelease]);
}

//Retrieving Specific Contacts -----------------------------------------------------------------------------------------
#pragma mark Retrieving Specific Contacts

//Retrieve a contact from the contact list (Creating if necessary)
- (AIListContact *)contactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID
{
	AIListContact	*contact = nil;

	if(inUID && [inUID length] && inService){ //Ignore invalid requests
		NSString		*key = [AIListContact internalUniqueObjectIDForService:inService
																	   account:inAccount
																		   UID:inUID];
		
		contact = [contactDict objectForKey:key];
		if(!contact){
			//Create
			contact = [[AIListContact alloc] initWithUID:inUID account:inAccount service:inService];

			//Place new contacts at the bottom of our list (by giving them the largest ordering index)
//			largestOrder += 1.0;
//			[contact setOrderIndex:largestOrder];
			//Make sure this contact's order index isn't bigger than our current nextOrderIndex we'll vend to new contacts
			float orderIndex = [contact orderIndex];
			if (orderIndex > nextOrderIndex) nextOrderIndex = orderIndex + 1;

			//Do the update thing
			[self _updateAllAttributesOfObject:contact];

			//Check to see if we should add to a metaContact
			AIMetaContact *metaContact = [contactToMetaContactLookupDict objectForKey:[contact internalObjectID]];
			if (metaContact){
				/* We already know to add this object to the metaContact, since we did it before with another object, 
				   but this particular listContact is new and needs to be added directly to the metaContact
				   (on future launches, the metaContact will obtain it automatically since all contacts matching this UID
				   and serviceID should be included). */
				[self _performAddListObject:contact toMetaContact:metaContact];
			}
			
			//Add
			[contactDict setObject:contact forKey:key];
			[contact release];
		}
	}
	
	return(contact);
}

- (AIListContact *)existingContactWithService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID
{	
	if(inService && [inUID length]){
		return([contactDict objectForKey:[AIListContact internalUniqueObjectIDForService:inService
																				 account:inAccount
																					 UID:inUID]]);
	}else{
		return(nil);
	}
}

- (NSArray *)allContactsWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID
{	
	return([self allContactsWithService:[[owner accountController] firstServiceWithServiceID:inServiceID]
									UID:inUID]);
}

- (NSArray *)allContactsWithService:(AIService *)service UID:(NSString *)inUID
{	
	NSEnumerator	*enumerator;
	AIAccount		*account;
	NSMutableArray  *returnContactArray = [NSMutableArray array];

	enumerator = [[[owner accountController] accountsWithServiceClassOfService:service] objectEnumerator];
	
	while(account = [enumerator nextObject]){
		[returnContactArray addObject:[self contactWithService:service
													   account:account
														   UID:inUID]];
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
		if([[listObject internalObjectID] isEqualToString:uniqueID]) return(listObject);
	}
		
	//Group
	enumerator = [groupDict objectEnumerator];
	while(listObject = [enumerator nextObject]){
		if([[listObject internalObjectID] isEqualToString:uniqueID]) return(listObject);
	}
	
	//Metacontact
	enumerator = [metaContactDict objectEnumerator];
	while(listObject = [enumerator nextObject]){
		if([[listObject internalObjectID] isEqualToString:uniqueID]) return(listObject);
	}
	
	return(nil);
}

- (AIListContact *)preferredContactForContentType:(NSString *)inType forListContact:(AIListContact *)inContact
{
	AIListContact   *returnContact = nil;
	AIAccount		*account;
	
	if ([inContact isKindOfClass:[AIMetaContact class]]){
		AIListObject	*preferredContact;
		NSString		*internalObjectID;
		
		
		//If we've messaged this object previously, and the account we used to message it is online, return that account
        internalObjectID = [inContact preferenceForKey:KEY_PREFERRED_DESTINATION_CONTACT
												 group:OBJECT_STATUS_CACHE];
		
        if((internalObjectID) &&
		   (preferredContact = [self existingListObjectWithUniqueID:internalObjectID]) &&
		   ([preferredContact isKindOfClass:[AIListContact class]])){
			returnContact = [self preferredContactForContentType:inType
												  forListContact:(AIListContact *)preferredContact];
        }
		
		if (!returnContact){
			//Recurse into metacontacts if necessary
			returnContact = [self preferredContactForContentType:inType
												  forListContact:[(AIMetaContact *)inContact preferredContact]];
		}
		
	}else{
		
		//We have a flat contact; find the best account for talking to this contact,
		//and return an AIListContact on that account
		account = [[owner accountController] preferredAccountForSendingContentType:inType
																		 toContact:inContact];
		if (account) {
			returnContact = [self contactWithService:[inContact service]
											 account:account 
												 UID:[inContact UID]];
		}
 	}
	
	return(returnContact);
}

//Retrieve a list contact matching the UID and serviceID of the passed contact but on the specified account.
//In many cases this will be the same as inContact.
- (AIListContact *)contactOnAccount:(AIAccount *)account fromListContact:(AIListContact *)inContact
{
	if(account){
		return([self contactWithService:[inContact service] account:account UID:[inContact UID]]);
	}else{
		return(inContact);
	}
}

#warning This is ridiculous.
- (AIListContact *)preferredContactWithUID:(NSString *)inUID andServiceID:(NSString *)inService forSendingContentType:(NSString *)inType
{
	AIService		*theService = [[owner accountController] firstServiceWithServiceID:inService];
	AIListContact	*tempListContact = [[AIListContact alloc] initWithUID:inUID 
																service:theService];
	AIAccount		*account = [[owner accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE 
																					  toContact:tempListContact
																				 includeOffline:YES];
	[tempListContact release];
	
	return([self contactWithService:theService account:account UID:inUID]);
}


//Watch outgoing content, remembering the user's choice of destination contact for contacts within metaContacts
- (void)didSendContent:(NSNotification *)notification
{
    AIChat			*chat = [notification object];
    AIListContact	*destContact = [chat listObject];
    AIListObject	*metaContact;
	
	//Note: parentContactForListObject returns the passed contact if it is not in a metaContact; 
	//this is a quick and easy check.
    if((chat) && 
	   (destContact) && 
	   ((metaContact = [self parentContactForListObject:destContact]) != destContact)){

		[metaContact setPreference:[destContact internalObjectID]
							forKey:KEY_PREFERRED_DESTINATION_CONTACT
							 group:OBJECT_STATUS_CACHE];
    }
}

//Retrieving Groups ----------------------------------------------------------------------------------------------------
#pragma mark Retrieving Groups

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
			group = [[AIListGroup alloc] initWithUID:groupUID];
			//[group setStatusObject:groupName forKey:@"FormattedUID" notify:YES];
			
			//Place new groups at the bottom of our list (by giving them the largest ordering index)
//			largestOrder += 1.0;
//			[group setOrderIndex:largestOrder];
			float orderIndex = [group orderIndex];
			if (orderIndex > nextOrderIndex) nextOrderIndex = orderIndex + 1;
			
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
			[group release];
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
			NSEnumerator	*enumerator;
			AIAccount		*account;
			
			//If this is a group, delete all the objects within it
			[self removeListObjects:[(AIListGroup *)listObject containedObjects]];
			
			//Delete the list off of all active accounts
			enumerator = [[[owner accountController] accountArray] objectEnumerator];
			while (account = [enumerator nextObject]){
				if ([account online]){
					[account deleteGroup:(AIListGroup *)listObject];
				}
			}
			
			//Then, procede to delete the group
			[listObject retain];
			[(AIMetaContact *)containingObject removeObject:listObject];
			[groupDict removeObjectForKey:[listObject UID]];
			[self _listChangedGroup:containingObject object:listObject];
			[listObject release];
			
		}else{
			[[(AIListContact *)listObject account] removeContacts:[NSArray arrayWithObject:listObject]];
		}
	}
}

- (void)addContacts:(NSArray *)contactArray toGroup:(AIListGroup *)group
{
	NSEnumerator	*enumerator;
	AIListContact	*listObject;
	
	enumerator = [contactArray objectEnumerator];
	while(listObject = [enumerator nextObject]){
		[[listObject account] addContacts:[NSArray arrayWithObject:listObject] toGroup:group];
	}
}

- (void)requestAddContactWithUID:(NSString *)contactUID service:(AIService *)inService
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:contactUID, UID, inService, @"service",nil];
	[[owner notificationCenter] postNotificationName:Contact_AddNewContact
											  object:nil
											userInfo:userInfo];
}

- (void)moveListObjects:(NSArray *)objectArray toGroup:(AIListObject<AIContainingObject> *)group index:(int)index
{
	NSEnumerator	*enumerator;
	AIListContact	*listContact;

	enumerator = [objectArray objectEnumerator];
	while(listContact = [enumerator nextObject]){
		[self moveContact:listContact toGroup:group];
		
		//Set the new index / position of the object
		[self _positionObject:listContact atIndex:index inGroup:group];
	}

	//Resort
	[[owner contactController] sortContactList];
}

- (void)moveContact:(AIListContact *)listContact toGroup:(AIListObject<AIContainingObject> *)group
{
	//Move the object to the new group if necessary
	if(group != [listContact containingObject]){			
		
		if ([group isKindOfClass:[AIListGroup class]]){
			if([listContact isKindOfClass:[AIMetaContact class]]){
				//This is a meta contact, move the objects within it.  listContacts will give us a flat array of AIListContacts.
				
				/*
				NSEnumerator	*metaEnumerator;
				AIListContact	*aContainedContact;
				
				metaEnumerator = [[(AIMetaContact *)listContact listContacts] objectEnumerator];
				while(aContainedContact = [metaEnumerator nextObject]){
					NSEnumerator	*allContactsEnumerator;
					AIListContact	*specificContact;
					
					//Leave no contact behind.
					allContactsEnumerator = [[self allContactsWithService:[aContainedContact service]
																	  UID:[aContainedContact UID]] objectEnumerator];
					while (specificContact = [allContactsEnumerator nextObject]){
						[self _moveObjectServerside:specificContact toGroup:(AIListGroup *)group];
					}
				}
				*/
				
				[self _moveContactLocally:listContact toGroup:(AIListGroup *)group];
				
			}else if([listContact isKindOfClass:[AIListContact class]]){
				//Move the object 
				[self _moveObjectServerside:listContact toGroup:(AIListGroup *)group];
			}
			
		}else if ([group isKindOfClass:[AIMetaContact class]]){
			//Moving a contact into a meta contact
			[self addListObject:listContact toMetaContact:(AIMetaContact *)group];
		}
	}
}

//Move an object to another group
- (void)_moveObjectServerside:(AIListObject *)listObject toGroup:(AIListGroup *)group
{
	AIAccount	*account = [(AIListContact *)listObject account];
	if ([account online]){
		[account moveListObjects:[NSArray arrayWithObject:listObject] toGroup:group];
	}
}

- (void)_moveContactLocally:(AIListContact *)listContact toGroup:(AIListGroup *)group
{
	AIListObject	*listContactContainingObject;
	
	//Protect with a retain while we are removing and adding the contact to our arrays
	[listContact retain];
	
	//Remove this object from any local groups we have it in currently
	listContactContainingObject = [listContact containingObject];
	if(listContactContainingObject && [listContactContainingObject isKindOfClass:[AIListGroup class]]){
		//Remove the object
		[(AIListGroup *)listContactContainingObject removeObject:listContact];
		[self _listChangedGroup:(AIListGroup *)listContactContainingObject object:listContact];
	}

	//Add this contact to the group
	[group addObject:listContact];
	[self _listChangedGroup:group object:listContact];
	
	//Cleanup
	[listContact release];
}

//Rename a group
- (void)_renameGroup:(AIListGroup *)listGroup to:(NSString *)newName
{
	NSEnumerator	*enumerator = [[[owner accountController] accountArray] objectEnumerator];
	AIAccount		*account;
	
	//Since Adium has no memory of what accounts a group is on, we have to send this message to all available accounts
	//The accounts without this group will just ignore it
	while(account = [enumerator nextObject]){
		[account renameGroup:listGroup to:newName];
	}
	
	//Remove the old group if it's empty
	if([listGroup containedObjectsCount] == 0){
		[self removeListObjects:[NSArray arrayWithObject:listGroup]];
	}
}

//Position a list object within a group
- (void)_positionObject:(AIListObject *)listObject atIndex:(int)index inGroup:(AIListObject<AIContainingObject> *)group
{
	if(index == 0){		
		//Moved to the top of a group.  New index is between 0 and the lowest current index
		[listObject setOrderIndex:([group smallestOrder] / 2.0)];
		
	}else if(index >= [group visibleCount]){
		//Moved to the bottom of a group.  New index is one higher than the highest current index
		[listObject setOrderIndex:([group largestOrder] + 1.0)];
		
	}else{
		//Moved somewhere in the middle.  New index is the average of the next largest and smallest index
		AIListObject	*previousObject = [group objectAtIndex:index-1];
		AIListObject	*nextObject = [group objectAtIndex:index];
		float nextLowest = [previousObject orderIndex];
		float nextHighest = [nextObject orderIndex];
		
		//
		[listObject setOrderIndex:((nextHighest + nextLowest) / 2.0)];
	}
}

- (float)nextOrderIndex
{
	return nextOrderIndex++;
}

@end


