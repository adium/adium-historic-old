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

// $Id: AIContactController.m,v 1.118 2004/03/21 18:59:28 evands Exp $

#import "AIContactController.h"
#import "AIAccountController.h"
#import "AIContactInfoWindowController.h"
#import "AIPreferenceCategory.h"

#define PREF_GROUP_CONTACT_LIST		@"Contact List"			//Contact list preference group
#define KEY_FLAT_GROUPS				@"FlatGroups"			//Group storage
#define KEY_FLAT_CONTACTS			@"FlatContacts"			//Contact storage

#define UPDATE_CLUMP_INTERVAL		1.0

@interface AIContactController (PRIVATE)
- (void)_handle:(AIHandle *)inHandle addedToAccount:(AIAccount *)inAccount;
- (void)_handle:(AIHandle *)inHandle removedFromAccount:(AIAccount *)inAccount;
- (void)_handlesChangedForAccount:(AIAccount *)inAccount;
- (void)processHandle:(AIHandle *)handle;
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

- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector;
- (id)_performSelectorOnFirstAvailableResponder:(SEL)selector conformingToProtocol:(Protocol *)protocol;

- (NSArray *)_arrayRepresentationOfListObjects:(NSArray *)listObjects;
- (NSDictionary *)_compressedOrderingOfObject:(AIListObject *)inObject;
- (void)_applyCompressedOrdering:(NSDictionary *)orderDict toObject:(AIListObject *)inObject;
- (void)_loadListObjectsFromArray:(NSArray *)array;

- (void)_listChangedGroup:(AIListGroup *)group object:(AIListObject *)object;

- (void)_positionObject:(AIListObject *)listObject atIndex:(int)index inGroup:(AIListGroup *)group;
- (void)_moveObject:(AIListObject *)listObject toGroup:(AIListGroup *)group;
- (void)_renameGroup:(AIListGroup *)listGroup to:(NSString *)newName;
@end

//Used to suppress compiler warnings
@interface NSObject (_RESPONDS_TO_LIST_OBJECT)
- (AIListObject *)listObject;
@end


@implementation AIContactController

//init
- (void)initController
{    
    //
    contactObserverArray = [[NSMutableArray alloc] init];
    sortControllerArray = [[NSMutableArray alloc] init];
    activeSortController = nil;
    delayedStatusChanges = 0;
	delayedAttributeChanges = 0;
    delayedContentChanges = 0;
	delayedUpdateRequests = 0;
	updatesAreDelayed = NO;
	contactDict = [[NSMutableDictionary alloc] init];
	groupDict = [[NSMutableDictionary alloc] init];
	contactList = [[AIListGroup alloc] initWithUID:ADIUM_ROOT_GROUP_NAME];
	largestOrder = 1.0;
	smallestOrder = 1.0;

	// AIContactStatusEvents Stuff
    onlineDict = [[NSMutableDictionary alloc] init];
    awayDict = [[NSMutableDictionary alloc] init];
    idleDict = [[NSMutableDictionary alloc] init];
    [owner registerEventNotification:CONTACT_STATUS_AWAY_YES displayName:@"Contact Away"];
	[owner registerEventNotification:CONTACT_STATUS_AWAY_NO displayName:@"Contact UnAway"];
	[owner registerEventNotification:CONTACT_STATUS_ONLINE_YES displayName:@"Contact Signed On"];
	[owner registerEventNotification:CONTACT_STATUS_ONLINE_NO displayName:@"Contact Signed Off"];
	[owner registerEventNotification:CONTACT_STATUS_IDLE_YES displayName:@"Contact Idle"];
	[owner registerEventNotification:CONTACT_STATUS_IDLE_NO displayName:@"Contact UnIdle"];

	//
    [owner registerEventNotification:ListObject_StatusChanged displayName:@"Contact Status Changed"];
    contactInfoCategory = [[AIPreferenceCategory categoryWithName:@"" image:nil] retain];
}

//finish initing
- (void)finishIniting
{
	[self loadContactList];
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
    [contactInfoCategory release];

    [super dealloc];
}


//Local Contact List Storage -------------------------------------------------------------------------------------------
#pragma mark Local Contact List Storage
//Load the contact list
- (void)loadContactList
{	
	//We must load all the groups before loading contacts for the ordering system to work correctly.
	[self _loadListObjectsFromArray:[[owner preferenceController] preferenceForKey:KEY_FLAT_GROUPS
																			 group:PREF_GROUP_CONTACT_LIST]];
	[self _loadListObjectsFromArray:[[owner preferenceController] preferenceForKey:KEY_FLAT_CONTACTS
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
- (void)_loadListObjectsFromArray:(NSArray *)array
{
	NSEnumerator	*enumerator = [array objectEnumerator];;
	NSDictionary	*infoDict;
	
	while(infoDict = [enumerator nextObject]){
		NSString		*type = [infoDict objectForKey:@"Type"];
		AIListObject	*object = nil;
		
		//Object
		if([type compare:@"Contact"] == 0){
			object = [self contactWithService:[infoDict objectForKey:@"ServiceID"]
									accountID:[infoDict objectForKey:@"AccountID"]
										  UID:[infoDict objectForKey:@"UID"]];
			
		}else if([type compare:@"Group"] == 0){
			object = [self groupWithUID:[infoDict objectForKey:@"UID"]];
			[(AIListGroup *)object setExpanded:[[infoDict objectForKey:@"Expanded"] boolValue]];

		}
		
		//Ordering
		if(object){
			float orderIndex = [[infoDict objectForKey:@"Ordering"] floatValue];
			
			if(orderIndex > largestOrder) largestOrder = orderIndex;
			if(orderIndex < smallestOrder) smallestOrder = orderIndex;
			
			[object setOrderIndex:orderIndex];
		}
	}
}

//Flattened array of the contact list content
- (NSArray *)_arrayRepresentationOfListObjects:(NSArray *)listObjects
{
	NSMutableArray	*array = [NSMutableArray array];
	NSEnumerator	*enumerator = [listObjects objectEnumerator];;
	AIListObject	*object;
	
	while(object = [enumerator nextObject]){
		if([object isKindOfClass:[AIListContact class]]){
			[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				@"Contact", @"Type",
				[object UID], @"UID",
				[(AIListContact *)object accountID], @"AccountID",
				[object serviceID], @"ServiceID",
				[NSNumber numberWithFloat:[object orderIndex]], @"Ordering",
				nil]];
			
		}else if([object isKindOfClass:[AIListGroup class]]){
			[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				@"Group", @"Type",
				[object UID], @"UID",
				[NSNumber numberWithBool:[(AIListGroup *)object isExpanded]], @"Expanded",
				[NSNumber numberWithFloat:[object orderIndex]], @"Ordering",
				nil]];
			
		}
	}
	
	return(array);
}


//Status and Display updates -------------------------------------------------------------------------------------------
#pragma mark Status and Display updates
//These delay Contact_ListChanged, ListObject_AttributesChanged, Contact_OrderChanged notificationsDelays, 
//sorting and redrawing to prevent redundancy when making a large number of changes
//Explicit delay.  Call endListObjectNotificationDelay to end
- (void)delayListObjectNotifications
{
	delayedUpdateRequests++;
	updatesAreDelayed = YES;
}

//End an explicit delay
- (void)endListObjectNotificationDelay
{
	delayedUpdateRequests--;
	if(delayedUpdateTimer == 0 && !delayedUpdateTimer){
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
	AIListGroup			*localGroup;
	AIListObject		*existingObject;

	//Remove this object from any local groups we have it in currently
	if(localGroup = [inObject containingGroup]){
		//Remove the object
		[localGroup removeObject:inObject];

		//If this object existed in a meta contact we'll either need to update the meta contact, or remove it.
		if([localGroup isKindOfClass:[AIMetaContact class]]){
			if([localGroup count] == 1){
				//Remove the meta contact as it's no longer needed				
				AIListObject	*internalObject = [localGroup objectAtIndex:0];
				AIListGroup		*mainGroup = [localGroup containingGroup];
				
				[internalObject retain];
				
				[localGroup removeObject:internalObject];
				[mainGroup removeObject:localGroup];
				[self _listChangedGroup:mainGroup object:localGroup];
				
				[mainGroup addObject:internalObject];
				[self _listChangedGroup:mainGroup object:internalObject];
				
				[internalObject release];
				
			}else{
				//Update the meta contact's attributes
				[self _updateAllAttributesOfObject:localGroup];
				
			}
		}else{
			[self _listChangedGroup:localGroup object:inObject];
		}
	}
	
	//Add this object to its new group
	if(remoteGroup){
		//Fun :)
		//remoteGroup = [NSString stringWithFormat:@"%@:%@",[inObject accountUID],remoteGroup];

		//
		localGroup = [self groupWithUID:remoteGroup];
		existingObject = [localGroup objectWithServiceID:[inObject serviceID] UID:[inObject UID]];
		if(existingObject){
			//If a similar object already exists, we want to group this new one together with it
			AIMetaContact	*metaContact;

			if([existingObject isKindOfClass:[AIMetaContact class]]){
				//If the existing object is a meta contact, we place our new one inside it.
				[(AIMetaContact *)existingObject addObject:inObject];

				//Update the meta contact's attributes
				[self _updateAllAttributesOfObject:existingObject];

			}else{
				//If the existing object is not a meta contact, we will create one and place both the existing object
				//and the new object within it
				metaContact = [[[AIMetaContact alloc] initWithUID:[inObject UID] serviceID:[inObject serviceID]] autorelease];
				[metaContact addObject:inObject];

				//Place existing contact within it
				[existingObject retain];
				
				[localGroup removeObject:existingObject];
				[self _listChangedGroup:localGroup object:existingObject];
				
				[metaContact addObject:(AIListContact *)existingObject];
				
				[existingObject release];

				//Update the meta contact's attributes
				[self _updateAllAttributesOfObject:metaContact];

				//Add the new meta contact to our list
				[localGroup addObject:metaContact];
				[self _listChangedGroup:localGroup object:metaContact];
			}
			
		}else{
			//If no similar objects exist, we add this contact directly to the list
			[localGroup addObject:inObject];
			[self _listChangedGroup:localGroup object:inObject];
		}
	}
}

//Post a list grouping changed notification for the object and group
- (void)_listChangedGroup:(AIListGroup *)group object:(AIListObject *)object
{
	if(updatesAreDelayed){
		delayedContentChanges++;
	}else{
		[[owner notificationCenter] postNotificationName:Contact_ListChanged 
												  object:object
												userInfo:[NSDictionary dictionaryWithObject:group forKey:@"ContainingGroup"]];
	}
}
	
//Called after modifying a contact's status
// Silent: Silences all events, notifications, sounds, overlays, etc. that would have been associated with this status change
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    NSArray			*modifiedAttributeKeys;
	
    //Let all observers know the contact's status has changed
	modifiedAttributeKeys = [self _informObserversOfObjectStatusChange:inObject withKeys:inModifiedKeys silent:silent];
	
    //Resort the contact list
	if(updatesAreDelayed){
		delayedStatusChanges++;
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
    AIMetaContact	*metaContact = (AIMetaContact *)[inObject containingGroup];
    if(metaContact && [metaContact isKindOfClass:[AIMetaContact class]]){
		[self listObjectStatusChanged:metaContact modifiedStatusKeys:inModifiedKeys silent:silent];
	}
}

//Call after modifying an object's display attributes
//(When modifying display attributes in response to a status change, this is not necessary)
- (void)listObjectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSArray *)inModifiedKeys
{	
	if(updatesAreDelayed){
		delayedAttributeChanges++;
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
	BOOL	updatesOccured = (delayedStatusChanges || delayedAttributeChanges || delayedContentChanges);
	
	//Send out global attribute & status changed notifications (to cover any delayed updates)
	if(updatesOccured){
		if(delayedAttributeChanges){
			[[owner notificationCenter] postNotificationName:ListObject_AttributesChanged object:nil];
		}
		if(delayedContentChanges){
			[[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
		}
		
		//Resort the list
		[self sortContactList];
		
        //Reset the delayed update count back to 0
		delayedStatusChanges = 0;
		delayedAttributeChanges = 0;
		delayedContentChanges = 0;
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


//Contact Info --------------------------------------------------------------------------------
#pragma mark Contact Info
//Show info for the selected contact
- (IBAction)showContactInfo:(id)sender
{
    [[AIContactInfoWindowController contactInfoWindowControllerWithCategory:contactInfoCategory] showWindow:nil];
}

//Add a contact info view
- (void)addContactInfoView:(AIPreferenceViewController *)inView
{
    [contactInfoCategory addView:inView];
}

//Always be able to show the inspector
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    return(YES);
}


//Selected contact ------------------------------------------------
#pragma mark Selected contact
//Returns the "selected"(represented) contact (By finding the first responder that returns a contact)
- (AIListObject *)selectedListObject
{
	return([self _performSelectorOnFirstAvailableResponder:@selector(listObject)]);
}
- (AIListObject *)selectedListObjectInContactList
{
	return([self _performSelectorOnFirstAvailableResponder:@selector(listObject) conformingToProtocol:@protocol(ContactListOutlineView)]);
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
    [[owner notificationCenter] postNotificationName:Contact_SortSelectorListChanged object:nil userInfo:nil];
}
- (NSArray *)sortControllerArray
{
    return(sortControllerArray);
}

//Set and get the active sort controller
- (void)setActiveSortController:(AISortController *)inController
{
    activeSortController = inController;
	
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
		delayedStatusChanges++;
	}else{
		AIListGroup		*group = [inObject containingGroup];
		
		//Sort the groups containing this object
		[group sortListObject:inObject sortController:activeSortController];
		[[owner notificationCenter] postNotificationName:Contact_OrderChanged object:group];
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
		AIMetaContact	*metaContact = (AIMetaContact *)[listObject containingGroup];
		if(metaContact && [metaContact isKindOfClass:[AIMetaContact class]]){
			NSArray	*attributes = [inObserver updateListObject:metaContact keys:nil silent:YES];
			if(attributes) [self listObjectAttributesChanged:metaContact modifiedKeys:attributes];
		}
	}

    //Reset all groups
	enumerator = [groupDict objectEnumerator];
	while(listObject = [enumerator nextObject]){
		NSArray	*attributes = [inObserver updateListObject:listObject keys:nil silent:YES];
		if(attributes) [self listObjectAttributesChanged:listObject modifiedKeys:attributes];
	}
	
	//
	[self endListObjectNotificationDelay];
}

//Notify observers of a status change.  Returns the modified attribute keys
- (NSArray *)_informObserversOfObjectStatusChange:(AIListObject *)inObject withKeys:(NSArray *)modifiedKeys silent:(BOOL)silent
{
	NSMutableArray				*attrChange = [NSMutableArray array];
	NSEnumerator				*enumerator;
    id <AIListObjectObserver>	observer;
	
	//Let our observers know
	enumerator = [contactObserverArray objectEnumerator];
	while((observer = [enumerator nextObject])){
		NSArray	*newKeys;
		
		if((newKeys = [observer updateListObject:inObject keys:modifiedKeys silent:silent])){
			[attrChange addObjectsFromArray:newKeys];
		}
	}
	
	//Send out the notification for other observers
	[[owner notificationCenter] postNotificationName:ListObject_StatusChanged
											  object:inObject
											userInfo:(modifiedKeys ? [NSDictionary dictionaryWithObject:modifiedKeys forKey:@"Keys"] : nil)];
	
	if (![inObject isKindOfClass: [AIAccount class]]) {

		if([modifiedKeys containsObject:@"Online"]){ //Sign on/off
			BOOL		newStatus = [inObject integerStatusObjectForKey:@"Online"];
			NSNumber	*oldStatusNumber = [onlineDict objectForKey:[inObject uniqueObjectID]];
			BOOL		oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough

			if(oldStatusNumber == nil || newStatus != oldStatus){
				//Save the new status
				[onlineDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inObject uniqueObjectID]];
				
				//Take action (If this update isn't silent)
				if(!silent){
					[[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_ONLINE_YES : CONTACT_STATUS_ONLINE_NO) object:inObject userInfo:nil];
				}
			}
		}

		if([modifiedKeys containsObject:@"Away"]){ //Away / Unaway
			BOOL		newStatus = [inObject integerStatusObjectForKey:@"Away"];
			NSNumber	*oldStatusNumber = [awayDict objectForKey:[inObject uniqueObjectID]];
			BOOL		oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough
			
			if(oldStatusNumber == nil || newStatus != oldStatus){
				//Save the new state
				[awayDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inObject uniqueObjectID]];
				
				//Take action (If this update isn't silent)
				if(!silent){
					[[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_AWAY_YES : CONTACT_STATUS_AWAY_NO) object:inObject userInfo:nil];
				}
				
			}
		}
		
		if([modifiedKeys containsObject:@"IdleSince"]){ //Idle / UnIdle
			NSDate 		*idleSince = [inObject earliestDateStatusObjectForKey:@"IdleSince"];
			NSNumber	*oldStatusNumber = [idleDict objectForKey:[inObject uniqueObjectID]];
			BOOL		oldStatus = [oldStatusNumber boolValue]; //UID is not unique enough
			BOOL		newStatus = (idleSince != nil);
			
			if(oldStatusNumber == nil || newStatus != oldStatus){
				//Save the new state
				[idleDict setObject:[NSNumber numberWithBool:newStatus] forKey:[inObject uniqueObjectID]];
				
				//Take action (If this update isn't silent)
				if(!silent){
					[[owner notificationCenter] postNotificationName:(newStatus ? CONTACT_STATUS_IDLE_YES : CONTACT_STATUS_IDLE_NO) object:inObject userInfo:nil];
				}
				
			}
		}
		
	}
	
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

//Returns a flat array of all the contacts in a group (and all subgroups, if desired).
- (NSMutableArray *)allContactsInGroup:(AIListGroup *)inGroup subgroups:(BOOL)subGroups
{
    NSMutableArray	*contactArray = [[NSMutableArray alloc] init];
    NSEnumerator	*enumerator;
    AIListObject	*object;
    
    if(inGroup == nil) inGroup = contactList; //Passing nil scans the entire contact list
	
    enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIListGroup class]]){
            if(subGroups){
                [contactArray addObjectsFromArray:[self allContactsInGroup:(AIListGroup *)object subgroups:subGroups]];
            }
        }else{
            [contactArray addObject:object];
        }
    }
	
    return([contactArray autorelease]);
}

//Return all the objects in a group on an account
- (NSMutableArray *)allContactsInGroup:(AIListGroup *)inGroup onAccount:(AIAccount *)inAccount
{
	NSMutableArray	*contactArray = [NSMutableArray array];
	NSEnumerator	*enumerator;
    AIListObject	*object;
	
	if (inGroup == nil) inGroup = contactList;  //Passing nil scans the entire contact list
	
	enumerator = [inGroup objectEnumerator];
	
    while((object = [enumerator nextObject])){
        if([object isMemberOfClass:[AIMetaContact class]] || [object isMemberOfClass:[AIListGroup class]]){
			[contactArray addObjectsFromArray:[self allContactsInGroup:(AIListGroup *)object onAccount:inAccount]];
			
		}else if([object isMemberOfClass:[AIListContact class]]){
			if([[(AIListContact *)object serviceID] compare:[inAccount serviceID]] == 0 &&
			   [[(AIListContact *)object accountID] compare:[inAccount uniqueObjectID]] == 0){
				[contactArray addObject:object];
			}
		}
	}
	
	return(contactArray);
}

//Retrieve a contact from the contact list (Creating if necessary)
- (AIListContact *)contactWithService:(NSString *)serviceID accountID:(NSString *)accountID UID:(NSString *)UID
{
	AIListContact	*contact = nil;
	
	if(serviceID && [serviceID length] && UID && [UID length]){ //Ignore invalid requests
		NSString		*key = [NSString stringWithFormat:@"%@.%@.%@", serviceID, accountID, UID];
		
		contact = [contactDict objectForKey:key];
		if(!contact){
			//Create
			contact = [[[AIListContact alloc] initWithUID:UID accountID:accountID serviceID:serviceID] autorelease];

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

- (AIListContact *)existingContactWithService:(NSString *)serviceID accountUID:(NSString *)accountUID UID:(NSString *)UID
{	
	if(serviceID && [serviceID length] && UID && [UID length]){
		return([contactDict objectForKey:[NSString stringWithFormat:@"%@.%@.%@", serviceID, accountUID, UID]]);
	}else{
		return(nil);
	}
}

- (AIListContact *)preferredContactForReceivingContentType:(NSString *)inType forListObject:(AIListObject *)inObject
{
	AIAccount	*account = [[owner accountController] preferredAccountForSendingContentType:inType
																			   toListObject:inObject];

	return([self contactWithService:[inObject serviceID] accountID:[account uniqueObjectID] UID:[inObject UID]]);
}

//Retrieve a group from the contact list (Creating if necessary)
- (AIListGroup *)groupWithUID:(NSString *)groupUID
{
	AIListGroup		*group;
	
	if(!groupUID || ![groupUID length] || [groupUID compare:ADIUM_ROOT_GROUP_NAME] == 0){
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
			//If this is a meta contact, delete the objects within it
			NSArray	*containedObjects = [[[(AIMetaContact *)listObject containedObjects] copy] autorelease];
			[self removeListObjects:containedObjects];
			
		}else if([listObject isKindOfClass:[AIListGroup class]]){
			AIListGroup	*containingGroup = [(AIListGroup *)listObject containingGroup];
			
			//If this is a group, delete all the objects within it
			[self removeListObjects:[(AIListGroup *)listObject containedObjects]];
			
			//Then, procede to delete the group
			[listObject retain];
			[containingGroup removeObject:listObject];
			[groupDict removeObjectForKey:[listObject UID]];
			[self _listChangedGroup:containingGroup object:listObject];
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

- (void)moveListObjects:(NSArray *)objectArray toGroup:(AIListGroup *)group index:(int)index
{
	NSEnumerator	*enumerator;
	AIListContact	*listObject;
	
	enumerator = [objectArray objectEnumerator];
	while(listObject = [enumerator nextObject]){
		//Set the new index / position of the object
		[self _positionObject:listObject atIndex:index inGroup:group];

		//Move the object to the new group if necessary
		if(group != [listObject containingGroup]){			

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
//					group = [group containingGroup];
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
	if([listGroup count] == 0){
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


