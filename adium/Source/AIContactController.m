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
#import "AIOutOfSyncWindowController.h"

#define CONTACT_LIST_GROUP_NAME		@"Contact List"		//The name of the main contact list group
#define STRANGER_GROUP_NAME		@"__Strangers"		//The name of the hidden stranger group
#define KEY_CONTACT_LIST 		@"ContactList"		//Contact list key
#define PREF_GROUP_CONTACT_LIST		@"Contact List"		//Contact list preference group

@interface AIContactController (PRIVATE)
- (AIContactHandle *)handleInGroup:(AIContactGroup *)inGroup withService:(AIServiceType *)service UID:(NSString *)UID;
- (void)updateListForObject:(AIContactObject *)inObject saveChanges:(BOOL)saveChanges;
- (AIContactGroup *)groupInGroup:(AIContactGroup *)inGroup withName:(NSString *)inName;
- (void)delayedUpdateTimer:(NSTimer *)inTimer;
- (void)saveContactList;
- (AIContactGroup *)loadContactList;
- (AIContactGroup *)createGroupFromDict:(NSDictionary *)groupDict;
- (NSDictionary *)saveDictForGroup:(AIContactGroup *)inGroup;
@end

@implementation AIContactController

//init
- (void)initController
{
    //
    handleObserverArray = [[NSMutableArray alloc] init];
    sortControllerArray = [[NSMutableArray alloc] init];
    activeSortController = nil;
    delayedUpdating = 0;
    contactList = nil;

    [owner registerEventNotification:Contact_StatusChanged displayName:@"Contact Status Changed"];

    //
    contactInfoCategory = [[AIPreferenceCategory categoryWithName:@"" image:nil] retain];
}

//close
- (void)closeController
{
    [self saveContactList]; //Save the contact list
    //The contact list is saved as changes are made, but some changes (such as the expanding and collapsing of groups) are not saved, so we save on closing just to make sure nothing is lost.
}

//dealloc
- (void)dealloc
{
    [contactList release];
    [handleObserverArray release]; handleObserverArray = nil;
    [contactInfoCategory release];

    [super dealloc];
}

- (void)finishIniting
{
    //Load the contact list
    contactList = [[self loadContactList] retain];
    [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];

    //Create a dynamic strangers group
    strangerGroup = [self createGroupNamed:STRANGER_GROUP_NAME inGroup:contactList];
    [[strangerGroup displayArrayForKey:@"Dynamic"] addObject:[NSNumber numberWithBool:YES] withOwner:self];
    [self updateListForObject:strangerGroup saveChanges:NO];
}

// Contact Info --------------------------------------------------------------------------------
//Show the info window for a contact
- (void)showInfoForContact:(AIContactHandle *)inContact
{
    [[AIContactInfoWindowController contactInfoWindowControllerWithCategory:contactInfoCategory forContact:inContact] showWindow:nil];
}

//Add a contact info view
- (void)addContactInfoView:(AIPreferenceViewController *)inView
{
    [contactInfoCategory addView:inView];
}


// Accounts --------------------------------------------------------------------------------
//Add an account to an existing object
- (void)addAccount:(AIAccount *)inAccount toObject:(AIContactObject *)inObject
{
    if([inAccount conformsToProtocol:@protocol(AIAccount_GroupedContacts)]){ //Account supports groups
        //Add the account to the object
        [inObject registerOwner:inAccount];
        [(AIAccount<AIAccount_GroupedContacts> *)inAccount addObject:inObject toGroup:[inObject containingGroup]];

    }else if([inAccount conformsToProtocol:@protocol(AIAccount_Contacts)]){ //..doesn't support groups
        //Add the account to the handle
        if([inObject isKindOfClass:[AIContactHandle class]]){ //Handle
            [inObject registerOwner:inAccount];
            [(AIAccount<AIAccount_Contacts> *)inAccount addObject:inObject];
        }
    }

    //Re-order and update the list
    [self updateListForObject:inObject saveChanges:NO];
}

//Remove an account from an existing handle/cluster
- (void)removeAccount:(AIAccount *)inAccount fromObject:(AIContactObject *)inObject
{
    if([inAccount conformsToProtocol:@protocol(AIAccount_GroupedContacts)]){ //Account supports groups
        //Remove the object from the account
        [inObject unregisterOwner:inAccount];
        [(AIAccount<AIAccount_GroupedContacts> *)inAccount removeObject:inObject fromGroup:[inObject containingGroup]];

    }else if([inAccount conformsToProtocol:@protocol(AIAccount_Contacts)]){ //..doesn't support groups
        //Remove the handle
        if([inObject isKindOfClass:[AIContactHandle class]]){ //Handle
            [inObject unregisterOwner:inAccount];
            [(AIAccount<AIAccount_Contacts> *)inAccount removeObject:inObject];
        }
    }

    //Re-order and update the list
    [self updateListForObject:inObject saveChanges:NO];
}

// Groups --------------------------------------------------------------------------------
//Create a new group
- (AIContactGroup *)createGroupNamed:(NSString *)inName inGroup:(AIContactGroup *)inGroup
{
    AIContactGroup	*newGroup;

    if(!inGroup) inGroup = [self contactList]; //If no group is specified, we create at the root level
    
    //create the new group
    newGroup = [AIContactGroup contactGroupWithUID:inName];
    [inGroup addObject:newGroup];
    
    //Re-order and update the list
    [self updateListForObject:newGroup saveChanges:YES]; //update the list
    
    return(newGroup);
}

//Delete an object
- (void)deleteObject:(AIContactObject *)object
{
    AIContactGroup	*containingGroup = [object containingGroup];
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    //If this is a group, delete everything within it first
    if([object isMemberOfClass:[AIContactGroup class]]){
        while([(AIContactGroup *)object count] != 0){
            [self deleteObject:[(AIContactGroup *)object objectAtIndex:0]];
        }
    }

    //Remove the object from all owning accounts
    enumerator = [[object ownerArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        if([account conformsToProtocol:@protocol(AIAccount_GroupedContacts)]){
            [(AIAccount<AIAccount_GroupedContacts> *)account removeObject:object fromGroup:[object containingGroup]];
        }else if([account conformsToProtocol:@protocol(AIAccount_Contacts)]){
            [(AIAccount<AIAccount_Contacts> *)account removeObject:object];
        }
    }

    //Delete the object locally, and update the contact list
    [containingGroup removeObject:object];
    [self updateListForObject:containingGroup saveChanges:YES];
}

//rename an object
- (void)renameObject:(AIContactObject *)object to:(NSString *)newName
{
    AIContactGroup	*containingGroup = [object containingGroup];
    NSEnumerator	*enumerator;
    AIAccount		*account;

    //Filter the UID (force lowercase, and/or remove invalid characters)
    //We let each owner account's service have a chance at filtering
    if([object isMemberOfClass:[AIContactHandle class]]){ //we'll eventually need to filter group names too though
        enumerator = [[object ownerArray] objectEnumerator];
        while((account = [enumerator nextObject])){
            newName = [[[account service] handleServiceType] filterUID:newName];
        }
    }

    //Rename the object on all owning accounts
    enumerator = [[object ownerArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        if([account conformsToProtocol:@protocol(AIAccount_GroupedContacts)]){
            [(AIAccount<AIAccount_GroupedContacts> *)account renameObject:object inGroup:containingGroup to:newName];
        }else if([account conformsToProtocol:@protocol(AIAccount_Contacts)]){
            [(AIAccount<AIAccount_Contacts> *)account renameObject:object to:newName];
        }
    }

    //Delete the object locally, and update the contact list
    [object setUID:newName];
    [self updateListForObject:object saveChanges:YES];
}

//Move an object
- (void)moveObject:(AIContactObject *)object toGroup:(AIContactGroup *)destGroup index:(int)inIndex
{
    AIContactGroup	*containingGroup = [object containingGroup];
    NSEnumerator	*enumerator;
    AIAccount		*account;

    //If no group is specified, we move to the root level
    if(!destGroup) destGroup = [self contactList];

    //Make sure the destination index is valid
    if(inIndex <= 0){
        inIndex = 0;
    }else if(inIndex > [destGroup count]){
        inIndex = [destGroup count]-1;
    }

    //If an object is moving to another location within the same group that is below its current location, we need to offset the destination index for it to fall in the correct place, since the index of every object in the group will shift up one when the targeted object is removed.
    if((containingGroup == destGroup) && (inIndex > [containingGroup indexOfObject:object])){
        inIndex -= 1;
    }

    //Move the object on all owning accounts
    enumerator = [[object ownerArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        if([account conformsToProtocol:@protocol(AIAccount_GroupedContacts)]){
            [(AIAccount<AIAccount_GroupedContacts> *)account moveObject:object fromGroup:containingGroup toGroup:destGroup];
        }
    }

    //Move the object
    [object retain];			//Hold onto the object so it doesn't accidentally get released
    [containingGroup removeObject:object];
    [destGroup insertObject:object atIndex:inIndex];
    [object release];

    //Re-order and update the list
    [self updateListForObject:containingGroup saveChanges:YES]; //Update the old group
    [self updateListForObject:object saveChanges:YES]; //Update the new group
}
    
 
// List Searching --------------------------------------------------------------------------------
//Finds a group with the specified name
- (AIContactGroup *)groupWithName:(NSString *)inName
{
    if([[contactList UID] compare:inName] == 0){
        return(contactList); //The root group can be called by name
    }else{
        return([self groupInGroup:contactList withName:inName]);
    }
}

/* Finds a handle on the contact list with the specified service and UID
    - If the handle does not exist, it will be created as a stranger (temporary handle)
    - Account is only used when a stranger is created, but must be valid
*/
- (AIContactHandle *)handleWithService:(AIServiceType *)inService UID:(NSString *)inUID forAccount:(AIAccount *)inAccount 
{
    AIContactHandle	*handle = [self handleInGroup:contactList withService:inService UID:inUID];

    //If the handle doesn't exist
    if(!handle){
        //Create stranger
        NSLog(@"Creating stranger '%@'",inUID);
        handle = [self createHandleWithService:inService UID:inUID inGroup:strangerGroup forAccount:inAccount];
    }

    return(handle);
}

/* Creates a handle on the contact list with the specified service and UID
    - If the handle does not exist, it will be added to the contact list in the specified group
    - If the handle exists in the passed group, it will be returned
    - If the handle exists in another group, an 'out of sync' condition will be flagged
    - If the handle exists in the strangers group, it will be permanently moved to the passed group

    - GROUP can be 'nil' (if the handle's location is not important)
*/
- (AIContactHandle *)createHandleWithService:(AIServiceType *)inService UID:(NSString *)inUID inGroup:(AIContactGroup *)inGroup forAccount:(AIAccount *)inAccount 
{
    AIContactHandle	*handle = [self handleInGroup:contactList withService:inService UID:inUID];

    //If the handle doesn't exist
    if(!handle){
        if(!inGroup) inGroup = [self contactList]; //If no group is specified, we create at the root level
	
        //Filter the UID (force lowercase, and/or remove invalid characters)
        inUID = [inService filterUID:inUID];
        
        //Create the handle
        handle = [AIContactHandle handleWithServiceID:[inService identifier] UID:inUID];
        [inGroup addObject:handle];

    }else{
	//If the handle is in the strangers group
        if([handle containingGroup] == strangerGroup){
            //Move it out
            NSLog(@"%@ is an existing stranger, and should be added to the contact list here", inUID);


        //If a group was specified, and the handle IS NOT in it.
        }else if(inGroup && [handle containingGroup] != inGroup){
            //Out of sync
            [AIOutOfSyncWindowController outOfSyncConditionForAccount:inAccount handle:handle serverGroup:inGroup];
        }
    }
    
    //Register the account as an owner, and update the list
    if(inAccount && ![handle belongsToAccount:inAccount]){
        [handle registerOwner:inAccount];
    }
    [self updateListForObject:handle saveChanges:YES];
    [self handleStatusChanged:handle modifiedStatusKeys:nil]; //let all observers touch this new handle
    
    //Return the handle
    return(handle);
}


// Handle status --------------------------------------------------------------------------------
//Registers code to observe handle status changes
- (void)registerHandleObserver:(id <AIHandleObserver>)inObserver
{
    NSEnumerator	*enumerator;
    AIContactHandle	*contact;
    
    [handleObserverArray addObject:inObserver];

    //Let the handle observer process all existing contacts
    enumerator = [[self allContactsInGroup:nil subgroups:YES ownedBy:nil] objectEnumerator];
    while((contact = [enumerator nextObject])){
        if([inObserver updateHandle:contact keys:nil]){
            [self updateListForObject:contact saveChanges:NO];
        }
    }

}

//Called after modifying a handle's status
- (void)handleStatusChanged:(AIContactHandle *)inHandle modifiedStatusKeys:(NSArray *)inModifiedKeys
{
    NSMutableArray	*modifiedAttributeKeys = [NSMutableArray array];
    int loop;

    //Let all the observers know it changed
    for(loop = 0;loop < [handleObserverArray count];loop++){
        NSArray	*newKeys;
        if((newKeys = [[handleObserverArray objectAtIndex:loop] updateHandle:inHandle keys:inModifiedKeys])){
            [modifiedAttributeKeys addObjectsFromArray:newKeys];
        }
    }

    //Resort the contact list (If necessary)
    if(!delayedUpdating && //Skip sorting when updates are delayed
       ([[self activeSortController] shouldSortForModifiedStatusKeys:inModifiedKeys] ||
       [[self activeSortController] shouldSortForModifiedAttributeKeys:modifiedAttributeKeys])){

        [self sortContactGroup:[inHandle containingGroup] mode:AISortGroupAndSuperGroups];
        [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
    }

    //Post a 'status' changed message, signaling that the object's status has changed.
    if(inModifiedKeys){
        [[owner notificationCenter] postNotificationName:Contact_StatusChanged object:inHandle userInfo:[NSDictionary dictionaryWithObject:inModifiedKeys forKey:@"Keys"]];
    }else{
        [[owner notificationCenter] postNotificationName:Contact_StatusChanged object:inHandle];
    }

    //Post an attributes changed message (if necessary)
    if([modifiedAttributeKeys count] != 0){
        [[owner notificationCenter] postNotificationName:Contact_AttributesChanged object:inHandle userInfo:[NSDictionary dictionaryWithObject:modifiedAttributeKeys forKey:@"Keys"]];
    }
}

//Call after modifying an object's display attributes
- (void)objectAttributesChanged:(AIContactObject *)inObject modifiedKeys:(NSArray *)inModifiedKeys
{
    //Resort the contact list (If necessary)
    if(!delayedUpdating && //Skip sorting when updates are delayed
        [[self activeSortController] shouldSortForModifiedAttributeKeys:inModifiedKeys]){

        [self sortContactGroup:[inObject containingGroup] mode:AISortGroupAndSuperGroups];
    }

    //Post an attributes changed message (if necessary)
    if(inModifiedKeys){
        [[owner notificationCenter] postNotificationName:Contact_ObjectChanged object:inObject userInfo:[NSDictionary dictionaryWithObject:inModifiedKeys forKey:@"Keys"]];
    }else{
        [[owner notificationCenter] postNotificationName:Contact_ObjectChanged object:inObject];
    }
}


// Contact Sorting --------------------------------------------------------------------------------
//Register code to sort contacts
- (void)registerContactSortController:(id <AIContactSortController>)inController
{
    [sortControllerArray addObject:inController];
    [[owner notificationCenter] postNotificationName:Contact_SortSelectorListChanged object:nil userInfo:nil];
}
- (NSArray *)sortControllerArray{
    return(sortControllerArray);
}

//Sets and get the active sort controller
- (void)setActiveSortController:(id <AIContactSortController>)inController
{
    activeSortController = inController;

    //Resort the list
    [self sortContactGroup:contactList mode:AISortGroupAndSubGroups];
    [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
}
- (id <AIContactSortController>)activeSortController{
    return(activeSortController);
}


//Sort a group
- (void)sortContactGroup:(AIContactGroup *)inGroup mode:(AISortMode)sortMode
{
    //Sort the group (and subgroups)
    [inGroup sortGroupAndSubGroups:(sortMode == AISortGroupAndSubGroups)
                    sortController:activeSortController];

    //Sort any groups above it
    if(sortMode == AISortGroupAndSuperGroups){
        AIContactGroup	*group = inGroup;

        while((group = [group containingGroup])){
            [group sortGroupAndSubGroups:NO sortController:activeSortController];
        }
    }
}


// Contact Access --------------------------------------------------------------------------------
//Returns the main contact list group
- (AIContactGroup *)contactList
{
    return(contactList);
}

//Returns a flat array of all the contacts in a group (and all subgroups if desired).
- (NSMutableArray *)allContactsInGroup:(AIContactGroup *)inGroup subgroups:(BOOL)subGroups ownedBy:(AIAccount *)inAccount
{
    NSMutableArray	*contactArray = [[NSMutableArray alloc] init];
    AIContactObject	*object;
    int			index = 0;
    
    if(inGroup == nil){
        inGroup = contactList;
    }

    while(index < [inGroup count]){
        object = [inGroup objectAtIndex:index];

        if([object isKindOfClass:[AIContactGroup class]]){
            if(subGroups){
                [contactArray addObjectsFromArray:[self allContactsInGroup:(AIContactGroup *)object subgroups:subGroups ownedBy:inAccount]];
            }
        }else{
            if(inAccount == nil || [object belongsToAccount:inAccount]){
                [contactArray addObject:object];
            }
        }
    
        index++;
    }

    return([contactArray autorelease]);
}

//Delays updating the contact list for the specified # of seconds.  Things are still updated, just not as frequently.  Call this before making massive changes to the contact list.
- (void)delayContactListUpdatesFor:(int)seconds
{
    if(delayedUpdating){ //If we're already delayed, increase the delay length
        if(seconds > delayedUpdating){
            delayedUpdating = seconds;    
        }

    }else{ //Otherwise, initiate a delay
        //Flag delayed
        delayedUpdating = seconds;    
        
        //Install an update timer to resort/update the list every second
        [NSTimer scheduledTimerWithTimeInterval:(1.0/1.0) target:self selector:@selector(delayedUpdateTimer:) userInfo:nil repeats:YES];
    }
}

//Returns YES if the contact list updates are currently delayed
- (BOOL)contactListUpdatesDelayed
{
    return(delayedUpdating != 0);
}

// Internal --------------------------------------------------------------------------------
//Call after making changes to an object on the contact list
- (void)updateListForObject:(AIContactObject *)inObject saveChanges:(BOOL)saveChanges
{
    //Resort its group, and any groups above it
    if(!delayedUpdating){ //Skip sorting when updates are delayed
        if([inObject isKindOfClass:[AIContactGroup class]]){ //If a group is passed, sort it
            [self sortContactGroup:(AIContactGroup *)inObject mode:AISortGroup];
        }
        
        [self sortContactGroup:[inObject containingGroup] mode:AISortGroupAndSuperGroups];
    }

    //Post an 'object' changed message, signaling that the object's status has changed.
    [[owner notificationCenter] postNotificationName:Contact_ObjectChanged object:inObject];

    //Save the changes 
    if(saveChanges && !delayedUpdating){ //Skip saving when updates are delayed
        [self saveContactList];
    }
}

//Returns the handle with the specified Service and UID in the group (or any subgroups)
- (AIContactHandle *)handleInGroup:(AIContactGroup *)inGroup withService:(AIServiceType *)service UID:(NSString *)UID
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
            if([service compareUID:UID toHandle:(AIContactHandle *)object] == 0){
                return((AIContactHandle *)object); //Match
            }
        }
    
        index++;
    }

    return(nil);
}

- (AIContactGroup *)groupInGroup:(AIContactGroup *)inGroup withName:(NSString *)inName
{
    AIContactObject 	*object;
    AIContactGroup	*subGroupObject;
    int 		index = 0;

    while(index < [inGroup count]){
        object = [inGroup objectAtIndex:index];

        if([object isKindOfClass:[AIContactGroup class]]){
        
            if([[object UID] compare:inName] == 0){
                return((AIContactGroup *)object);
            }else{
                if((subGroupObject = [self groupInGroup:(AIContactGroup *)object withName:inName])){
                    return(subGroupObject); //Match in a subgroup
                }
            }
        }

        index++;
    }

    return(nil);
}

- (void)delayedUpdateTimer:(NSTimer *)inTimer
{
    //Resort and redisplay the entire list at once (since sorting has been skipped while delayed)
    [self sortContactGroup:contactList mode:AISortGroupAndSubGroups];
    [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];

    //decrease the counter
    delayedUpdating--;
    if(delayedUpdating == 0){
        [inTimer invalidate]; //end the delay
        [self saveContactList]; //Save the contact list (since saving has been skipped while delayed)
    }
}

//Save the contact list to disk
- (void)saveContactList
{
    NSDictionary	*saveDict = [self saveDictForGroup:contactList];

    [[owner preferenceController] setPreference:saveDict forKey:KEY_CONTACT_LIST group:PREF_GROUP_CONTACT_LIST];
}

//Load the contact list from disk
- (AIContactGroup *)loadContactList
{
    NSDictionary	*saveDict;
    AIContactGroup	*contactListGroup;

    //Load & build the list
    saveDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST] objectForKey:KEY_CONTACT_LIST];    
    if(!saveDict){
        contactListGroup = [AIContactGroup contactGroupWithUID:CONTACT_LIST_GROUP_NAME];
    }else{
        contactListGroup = [self createGroupFromDict:saveDict];
    }

    //Sort the list
    [self sortContactGroup:contactListGroup mode:AISortGroupAndSubGroups];

    return(contactListGroup);
}

//Create a group from the passed dictionary
- (AIContactGroup *)createGroupFromDict:(NSDictionary *)groupDict
{
    AIContactGroup	*group;
    NSNumber		*expanded;
    NSString		*groupName;
    NSEnumerator	*enumerator;
    NSArray		*contentsArray;
    NSDictionary	*objectDict;

    //Create and config the group
    groupName = [groupDict objectForKey:@"Name"];
    expanded = [groupDict objectForKey:@"Expanded"];
    group = [AIContactGroup contactGroupWithUID:groupName];
    [group setExpanded:(expanded == nil || [expanded boolValue] == YES)];
    

    //Create it's contents
    contentsArray = [groupDict objectForKey:@"Contents"];
    enumerator = [contentsArray objectEnumerator];
    while((objectDict = [enumerator nextObject])){
        NSString *type = [objectDict objectForKey:@"Type"];

        if([type compare:@"Contact"] == 0){
            AIContactHandle	*handle;
            NSString 		*UID = [objectDict objectForKey:@"UID"];
            NSString 		*service = [objectDict objectForKey:@"Service"];

            //Create and add the handle
            handle = [AIContactHandle handleWithServiceID:service UID:UID];
            [group addObject:handle];
            
            [self handleStatusChanged:handle modifiedStatusKeys:nil]; //let all observers touch this new handle
            
        }else if([type compare:@"Group"] == 0){
            [group addObject:[self createGroupFromDict:objectDict]];

        }
        
    }

    return(group);
}

//Create a dictionary from the passed group
- (NSDictionary *)saveDictForGroup:(AIContactGroup *)inGroup
{
    NSMutableDictionary	*saveDict = [[NSMutableDictionary alloc] init];
    NSMutableArray	*objectArray = [[NSMutableArray alloc] init];
    NSEnumerator	*enumerator;
    AIContactObject	*object;

    //Add the group keys
    [saveDict setObject:@"Group" forKey:@"Type"];
    [saveDict setObject:[inGroup UID] forKey:@"Name"];
    [saveDict setObject:[NSNumber numberWithBool:[inGroup isExpanded]] forKey:@"Expanded"];

    //Add all contained objects
    enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if(![[object displayArrayForKey:@"Dynamic"] containsAnyIntegerValueOf:1]){ //Don't save dynamic objects
            if([object isKindOfClass:[AIContactHandle class]]){ //Handle
                NSMutableDictionary	*objectDict = [[NSMutableDictionary alloc] init];
    
                [objectDict setObject:@"Contact" forKey:@"Type"];
                [objectDict setObject:[object UID] forKey:@"UID"];
                [objectDict setObject:[(AIContactHandle *)object serviceID] forKey:@"Service"];
    
                [objectArray addObject:[objectDict autorelease]];
    
            }else{ //Group
                [objectArray addObject:[self saveDictForGroup:(AIContactGroup *)object]]; //Add the group and it's contents
    
            }
        }
    }
    [saveDict setObject:objectArray forKey:@"Contents"];

    return([saveDict autorelease]);
}


@end

