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
#import "AIContactInfoViewController.h"
#import "AIPreferenceCategory.h"
#import "AIOutOfSyncWindowController.h"

#define CONTACT_LIST_GROUP_NAME		@"Contact List"		//The name of the main contact list group
#define STRANGER_GROUP_NAME		@"__Strangers"		//The name of the hidden stranger group
#define KEY_CONTACT_LIST 		@"ContactList"		//Contact list key
#define GROUP_CONTACT_LIST		@"Contact List"		//Contact list preference group

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
    //Load the contact list
    contactList = [[self loadContactList] retain];

    //Create a dynamic strangers group
    strangerGroup = [self createGroupNamed:STRANGER_GROUP_NAME inGroup:contactList];
    [[strangerGroup displayArrayForKey:@"Dynamic"] addObject:[NSNumber numberWithBool:YES] withOwner:self];
    [self updateListForObject:strangerGroup saveChanges:NO];

    //
    handleObserverArray = [[NSMutableArray alloc] init];
    delayedUpdating = 0;
    
    //
    contactInfoCategory = [[AIPreferenceCategory categoryWithName:@"" image:nil] retain];
}

//dealloc
- (void)dealloc
{
    [contactList release];
    [handleObserverArray release]; handleObserverArray = nil;
    [contactNotificationCenter release]; contactNotificationCenter = nil;
    [contactInfoCategory release];

    [super dealloc];
}

//Notification center for contact notifications
- (NSNotificationCenter *)contactNotificationCenter
{
    if(contactNotificationCenter == nil){
        contactNotificationCenter = [[NSNotificationCenter alloc] init];
    }
    
    return(contactNotificationCenter);
}

// Contact Info --------------------------------------------------------------------------------
//Show the info window for a contact
- (void)showInfoForContact:(AIContactHandle *)inContact
{
    [[AIContactInfoWindowController contactInfoWindowControllerWithOwner:owner category:contactInfoCategory forContact:inContact] showWindow:nil];
}

//Add a contact info view
- (void)addContactInfoView:(AIContactInfoViewController *)inView
{
    [contactInfoCategory addView:inView];
}


// Accounts --------------------------------------------------------------------------------
//Add an account to an existing object
- (void)addAccount:(AIAccount<AIAccount_Handles> *)inAccount toObject:(AIContactObject *)inObject
{

    if([inAccount conformsToProtocol:@protocol(AIAccount_GroupedHandles)]){ //Account supports groups
        AIContactGroup *containingGroup = [inObject containingGroup];

        //Add the containing group (if it's not yet on the account)
        if(![containingGroup belongsToAccount:inAccount]){
            [containingGroup registerOwner:inAccount];
            [(AIAccount<AIAccount_GroupedHandles> *)inAccount addGroup:containingGroup];
        }

        //Add the account to the object
        [inObject registerOwner:inAccount];
        if([inObject isKindOfClass:[AIContactHandle class]]){ //Handle
            [(AIAccount<AIAccount_GroupedHandles> *)inAccount addHandle:(AIContactHandle *)inObject toGroup:containingGroup];
        
        }else if([inObject isKindOfClass:[AIContactGroup class]]){ //Group
            [(AIAccount<AIAccount_GroupedHandles> *)inAccount addGroup:(AIContactGroup *)inObject];
        
        }

    }else if([inAccount conformsToProtocol:@protocol(AIAccount_Handles)]){ //..doesn't support groups
        //Add the account to the handle
        if([inObject isKindOfClass:[AIContactHandle class]]){ //Handle
            [inObject registerOwner:inAccount];
            [inAccount addHandle:(AIContactHandle *)inObject];
        }
    }

    //Re-order and update the list
    [self updateListForObject:inObject saveChanges:NO];
}

//Remove an account from an existing handle/cluster
- (void)removeAccount:(AIAccount<AIAccount_Handles> *)inAccount fromObject:(AIContactObject *)inObject
{
    if([inAccount conformsToProtocol:@protocol(AIAccount_GroupedHandles)]){ //Account supports groups
        AIContactGroup *containingGroup = [inObject containingGroup];

        //Remove the object from the account
        [inObject unregisterOwner:inAccount];
        if([inObject isKindOfClass:[AIContactHandle class]]){ //Handle
            [(AIAccount<AIAccount_GroupedHandles> *)inAccount removeHandle:(AIContactHandle *)inObject fromGroup:containingGroup];
        
        }else if([inObject isKindOfClass:[AIContactGroup class]]){ //Group
            [(AIAccount<AIAccount_GroupedHandles> *)inAccount removeGroup:(AIContactGroup *)inObject];

        }

        //If the containing group no longer contains anything on this account, remove it as well
        if([containingGroup contentsBelongToAccount:inAccount] == 0){
            [containingGroup unregisterOwner:inAccount];
            [(AIAccount<AIAccount_GroupedHandles> *)inAccount removeGroup:containingGroup];
        }
        
    }else if([inAccount conformsToProtocol:@protocol(AIAccount_Handles)]){ //..doesn't support groups
        //Remove the handle from the handle
        if([inObject isKindOfClass:[AIContactHandle class]]){ //Handle
            [inObject unregisterOwner:inAccount];
            [inAccount removeHandle:(AIContactHandle *)inObject];
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
    newGroup = [AIContactGroup contactGroupWithName:inName];
    [inGroup addObject:newGroup];
    
    //Re-order and update the list
    [newGroup sortGroupAndSubGroups:NO]; //update the group
    [self updateListForObject:newGroup saveChanges:YES]; //update the list
    
    return(newGroup);
}

//Delete a group
- (void)deleteGroup:(AIContactGroup *)inGroup
{
    NSArray		*accountArray;
    AIContactGroup	*containingGroup = [inGroup containingGroup];
    int			loop;

    //Delete everything in the group
    while([inGroup count] != 0){
        [self deleteHandle:[inGroup objectAtIndex:0]];
    }

    //notify all accounts that the group will be deleted
    accountArray = [[owner accountController] accountArray];
    for(loop = 0;loop < [accountArray count];loop++){
        AIAccount<AIAccount_GroupedHandles>	*account = [accountArray objectAtIndex:loop];
               
        NSParameterAssert([account conformsToProtocol:@protocol(AIAccount_GroupedHandles)]);

        if([inGroup belongsToAccount:account]){
            [account removeGroup:inGroup];
        }
    }

    //Delete the group
    [[inGroup containingGroup] removeObject:inGroup];
    
    //Re-order and update the list
    [self updateListForObject:containingGroup saveChanges:YES];
}

//rename a group
- (void)renameGroup:(AIContactGroup *)inGroup to:(NSString *)newName
{
    NSArray		*accountArray;
    int			loop;

    //Notify all accounts that the group will be renamed
    accountArray = [[owner accountController] accountArray];
    for(loop = 0;loop < [accountArray count];loop++){
        AIAccount<AIAccount_GroupedHandles>	*account = [accountArray objectAtIndex:loop];
        
        NSParameterAssert([account conformsToProtocol:@protocol(AIAccount_GroupedHandles)]);

        if([inGroup belongsToAccount:account]){
            [account renameGroup:inGroup to:newName];
        }
    }

    //Rename the group
    [inGroup setName:newName];
    
    //Re-order and update the list
    [self updateListForObject:inGroup saveChanges:YES];
}

// Handles --------------------------------------------------------------------------------
//Delete a handle
- (void)deleteHandle:(AIContactHandle *)inHandle
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    AIContactGroup	*containingGroup = [inHandle containingGroup];

    //notify account(s) that the handle will be deleted
    enumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){                
        if([inHandle belongsToAccount:account]){
            if([account conformsToProtocol:@protocol(AIAccount_GroupedHandles)]){
                [(AIAccount<AIAccount_GroupedHandles> *)account removeHandle:inHandle fromGroup:[inHandle containingGroup]];
    
            }else if([account conformsToProtocol:@protocol(AIAccount_Handles)]){
                [(AIAccount<AIAccount_Handles> *)account removeHandle:inHandle];

            }
        }
    }

    //Delete the handle
    [containingGroup removeObject:inHandle];
    
    //Re-order and update the list
    [self updateListForObject:containingGroup saveChanges:YES];
}

//Rename a handle
- (void)renameHandle:(AIContactHandle *)inHandle to:(NSString *)newName
{
    NSEnumerator	*enumerator;
    AIAccount		*account;

    //Filter the UID (force lowercase, and/or remove invalid characters)
    //We let each owner account's service have a chance at filtering
    enumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        if([inHandle belongsToAccount:account]){
            newName = [[[account service] handleServiceType] filterUID:newName];
        }
    }

    //notify the account(s) that the handle will been renamed
    enumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){        
        if([inHandle belongsToAccount:account]){
            if([account conformsToProtocol:@protocol(AIAccount_GroupedHandles)]){
                [(AIAccount<AIAccount_GroupedHandles> *)account renameHandle:inHandle inGroup:[inHandle containingGroup] to:newName];
    
            }else if([account conformsToProtocol:@protocol(AIAccount_Handles)]){
                [(AIAccount<AIAccount_Handles> *)account renameHandle:inHandle to:newName];

            }
        }
    }

    //rename the handle
    [inHandle setUID:newName];
    
    //Re-order and update the list
    [self updateListForObject:inHandle saveChanges:YES];
}

//Move a handle
- (void)moveHandle:(AIContactHandle *)inHandle toGroup:(AIContactGroup *)inGroup
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    AIContactGroup	*containingGroup = [inHandle containingGroup];

    if(!inGroup) inGroup = [self contactList]; //If no group is specified, we move to the root level
    
    //notify the account(s) that the handle will been moved
    enumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        if([inHandle belongsToAccount:account] && [account conformsToProtocol:@protocol(AIAccount_GroupedHandles)]){
            [(AIAccount<AIAccount_GroupedHandles> *)account moveHandle:inHandle fromGroup:containingGroup toGroup:inGroup];
        }
    }

    //move the handle
    [inHandle retain];				//Hold onto the handle so it doesn't accidentally get released
    [containingGroup removeObject:inHandle];
    [inGroup addObject:inHandle];
    [inHandle release];
    
    //Re-order and update the list
    [self updateListForObject:inHandle saveChanges:YES];    
}
    
 
// List Searching --------------------------------------------------------------------------------
//Finds a group with the specified name
- (AIContactGroup *)groupWithName:(NSString *)inName
{
    return([self groupInGroup:contactList withName:inName]);
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

//Called when a handle's status changes
- (void)handleStatusChanged:(AIContactHandle *)inHandle modifiedStatusKeys:(NSArray *)InModifiedKeys
{
    int	handleAltered = 0;
    int loop;

    //Let all the observers know it changed
    for(loop = 0;loop < [handleObserverArray count];loop++){
        handleAltered += [[handleObserverArray objectAtIndex:loop] updateHandle:inHandle keys:InModifiedKeys];
    }

    if(handleAltered){ //If the handle was modified
        [self updateListForObject:inHandle saveChanges:NO];
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

- (BOOL)contactListUpdatesDelayed
{
    return(delayedUpdating != 0);
}


// Internal --------------------------------------------------------------------------------
//Call after making changes to an object on the contact list
- (void)updateListForObject:(AIContactObject *)inObject saveChanges:(BOOL)saveChanges
{
    AIContactObject	*object = inObject;

    //Resort its group, and any groups above it
    if(!delayedUpdating){ //Skip sorting when updates are delayed
        while((object = [object containingGroup])){
            [(AIContactGroup *)object sortGroupAndSubGroups:NO];
        }
    }

    //Post an 'object' changed message, signaling that the object's status has changed.
    [[self contactNotificationCenter] postNotificationName:Contact_ObjectChanged object:inObject];

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
        
            if([[(AIContactGroup *)object displayName] compare:inName] == 0){
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
    [contactList sortGroupAndSubGroups:YES];
    [[self contactNotificationCenter] postNotificationName:Contact_ListChanged object:nil];

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

    [[owner preferenceController] setPreference:saveDict forKey:KEY_CONTACT_LIST group:GROUP_CONTACT_LIST];
}

//Load the contact list from disk
- (AIContactGroup *)loadContactList
{
    NSDictionary	*saveDict;
    AIContactGroup	*contactListGroup;

    //Load & build the list
    saveDict = [[[owner preferenceController] preferencesForGroup:GROUP_CONTACT_LIST] objectForKey:KEY_CONTACT_LIST];    
    if(!saveDict){
        contactListGroup = [AIContactGroup contactGroupWithName:CONTACT_LIST_GROUP_NAME];
    }else{
        contactListGroup = [self createGroupFromDict:saveDict];
    }

    //Sort the list
    [contactListGroup sortGroupAndSubGroups:YES];

    return(contactListGroup);
}

//Create a group from the passed dictionary
- (AIContactGroup *)createGroupFromDict:(NSDictionary *)groupDict
{
    AIContactGroup	*group;
    NSString		*groupName;
    NSEnumerator	*enumerator;
    NSArray		*contentsArray;
    NSDictionary	*objectDict;

    //Create and config the group
    groupName = [groupDict objectForKey:@"Name"];
    group = [AIContactGroup contactGroupWithName:groupName];

    //Create it's contents
    contentsArray = [groupDict objectForKey:@"Contents"];
    enumerator = [contentsArray objectEnumerator];
    while((objectDict = [enumerator nextObject])){
        NSString *type = [objectDict objectForKey:@"Type"];

        if([type compare:@"Contact"] == 0){
            NSString 	*UID = [objectDict objectForKey:@"UID"];
            NSString 	*service = [objectDict objectForKey:@"Service"];

            [group addObject:[AIContactHandle handleWithServiceID:service UID:UID]];
            
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
    [saveDict setObject:[inGroup displayName] forKey:@"Name"];

    //Add all contained objects
    enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if(![[object displayArrayForKey:@"Dynamic"] containsAnyIntegerValueOf:1]){ //Don't save dynamic objects
            if([object isKindOfClass:[AIContactHandle class]]){ //Handle
                NSMutableDictionary	*objectDict = [[NSMutableDictionary alloc] init];
    
                [objectDict setObject:@"Contact" forKey:@"Type"];
                [objectDict setObject:[(AIContactHandle *)object UID] forKey:@"UID"];
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

