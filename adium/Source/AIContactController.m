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

@interface AIContactController (PRIVATE)
- (AIContactHandle *)handleInGroup:(AIContactGroup *)inGroup withService:(AIServiceType *)service UID:(NSString *)UID;
- (void)updateListForObject:(AIContactObject *)inObject;
- (AIContactGroup *)groupInGroup:(AIContactGroup *)inGroup withName:(NSString *)inName;
- (void)delayedUpdateTimer:(NSTimer *)inTimer;
@end

@implementation AIContactController

//init
- (void)initController
{
    contactList = [[AIContactGroup contactGroupWithName:CONTACT_LIST_GROUP_NAME] retain];
    strangerGroup = [self createGroupNamed:STRANGER_GROUP_NAME inGroup:contactList];
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
    [self updateListForObject:inObject];
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
    [self updateListForObject:inObject];
}

// Groups --------------------------------------------------------------------------------
//Create a new group
- (AIContactGroup *)createGroupNamed:(NSString *)inName inGroup:(AIContactGroup *)inGroup
{
    AIContactGroup	*newGroup;

    //create the new group
    newGroup = [AIContactGroup contactGroupWithName:inName];
    [inGroup addObject:newGroup];
    
    //Re-order and update the list
    [self updateListForObject:newGroup];
    
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
    [self updateListForObject:containingGroup];
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
    [self updateListForObject:inGroup];
}

// Handles --------------------------------------------------------------------------------
//Delete a handle
- (void)deleteHandle:(AIContactHandle *)inHandle
{
    NSArray		*accountArray;
    AIContactGroup	*group;
    int			loop;

    //notify account(s) that the handle will be deleted
    accountArray = [[owner accountController] accountArray];
    for(loop = 0;loop < [accountArray count];loop++){
        AIAccount<AIAccount_Handles>	*account = [accountArray objectAtIndex:loop];
        
        if([inHandle belongsToAccount:account]){
            if([account conformsToProtocol:@protocol(AIAccount_GroupedHandles)]){
                [(AIAccount<AIAccount_GroupedHandles> *)account removeHandle:inHandle fromGroup:[inHandle containingGroup]];
    
            }else if([account conformsToProtocol:@protocol(AIAccount_Handles)]){
                [(AIAccount<AIAccount_Handles> *)account removeHandle:inHandle];

            }
        }
    }

    group = [inHandle containingGroup];

    //Delete the handle
    [group removeObject:inHandle];
    
    //Re-order and update the list
    [self updateListForObject:group];
}

//Rename a handle
- (void)renameHandle:(AIContactHandle *)inHandle to:(NSString *)newName
{
    NSArray		*accountArray;
    int			loop;

    //Filter the UID (force lowercase, and/or remove invalid characters)
    newName = [[inHandle service] filterUID:newName];

    //notify the account(s) that the handle will been renamed
    accountArray = [[owner accountController] accountArray];
    for(loop = 0;loop < [accountArray count];loop++){
        AIAccount *account = [accountArray objectAtIndex:loop];
        
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
    [self updateListForObject:inHandle];
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
        handle = [AIContactHandle handleWithService:inService UID:inUID];
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
    [self updateListForObject:handle];
    [self handleStatusChanged:handle modifiedStatusKeys:nil]; //let all observers touch this new handle
    
    //Return the handle
    return(handle);
}

// Handle status --------------------------------------------------------------------------------
//Registers code to observe handle status changes
- (void)registerHandleObserver:(id <AIHandleObserver>)inObserver
{
    [handleObserverArray addObject:inObserver];
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

    if(handleAltered != 0 && !delayedUpdating){
        [contactList sortGroupAndSubGroups:YES];

        //tell everyone to redraw
        [[self contactNotificationCenter] postNotificationName:Contact_ObjectChanged object:inHandle];
    }else{
        requiresUpdating = YES;
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

//Delays updating the contact list for the specified # of seconds.  Things are still updated, just not as frequently.  Call this before making massive changes to the contact list.  This also prevents any sorting from taking place.
- (void)delayContactListUpdatesFor:(int)seconds
{
#warning Delaying updates causes a crash when editing the buddy list.  changes are made to the buddy list (specifically deleting of groups/handles), and then the outline view tries to redraw on its own, and attempts to references the deleted objects (since it hasn't been sent any update events due to the delay.  Disabled for now.

/*    if(delayedUpdating != 0){
        //If we're already delayed, increase the delay length
        if(seconds > delayedUpdating){
            delayedUpdating = seconds;    
        }
        NSLog(@"(push)Delaying Updates for %i seconds",seconds);

    }else{
        //Flag delayed
        delayedUpdating = seconds;    
        NSLog(@"Delaying Updates for %i seconds",seconds);
        
        //Install a passive update timer
        [NSTimer scheduledTimerWithTimeInterval:(1.0/1.0) target:self selector:@selector(delayedUpdateTimer:) userInfo:nil repeats:YES];
    }*/
}

// Internal --------------------------------------------------------------------------------
//Call after making changes to an object on the contact list
- (void)updateListForObject:(AIContactObject *)inObject
{
    if(!delayedUpdating){
        AIContactObject		*object = inObject;

        //Resort all groups above this object
        while( (object = [object containingGroup]) ){
            [(AIContactGroup *)object sortGroupAndSubGroups:NO];
        }

        //Post an 'object' changed message, signaling that the object's status has changed.
        //When buddy sorting is off and groups have no content reliant display attributes, this refresh will often be unnecessary, but for now the whole list (excluding other sub groups) needs to be resorted and refreshed :(
        [[self contactNotificationCenter] postNotificationName:Contact_ListChanged object:nil];

    }else{
        requiresUpdating = YES; //Postpone the updating until later

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
    //update
    if(requiresUpdating){
        [contactList sortGroupAndSubGroups:YES];
        [[self contactNotificationCenter] postNotificationName:Contact_ListChanged object:nil];
        
        NSLog(@"(UPDATE) Delaying: %i seconds",delayedUpdating);
    }else{
        NSLog(@"Delaying: %i seconds",delayedUpdating);
    }
    
    //decrease the counter
    requiresUpdating = NO;
    delayedUpdating--;
    if(delayedUpdating == 0){
        [inTimer invalidate];
    }
}

@end

