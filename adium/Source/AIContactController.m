/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#define CONTACT_LIST_GROUP_NAME		@"Contact List"		//The name of the main contact list group
#define STRANGER_GROUP_NAME		@"__Strangers"		//The name of the hidden stranger group
#define KEY_CONTACT_LIST 		@"ContactList"		//Contact list key
#define PREF_GROUP_CONTACT_LIST		@"Contact List"		//Contact list preference group
#define GET_INFO_MENU_TITLE		@"Get Info"

@interface AIContactController (PRIVATE)
- (void)_handle:(AIHandle *)inHandle addedToAccount:(AIAccount *)inAccount;
- (void)_handle:(AIHandle *)inHandle removedFromAccount:(AIAccount *)inAccount;
- (void)_handlesChangedForAccount:(AIAccount *)inAccount;
- (void)processHandle:(AIHandle *)handle;
- (void)breakDownContactList;
- (void)breakDownGroup:(AIListGroup *)inGroup;
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
    contactList = nil;
    groupDict = [[NSMutableDictionary alloc] init];
    abandonedContacts = [[NSMutableDictionary alloc] init];
    abandonedGroups = [[NSMutableDictionary alloc] init];

    [owner registerEventNotification:Contact_StatusChanged displayName:@"Contact Status Changed"];
    
    //
    contactInfoCategory = [[AIPreferenceCategory categoryWithName:@"" image:nil] retain];
}

//close
- (void)closeController
{
    //[self saveContactList]; //Save the contact list
    //The contact list is saved as changes are made, but some changes (such as the expanding and collapsing of groups) are not saved, so we save on closing just to make sure nothing is lost.
}

//dealloc
- (void)dealloc
{
    [contactList release];
    [contactObserverArray release]; contactObserverArray = nil;
    [contactInfoCategory release];

    [super dealloc];
}

- (void)finishIniting
{
    //Load the contact list
    contactList = [[AIListGroup alloc] initWithUID:CONTACT_LIST_GROUP_NAME];
//    [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
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
    [[owner contactController] setHoldContactListUpdates:YES]; //Hold contact list updates

    //Post a handles changed notification
    [[owner notificationCenter] postNotificationName:Account_HandlesChanged object:inAccount];
    
    //Rebuild the list
    [self breakDownContactList]; //Move existing contacts into the abandoned contact dict
    [self _handlesChangedForAccount:inAccount]; //Build the new contact list

    [[owner contactController] setHoldContactListUpdates:NO]; //Stop holding updates
}

- (void)handle:(AIHandle *)inHandle addedToAccount:(AIAccount *)inAccount
{
    [self _handle:inHandle addedToAccount:inAccount];
}

- (void)handle:(AIHandle *)inHandle removedFromAccount:(AIAccount *)inAccount
{
    [self _handle:inHandle removedFromAccount:inAccount];
}

//For the list generation code to call, resets the contact list - moving
- (void)breakDownContactList
{
    //Move everything on the contact list into the abandoned dicts
    [self breakDownGroup:contactList];

    //Create new contact list
    [contactList release];
    contactList = [[AIListGroup alloc] initWithUID:CONTACT_LIST_GROUP_NAME];

    //Post a list changed message so everyone has the new (currently empty) list
    [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
}

- (void)breakDownGroup:(AIListGroup *)inGroup
{
    NSEnumerator	*enumerator;
    AIListObject	*object;

    enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIListContact class]]){
            //Remove handles from the contact
            [(AIListContact *)object removeAllHandles];
            
            //Add the contact to our abandoned dict
            if(![abandonedContacts objectForKey:[object UID]]){
                //Multiple contacts with the same UID could exist.  The behavior here in that case is not the best.  For now we're just dropping and recreating the duplicate contact.  In the future, duplicates will most likely be disallowed.
                [abandonedContacts setObject:object forKey:[object UID]];
            }

        }else if([object isKindOfClass:[AIListGroup class]]){
            //Breakdown the subgroup
            [self breakDownGroup:(AIListGroup *)object];
        }

        //Since we will remove these objects from their group, we can take care
        [object setContainingGroup:nil];
    }

    if(inGroup != contactList){ //We don't want to break down the root contact list group
        //Empty the group and hold onto it as well
        [inGroup removeAllObjects];
        [abandonedGroups setObject:inGroup forKey:[inGroup UID]];
    }
}



// ------------------------------------------
// Contact list generation module code...
// This code should be moved into a seperate module similar to sorting
// ----------------------
- (void)_handle:(AIHandle *)inHandle addedToAccount:(AIAccount *)inAccount
{
    [self processHandle:inHandle];
    [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
}

- (void)_handle:(AIHandle *)inHandle removedFromAccount:(AIAccount *)inAccount
{
    NSArray	*statusKeyArray = [[inHandle statusDictionary] allKeys];

    //Remove ALL status flags from the handle, and then call an update status.
    [[inHandle statusDictionary] removeAllObjects];
    [self handleStatusChanged:inHandle modifiedStatusKeys:statusKeyArray];

    //After all the observers have responded to the status change, we can remove the handle
    [[inHandle containingContact] removeHandle:inHandle];

    //We really don't have to update the list... just leave the contact there.. no harm in it
    [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
}

- (void)_handlesChangedForAccount:(AIAccount *)inAccount
{
    NSEnumerator		*accountEnumerator;
    AIAccount			*account;

    [groupDict release];
    groupDict = [[NSMutableDictionary alloc] init];
        
    //Go through each account, grabbing its handles
    accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [accountEnumerator nextObject])){
        if([account conformsToProtocol:@protocol(AIAccount_Handles)]){
            NSEnumerator	*handleEnumerator = [[[(AIAccount<AIAccount_Handles> *)account availableHandles] allValues] objectEnumerator];
            AIHandle		*handle;

            while((handle = [handleEnumerator nextObject])){
                [self processHandle:handle];
            }
        }
    }

    //post a list changed
    [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
}

- (void)processHandle:(AIHandle *)handle
{
    NSString		*handleUID = [handle UID];
    NSString		*serverGroup = [handle serverGroup];
    AIServiceType	*serviceType = [[[handle account] service] handleServiceType];
    AIListContact	*contact;
    AIListGroup		*group;
    
    //We first check if a contact for this handle alredy exists on our new contact list.
    //If it does, we'll simply add this handle to the existing contact.
    contact = [self contactInGroup:contactList withService:serviceType UID:handleUID serverGroup:nil/*serverGroup*/];
    if(!contact){
        //If the contact does not exist
        //Check for it in the abandoned contact dict
        contact = [abandonedContacts objectForKey:handleUID];
        if(contact){
            [[contact retain] autorelease]; //We need to temporarily hold onto the contact, since removing it from the abandoned contacts array will cause it to be released immediately.
            [abandonedContacts removeObjectForKey:handleUID]; //remove it from abandoned
        } 

        //If it wasn't in the abandoned dict, we create
        if(!contact){
            contact = [[AIListContact alloc] initWithUID:handleUID serviceID:[serviceType identifier]];
        }

        //Make sure a group exists
        group = [groupDict objectForKey:serverGroup];
        //If no group exists in either location, we create a new one
        if(!group){
            //If the group does not exist, check for it in the abandoned group dict
            group = [abandonedGroups objectForKey:serverGroup];
            if(group){
                [[group retain] autorelease]; //We need to temporarily hold onto the group, since removing it from the abandoned groups array will cause it to be released immediately.
                [abandonedGroups removeObjectForKey:serverGroup]; //remove it from abandoned
            }

            //If it wasn't in the abandoned dict, we create
            if(!group){
                group = [[[AIListGroup alloc] initWithUID:serverGroup] autorelease];	//Create the group
                [group setExpanded:YES/*[[dict objectForKey:serverGroup boolValue]]*/]; //Correctly expand/collapse the group
            }

            [contactList addObject:group];				//Add the group to our contact list
            [groupDict setObject:group forKey:serverGroup];		//Add it to our group tracking dict
        }

        //Add the contact to the group
        [group addObject:contact];
    }

    //Add the handle to the contact
    [contact addHandle:handle];

    //Call status changed so observers can update the contact's display
    [self handleStatusChanged:handle modifiedStatusKeys:nil];
}
// ------------------------------------------





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
- (AIListContact *)contactInGroup:(AIListGroup *)inGroup withService:(AIServiceType *)service UID:(NSString *)UID
{
    return([self contactInGroup:inGroup withService:service UID:UID serverGroup:nil]);
}

//Returns the handle with the specified Service and UID in the group (or any subgroups)
- (AIListContact *)contactInGroup:(AIListGroup *)inGroup withService:(AIServiceType *)service UID:(NSString *)UID serverGroup:(NSString *)serverGroup
{
    NSEnumerator	*enumerator;
    AIListObject 	*object;
    AIListContact	*subGroupObject;
    
    if(!inGroup) inGroup = contactList;
    
    enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIListGroup class]]){
            if((subGroupObject = [self contactInGroup:(AIListGroup *)object withService:service UID:UID serverGroup:serverGroup])){
                return(subGroupObject); //Match in a subgroup
            }
        }else if([object isKindOfClass:[AIListContact class]]){
            if([service compareUID:UID to:[object UID]] == 0){
                if(!serverGroup || [serverGroup compare:[inGroup UID]] == 0){ //ensure the groups match
                    if([[service identifier] compare:[(AIListContact *)object serviceID]] == 0){ //ensure the services match
                        return((AIListContact *)object); //Match
                    }
                }
            }
        }
    }

    return(nil);
}


// List Searching --------------------------------------------------------------------------------
/* Finds a handle on the contact list with the specified service and UID
- If the handle does not exist, it will be created as a stranger (temporary handle)
- Account is only used when a stranger is created, but must be valid
    */
/*- (AIContactHandle *)handleWithService:(AIServiceType *)inService UID:(NSString *)inUID forAccount:(AIAccount *)inAccount
{
    AIContactHandle	*handle = [self handleInGroup:contactList withService:inService UID:inUID];

    //If the handle doesn't exist
    if(!handle){
        //Create stranger
        NSLog(@"Creating stranger '%@'",inUID);
        handle = [self createHandleWithService:inService UID:inUID inGroup:strangerGroup forAccount:inAccount];
    }

    return(handle);
}*/

/*- (AIContactHandle *)handleInGroup:(AIContactGroup *)inGroup withService:(AIServiceType *)service UID:(NSString *)UID
{
    AIContactObject 	*object;
    AIContactHandle	*subGroupObject;
    int 		index = 0;

    while(index < [inGroup count]){
        object = [inGroup objectAtIndex:index];

        if([object isKindOfClass:[AIContactGroup class]]){
            if((subGroupObject = [self handleInGroup:(AIContactGroup *)object withService:service UID:UID])){
                return(subGroupObject); //Match in a subgroup
            }
        }else{
            if([service compareUID:UID to:[object UID]] == 0){
                if([[service identifier] compare:[object serviceID]] == 0){ //double check to ensure the services match
                    return((AIContactHandle *)object); //Match
                }
            }
        }

        index++;
    }

    return(nil);
}*/

@end

