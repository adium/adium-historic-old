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

// $Id: AIContactController.m,v 1.65 2004/01/07 21:29:17 adamiser Exp $

#import "AIContactController.h"
#import "AIAccountController.h"
#import "AIContactListEditorWindowController.h"
#import "AIContactInfoWindowController.h"
#import "AIPreferenceCategory.h"
#import "AIContactListGeneration.h"

#define CONTACT_LIST_GROUP_NAME		@"Contact List"		//The name of the main contact list group
#define STRANGER_GROUP_NAME		@"__Strangers"		//The name of the hidden stranger group
#define KEY_CONTACT_LIST 		@"ContactList"		//Contact list key
#define PREF_GROUP_CONTACT_LIST		@"Contact List"		//Contact list preference group
#define GET_INFO_MENU_TITLE		@"Get Info"
#define KEY_CONTACT_LIST_ORDER		@"Contact List Order"
#define KEY_CONTACT_GROUP_ORDER		@"Contact Group Order"

#define ORDER_INDEX_SMALLEST		0
#define ORDER_INDEX_LARGEST		10000

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
@end

//Used to suppress compiler warnings
@interface NSObject (_RESPONDS_TO_CONTACT)
- (AIListContact *)contact;
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
	updatesAreDelayed = NO;
	contactDict = nil;
	groupDict = nil;
	contactList = nil;

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
	//Save contact list
	[[owner preferenceController] setPreference:[self _arrayRepresentationOfGroupContent:contactList]
										 forKey:KEY_CONTACT_LIST
										  group:PREF_GROUP_CONTACT_LIST];
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
//Load the contact list
- (void)loadContactList
{
	NSArray		*contactListArray;
	
	//Load the contact list
	contactDict = [[NSMutableDictionary alloc] init];
	groupDict = [[NSMutableDictionary alloc] init];
	contactList = [[AIListGroup alloc] initWithUID:CONTACT_LIST_GROUP_NAME];
	if(contactListArray = [[owner preferenceController] preferenceForKey:KEY_CONTACT_LIST group:PREF_GROUP_CONTACT_LIST]){
		[self _loadListObjectsFromGroupContent:contactListArray intoGroup:contactList];
	}
}

//Flatten the passed group into an array
- (NSArray *)_arrayRepresentationOfGroupContent:(AIListGroup *)inGroup
{
	NSMutableArray	*array = [NSMutableArray array];
	NSEnumerator	*enumerator = [inGroup objectEnumerator];
	AIListObject	*object;
	
	//Get the represented dicts of all our content
	while(object = [enumerator nextObject]){
		NSString		*type = nil;
		NSDictionary	*infoDict = nil;
		
		//
		if([object isKindOfClass:[AIListContact class]]){
			type = @"AIListContact";
			infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
				[object UID], @"UID",
				[object serviceID], @"ServiceID",
				nil];
			
		}else if([object isKindOfClass:[AIListGroup class]]){
			type = @"AIListGroup";
			infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
				[object UID], @"UID",
				[self _arrayRepresentationOfGroupContent:(AIListGroup *)object], @"Content",
				nil];
		}
		
		//
		if(type && infoDict){
			[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				type, @"Type",
				infoDict, @"Info",
				nil]];
		}
	}
	
	return(array);
}

//Create groups and objects from the previously flattened group array
- (void)_loadListObjectsFromGroupContent:(NSArray *)contentArray intoGroup:(AIListGroup *)inGroup
{
	NSEnumerator	*enumerator;
	NSDictionary	*objectDict;
	
	enumerator = [contentArray objectEnumerator];
	while(objectDict = [enumerator nextObject]){
		NSString		*type = [objectDict objectForKey:@"Type"];
		NSDictionary	*infoDict = [objectDict objectForKey:@"Info"];
		AIListObject	*object = nil;
		
		if([type compare:@"AIListContact"] == 0){			
			object = [self contactWithService:[infoDict objectForKey:@"ServiceID"]
										  UID:[infoDict objectForKey:@"UID"]];
			
			[inGroup addObject:object];
			
		}else if([type compare:@"AIListGroup"] == 0){
			object = [self groupWithUID:[infoDict objectForKey:@"UID"]];
			
			[inGroup addObject:object];
			[self _loadListObjectsFromGroupContent:[infoDict objectForKey:@"Content"]
										 intoGroup:(AIListGroup *)object];
			
		}
	}
}


//Status and Display updates -------------------------------------------------------------------------------------------
//Delay all list object notifications until a period of inactivity occurs
//This delays Contact_ListChanged, ListObject_AttributesChanged, and Contact_OrderChanged notifications
// Delayed: Delays sorting and redrawing to prevent redundancy when making a large number of changes
- (void)delayListObjectNotifications
{
#warning (Intentional) Event delays are disabled for now, pending an investigation of their usefulness :)
//    if(!delayedUpdateTimer){
//			updatesAreDelayed = YES;
//        	delayedUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:UPDATE_CLUMP_INTERVAL target:self selector:@selector(_performDelayedUpdates:) userInfo:nil repeats:YES] retain];
//    }
}

//Remote grouping of a list object has changed
- (void)listObjectRemoteGroupingChanged:(AIListContact *)inObject oldGroupName:(NSString *)oldGroupName
{
	AIMutableOwnerArray		*remoteGroups = [inObject remoteGroupArray];
	NSEnumerator			*enumerator;
	NSString				*groupName;
	BOOL					keepAtOldLocation = NO;
	
	//
	if(updatesAreDelayed) delayedContentChanges++;
	
	//First, let's check to see if any account still wants the object in the old location.  If no one still wants it
	//there we can remove it - otherwise, it stays.
	if(oldGroupName){
		enumerator = [remoteGroups objectEnumerator];
		while(groupName = [enumerator nextObject]){
			if([oldGroupName compare:groupName] == 0){
				keepAtOldLocation = YES;
				break;
			}
		}
		
		if(!keepAtOldLocation){
			AIListGroup *oldGroup = [self groupWithUID:oldGroupName];
			
			[oldGroup removeObject:inObject];
			if(!updatesAreDelayed) [[owner notificationCenter] postNotificationName:Contact_ListChanged object:oldGroup];
		}
	}
	
	//Second, we check to make sure the object is in every requested group
	//If it's not in a group, we create that group at the root of the contact list (if necessary) and stick it in there
	enumerator = [remoteGroups objectEnumerator];
	while(groupName = [enumerator nextObject]){
		AIListGroup		*group = [self groupWithUID:groupName];
		
		//Add to list if necessary
		if([[group containingGroups] count] == 0){
			[contactList addObject:group];
		}
		
		//Add the object if necessary
		if(![group containsObject:inObject]){
			[group addObject:inObject];
			
			//Post a list content changed notification for the contaning group
			if(!updatesAreDelayed) [[owner notificationCenter] postNotificationName:Contact_ListChanged object:group];
		}
	}
}

//Called after modifying a contact's status
// Silent: Silences all events, notifications, sounds, overlays, etc. that would have been associated with this status change
- (void)listObjectStatusChanged:(AIListObject *)inObject modifiedStatusKeys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    NSArray		*modifiedAttributeKeys;
		
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
    //If updates have been delayed, we process them.  If not, we turn off the delayed update timer.
	if(delayedStatusChanges || delayedAttributeChanges || delayedContentChanges){
		//Send out global attribute & status changed notifications (to cover any delayed updates)
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
		
    }else{
        //Disable the delayed update timer (it is no longer needed).
        [delayedUpdateTimer invalidate]; [delayedUpdateTimer release]; delayedUpdateTimer = nil;
		updatesAreDelayed = NO;
    }
}


//Contact Info --------------------------------------------------------------------------------
//Show info for the selected contact
- (IBAction)showContactInfo:(id)sender
{
    [self showInfoForContact:[self selectedContact]];
}

//Show the info window for a contact
- (void)showInfoForContact:(AIListContact *)inContact
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
//Returns the "selected"(represented) contact (By finding the first responder that returns a contact)
- (AIListContact *)selectedContact
{
    NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];

    //Check the first responder
    if([responder respondsToSelector:@selector(contact)]){
        return([responder contact]);
    }

    //Search the responder chain
    do{
        responder = [responder nextResponder];
        if([responder respondsToSelector:@selector(contact)]){
            return([responder contact]);
        }
        
    } while(responder != nil);

    //Noone found, return nil
    return(nil);
}


//Contact Sorting --------------------------------------------------------------------------------
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
	NSEnumerator	*enumerator = [[inObject containingGroups] objectEnumerator];
	AIListGroup		*group;
	
	//Sort all the groups containing this object
	while(group = [enumerator nextObject]){		
		[group sortListObject:inObject sortController:activeSortController];
		[[owner notificationCenter] postNotificationName:Contact_OrderChanged object:group];
	}
}


//List object observers ------------------------------------------------------------------------------------------------
//Registers code to observe handle status changes
- (void)registerListObjectObserver:(id <AIListObjectObserver>)inObserver
{
	NSEnumerator	*enumerator = [contactDict objectEnumerator];
	AIListObject	*listObject;
    
	//Add the observer
    [contactObserverArray addObject:inObserver];
	
    //Let the new observer process all existing objects
	while(listObject = [enumerator nextObject]){
		[inObserver updateListObject:listObject keys:nil silent:YES];
	}
}

- (void)unregisterListObjectObserver:(id)inObserver
{
    [contactObserverArray removeObject:inObserver];
	[self sortContactList];
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
	return(attrChange);
}

//Notifies observers that an object was created
- (void)_informObserversOfObjectCreation:(AIListObject *)inObject
{
	NSEnumerator				*enumerator = [contactObserverArray objectEnumerator];
    id <AIListObjectObserver>	observer;
	
	while((observer = [enumerator nextObject])){
		[observer updateListObject:inObject keys:nil silent:YES];
	}
}


//Contact List ---------------------------------------------------------------------------------------------------------
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

//Retrieve a contact from the contact list (Creating if necessary)
- (AIListContact *)contactWithService:(NSString *)serviceID UID:(NSString *)UID
{
	NSString		*key = [NSString stringWithFormat:@"%@.%@", serviceID, UID];
	AIListContact	*contact = [contactDict objectForKey:key];
	
	if(!contact){
		//Create
		contact = [[[AIListContact alloc] initWithUID:UID serviceID:serviceID] autorelease];
		[self _informObserversOfObjectCreation:contact];
		
		//Add
		[contactDict setObject:contact forKey:key];
	}
	
	return(contact);
}

//Retrieve a group from the contact list (Creating if necessary)
- (AIListGroup *)groupWithUID:(NSString *)groupUID
{
	AIListGroup		*group = [groupDict objectForKey:groupUID];
	
	if(!group){
		//Create
		group = [[[AIListGroup alloc] initWithUID:groupUID] autorelease];
		[self _informObserversOfObjectCreation:group];
		
		[groupDict setObject:group forKey:groupUID];
	}
	
	return(group);
}

@end

