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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
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
@end

@implementation AIContactController

//init
- (void)initController
{    
    //
    contactObserverArray = [[NSMutableArray alloc] init];
    sortControllerArray = [[NSMutableArray alloc] init];
    activeSortController = nil;
    holdUpdates = NO;
    contactList = [[AIListGroup alloc] initWithUID:CONTACT_LIST_GROUP_NAME];
    contactListGeneration = [[AIContactListGeneration alloc] initWithContactList:contactList owner:owner];

    [owner registerEventNotification:Contact_StatusChanged displayName:@"Contact Status Changed"];
    
    //
    contactInfoCategory = [[AIPreferenceCategory categoryWithName:@"" image:nil] retain];

    //Load the contact ordering
    [self loadContactOrdering];

}

//close
- (void)closeController
{
    //Save the group expand/collapse state
    [contactListGeneration saveGroupState];

    //Save order index information
    [self saveContactOrdering];
}

//dealloc
- (void)dealloc
{
    [contactList release];
    [contactObserverArray release]; contactObserverArray = nil;
    [contactListGeneration release];
    [contactInfoCategory release];

    [super dealloc];
}

// Contact Info --------------------------------------------------------------------------------
- (IBAction)showContactInfo:(id)sender
{
    [self showInfoForContact:[self selectedContact]];
}

//Show the info window for a contact
- (void)showInfoForContact:(AIListContact *)inContact
{
    [[AIContactInfoWindowController contactInfoWindowControllerWithCategory:contactInfoCategory forContact:inContact] showWindow:nil];
}

//Add a contact info view
- (void)addContactInfoView:(AIPreferenceViewController *)inView
{
    [contactInfoCategory addView:inView];
}

// Selected contact ------------------------------------------------
@protocol _RESPONDS_TO_CONTACT //Just a temp protocol to suppress compiler warning when I call contact on the responders below
- (AIListContact *)contact;
@end
//Returns the "selected"(represented) contact.
- (AIListContact *)selectedContact
{
    NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];

    //Find the first responder that returns a selected contact
    //Check the first responder
    if([responder respondsToSelector:@selector(contact)]){
        return([(NSResponder<_RESPONDS_TO_CONTACT> *)responder contact]);
    }

    //Search the responder chain
    do{
        responder = [responder nextResponder];
        if([responder respondsToSelector:@selector(contact)]){
            return([(NSResponder<_RESPONDS_TO_CONTACT> *)responder contact]);
        }
        
    } while(responder != nil);

    //Noone found, return nil
    return(nil);
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    return([self selectedContact] != nil);
}



// Contact list generation
- (void)handlesChangedForAccount:(AIAccount *)inAccount
{
    //Hold contact list updates, and apply the changes to the contact list
    [[owner contactController] setHoldContactListUpdates:YES];
    [contactListGeneration handlesChangedForAccount:inAccount];
    [[owner contactController] setHoldContactListUpdates:NO];

    //Post a handles changed notification for the account
    [[owner notificationCenter] postNotificationName:Account_HandlesChanged object:inAccount]; 
}

- (void)handle:(AIHandle *)inHandle addedToAccount:(AIAccount *)inAccount
{
    //Hold contact list updates, and apply the changes to the contact list
//    [[owner contactController] setHoldContactListUpdates:YES];
    [contactListGeneration handle:inHandle addedToAccount:inAccount];
//    [[owner contactController] setHoldContactListUpdates:NO];

    //Post a handles changed notification
    [[owner notificationCenter] postNotificationName:Account_HandlesChanged object:inAccount];
}

- (void)handle:(AIHandle *)inHandle removedFromAccount:(AIAccount *)inAccount
{
    //Hold contact list updates, and apply the changes to the contact list
//    [[owner contactController] setHoldContactListUpdates:YES];
    [contactListGeneration handle:inHandle removedFromAccount:inAccount];
//    [[owner contactController] setHoldContactListUpdates:NO];

    //Post a handles changed notification
    [[owner notificationCenter] postNotificationName:Account_HandlesChanged object:inAccount];
}





// Handle status --------------------------------------------------------------------------------
//Registers code to observe handle status changes
- (void)registerContactObserver:(id <AIContactObserver>)inObserver
{
    NSEnumerator	*enumerator;
    AIListContact	*contact;
    
    [contactObserverArray addObject:inObserver];

    //Let the handle observer process all existing contacts
    enumerator = [[self allContactsInGroup:nil subgroups:YES] objectEnumerator];
    while((contact = [enumerator nextObject])){
        [inObserver updateContact:contact handle:nil keys:nil];
    }

    //Resort and update the contact list (Since the observer has most likely changed attributes)
    //This may be incorrect.  Will not posting attribute changed messages cause problems?
    [self sortListGroup:nil mode:AISortGroupAndSubGroups];
    [[owner notificationCenter] postNotificationName:Contact_OrderChanged object:nil];
}

//Called after modifying a handle's status
- (void)handleStatusChanged:(AIHandle *)inHandle modifiedStatusKeys:(NSArray *)inModifiedKeys
{
    AIListContact	*listContact;
    
    listContact = [inHandle containingContact];
    if(listContact){
        NSDictionary		*handleStatusDict = [inHandle statusDictionary];
        NSMutableArray		*modifiedAttributeKeys;
        NSEnumerator		*enumerator;
        NSString		*key;
        id <AIContactObserver>	observer;
        
        //Apply all the changed status values to the handle's containing contact
        if(inModifiedKeys){
            enumerator = [inModifiedKeys objectEnumerator];
        }else{
            enumerator = [[handleStatusDict allKeys] objectEnumerator]; //If nil is passed, copy all keys
        }
        while((key = [enumerator nextObject])){
            AIMutableOwnerArray	*ownerArray = [listContact statusArrayForKey:key];

            [ownerArray setObject:[handleStatusDict objectForKey:key] withOwner:inHandle];
        }

        //Let all the observers know the contact has changed
        modifiedAttributeKeys = [NSMutableArray array];
        enumerator = [contactObserverArray objectEnumerator];
        while((observer = [enumerator nextObject])){
            NSArray	*newKeys;

            if((newKeys = [observer updateContact:listContact handle:inHandle keys:inModifiedKeys])){
                [modifiedAttributeKeys addObjectsFromArray:newKeys];
            }
        }

        //Resort the contact list (If necessary)
        if(!holdUpdates && //Skip sorting when updates are delayed
           ([[self activeSortController] shouldSortForModifiedStatusKeys:inModifiedKeys] ||
            [[self activeSortController] shouldSortForModifiedAttributeKeys:modifiedAttributeKeys])){

            [self sortListGroup:[listContact containingGroup] mode:AISortGroupAndSuperGroups];
            [[owner notificationCenter] postNotificationName:Contact_OrderChanged object:[listContact containingGroup]];
        }

        //Post a 'status' changed message, signaling that the object's status has changed.
        if(inModifiedKeys){
            [[owner notificationCenter] postNotificationName:Contact_StatusChanged object:listContact userInfo:[NSDictionary dictionaryWithObject:inModifiedKeys forKey:@"Keys"]];
        }else{
            [[owner notificationCenter] postNotificationName:Contact_StatusChanged object:listContact];
        }

        //Post an attributes changed message (if necessary)
        if([modifiedAttributeKeys count] != 0){
            [[owner notificationCenter] postNotificationName:Contact_AttributesChanged object:listContact userInfo:[NSDictionary dictionaryWithObject:modifiedAttributeKeys forKey:@"Keys"]];
        }
    }

}

//Call after modifying an object's display attributes
- (void)objectAttributesChanged:(AIListObject *)inObject modifiedKeys:(NSArray *)inModifiedKeys
{
    //Resort the contact list (If necessary)
    if(!holdUpdates && //Skip sorting when updates are delayed
        [[self activeSortController] shouldSortForModifiedAttributeKeys:inModifiedKeys]){

        [self sortListGroup:[inObject containingGroup] mode:AISortGroupAndSuperGroups];
        [[owner notificationCenter] postNotificationName:Contact_OrderChanged object:[inObject containingGroup]];
    }

    //Post an attributes changed message (if necessary)
    if(inModifiedKeys){
        [[owner notificationCenter] postNotificationName:Contact_AttributesChanged object:inObject userInfo:[NSDictionary dictionaryWithObject:inModifiedKeys forKey:@"Keys"]];
    }else{
        [[owner notificationCenter] postNotificationName:Contact_AttributesChanged object:inObject];
    }
}


// Contact Sorting --------------------------------------------------------------------------------
//Register code to sort contacts
- (void)registerListSortController:(id <AIListSortController>)inController
{
    [sortControllerArray addObject:inController];
    [[owner notificationCenter] postNotificationName:Contact_SortSelectorListChanged object:nil userInfo:nil];
}
- (NSArray *)sortControllerArray{
    return(sortControllerArray);
}

//Sets and get the active sort controller
- (void)setActiveSortController:(id <AIListSortController>)inController
{
    activeSortController = inController;

    //Resort the list
    [self sortListGroup:contactList mode:AISortGroupAndSubGroups];
    [[owner notificationCenter] postNotificationName:Contact_OrderChanged object:nil];
}
- (id <AIListSortController>)activeSortController{
    return(activeSortController);
}


//Ordering
- (void)loadContactOrdering
{
    NSEnumerator	*enumerator;
    NSString		*key;
    NSNumber		*position;

    //Load the contact list ordering (Name -> Index)
    listOrderDict = [[[[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST] objectForKey:KEY_CONTACT_LIST_ORDER] mutableCopy];
    if(!listOrderDict) listOrderDict = [[NSMutableDictionary alloc] init];

    //Find the largest contact order index (Helps speed up index adding)
    largestOrder = 0;
    enumerator = [[listOrderDict allValues] objectEnumerator];
    while((position = [enumerator nextObject])){
        int order = [position intValue];
        if(order > largestOrder) largestOrder = order;
    }

    //Build a reverse-lookup dictionary (Index -> Name) (Helps speed up index setting)
    reverseListOrderDict = [[NSMutableDictionary alloc] init];
    enumerator = [[listOrderDict allKeys] objectEnumerator];
    while((key = [enumerator nextObject])){
        NSNumber	*index = [listOrderDict objectForKey:key];

        [reverseListOrderDict setObject:key forKey:index];
    }

}

- (void)saveContactOrdering
{
    NSEnumerator	*enumerator;
    NSMutableArray	*orderIndexArray;
    NSMutableDictionary	*spreadDict;
    NSNumber		*orderIndex;
    int			index;
    
    //We want to spread the index values out so they start at 1 and work up to remove any fractional numbers and gaps.  This greatly lowers any chance that the user will EVER overload a floating point index.  It'll also automatically fix any duplicate errors (if they happen to come up).
    //Sort all the current index values from least to greatest
    orderIndexArray = [[[listOrderDict allValues] mutableCopy] autorelease];;
    [orderIndexArray sortUsingSelector:@selector(compare:)];
    
    //Re-assign a value 1 to n for each key in order.
    index = 1;
    spreadDict = [NSMutableDictionary dictionary];
    enumerator = [orderIndexArray objectEnumerator];
    while((orderIndex = [enumerator nextObject])){
        NSString	*key;
        
        key = [reverseListOrderDict objectForKey:orderIndex]; //Find the key for this index
        NSLog(@"%i: %@",index,key);
        [spreadDict setObject:[NSNumber numberWithInt:index++]  forKey:key]; //Re-assign it to the new index
    }

    //Save the spread order index information
    [[owner preferenceController] setPreference:spreadDict
                                         forKey:KEY_CONTACT_LIST_ORDER
                                          group:PREF_GROUP_CONTACT_LIST];
}

//Get a contact order index ---
- (float)orderIndexOfContact:(AIListContact *)contact
{
    return([self orderIndexOfKey:[contact UIDAndServiceID]]);
}
- (float)orderIndexOfGroup:(AIListGroup *)group
{
    return([self orderIndexOfKey:[group UID]]);
}
- (float)orderIndexOfKey:(NSString *)key
{
    NSNumber	*index = [listOrderDict objectForKey:key];
    
    if(!index){
        //If this contact doesn't have an index, put it at the end of the list (largest order)
        index = [NSNumber numberWithFloat:largestOrder];
        [listOrderDict setObject:index forKey:key];
        [reverseListOrderDict setObject:key forKey:index];
        largestOrder++;
    }

    return([index floatValue]);
}

//Set a contact order index --
//Returns the actual index that was used... if desired would have produced a conflict
- (float)setOrderIndexOfContactWithServiceID:(NSString *)serviceID UID:(NSString *)UID to:(float)index
{
    AIListContact	*contact;

    //Get a unique index
    index = [self _setOrderIndexOfKey:[NSString stringWithFormat:@"%@.%@",serviceID,UID] to:index];
    
    //Set the new index and resort
    contact = [self contactInGroup:nil withService:serviceID UID:UID];
    [contact setOrderIndex:index];
    NSLog(@"index %@ to %0.2f",[contact UID],index);
    [self sortListGroup:[contact containingGroup] mode:AISortGroupAndSuperGroups];
    [[owner notificationCenter] postNotificationName:Contact_OrderChanged object:nil];

    return(index);
}
- (float)setOrderIndexOfGroupWithUID:(NSString *)UID to:(float)index
{
    AIListGroup		*group;

    //Get a unique index
    index = [self _setOrderIndexOfKey:UID to:index];

    //Set the new index and resort
    group = [self groupInGroup:nil withUID:UID];
    [group setOrderIndex:index];
    [self sortListGroup:[group containingGroup] mode:AISortGroupAndSuperGroups];
    [[owner notificationCenter] postNotificationName:Contact_OrderChanged object:nil];

    return(index);
}

//Saves and returns a non-conflicting index for the desired key
- (float)_setOrderIndexOfKey:(NSString *)key to:(float)index
{
    NSString		*conflictingContactKey;

    //Check for a conflict
    conflictingContactKey = [reverseListOrderDict objectForKey:[NSNumber numberWithFloat:index]];
    if(conflictingContactKey){
        NSEnumerator	*enumerator;
        NSNumber	*indexNumber;
        float		closestIndex = ORDER_INDEX_SMALLEST;

        //Find the closest index to this one (less than) (Doesn't matter who's it is, just what it is)
        enumerator = [[listOrderDict allValues] objectEnumerator];
        while((indexNumber = [enumerator nextObject])){
            float indexValue = [indexNumber floatValue];

            if(indexValue < index && (index - indexValue) < (index - closestIndex)){ //If this one is closer to our target index
                closestIndex = indexValue;
            }
        }


        NSLog(@"Set Order to: %0.2f  (%0.2f + %0.2f) / 2.0 = %0.2f",index,index,closestIndex,(index + closestIndex) / 2.0);

        //Set the index to the halfway point
        index = (index + closestIndex) / 2.0;
    }else{
        NSLog(@"Set Order to: %0.2f",index);
    }

    //Save the new index
    [listOrderDict setObject:[NSNumber numberWithFloat:index] forKey:key];
    [reverseListOrderDict setObject:key forKey:[NSNumber numberWithFloat:index]];

    return(index);
}



//Sort a group
- (void)sortListGroup:(AIListGroup *)inGroup mode:(AISortMode)sortMode
{
    if(inGroup == nil) inGroup = contactList; //Passing nil sorts the entire contact list
    
    //Sort the group (and subgroups)
    [inGroup sortGroupAndSubGroups:(sortMode == AISortGroupAndSubGroups)
                    sortController:activeSortController];

    //Sort any groups above it
    if(sortMode == AISortGroupAndSuperGroups){
        AIListGroup	*group = inGroup;

        while((group = [group containingGroup])){
            [group sortGroupAndSubGroups:NO sortController:activeSortController];
        }
    }
}

//Returns the desired destination handle
- (AIHandle *)handleOfContact:(AIListContact *)inContact forReceivingContentType:(NSString *)inType fromAccount:(AIAccount *)inAccount create:(BOOL)create
{
    NSEnumerator	*enumerator;
    AIHandle		*handle = nil;
    
    //Search for an existing handle belonging to the account
    enumerator = [inContact handleEnumerator];
    while((handle = [enumerator nextObject])){
        if([handle account] == inAccount) break;
    }

    //If a handle doesn't exist, create one
    if(!handle && create){
        handle = [(AIAccount<AIAccount_Handles> *)inAccount addHandleWithUID:[inContact UID] serverGroup:nil temporary:YES];
    }
    
    return(handle);
}




// Contact Access --------------------------------------------------------------------------------
//Returns the main contact list group
- (AIListGroup *)contactList;
{
    return(contactList);
}

//Returns a flat array of all the contacts in a group (and all subgroups if desired).
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

//Call before making large changes to the contact list, or changes to a large number of contacts
- (void)setHoldContactListUpdates:(BOOL)inHoldUpdates
{
    holdUpdates = inHoldUpdates;

    if(inHoldUpdates == NO){
        //Resort and redisplay the entire list at once (since sorting has been skipped while delayed)
        [self sortListGroup:contactList mode:AISortGroupAndSubGroups];
        [[owner notificationCenter] postNotificationName:Contact_OrderChanged object:nil];
    }
}

//Returns YES if the contact list updates are currently on hold
- (BOOL)holdContactListUpdates
{
    return(holdUpdates);
}

//Returns the handle with the specified Service and UID in the group (or any subgroups)
- (AIListContact *)contactInGroup:(AIListGroup *)inGroup withService:(NSString *)serviceID UID:(NSString *)UID
{
    return([self contactInGroup:inGroup withService:serviceID UID:UID serverGroup:nil]);
}

//Returns the handle with the specified Service and UID in the group (or any subgroups)
- (AIListContact *)contactInGroup:(AIListGroup *)inGroup withService:(NSString *)serviceID UID:(NSString *)UID serverGroup:(NSString *)serverGroup
{
    NSEnumerator	*enumerator;
    AIListObject 	*object;
    AIListContact	*subGroupObject;
    
    if(!inGroup) inGroup = contactList;
    
    enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIListGroup class]]){
            if((subGroupObject = [self contactInGroup:(AIListGroup *)object withService:serviceID UID:UID serverGroup:serverGroup])){
                return(subGroupObject); //Match in a subgroup
            }
        }else if([object isKindOfClass:[AIListContact class]]){
            if([UID compare:[object UID]] == 0){
                if(!serverGroup || [serverGroup compare:[inGroup UID]] == 0){ //ensure the groups match
                    if(!serviceID || [serviceID compare:[(AIListContact *)object serviceID]] == 0){ //ensure the services match
                        return((AIListContact *)object); //Match
                    }
                }
            }
        }
    }

    return(nil);
}

//Returns the group with the specified UID in the group (or any subgroups)
- (AIListGroup *)groupInGroup:(AIListGroup *)inGroup withUID:(NSString *)UID
{
    NSEnumerator	*enumerator;
    AIListGroup 	*object;

    if(!inGroup) inGroup = contactList;

    enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIListGroup class]]){
            if([UID compare:[object UID]] == 0){
                return(object); //Match
            }
            if((object = [self groupInGroup:object withUID:UID])){
                return(object); //Match in a subgroup
            }
        }
    }

    return(nil);
}

@end

