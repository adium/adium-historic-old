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

#import "AIContactListGeneration.h"
#import "Adium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

/*

 This file contains what should be very simple code.  The goal is to generate a structure of AIListGroups and AIListContacts using the AIHandles contained by each account as a guide.  When an AIHandle's location/grouping is ambiguous, the grouping of the first active account is used.

 Contact order is determined by index values stored in a preference dictionary.
 
 However, doing a regeneration of this structure from scratch in response to every handle change would be very slow.  But at the same time, optimizations would require a lot of complicated code (see below :P) since even a simple handle addition could require movement of existing contacts.

 To help simplify things a bit, I've divided handle changes into 3 types.  addedToAccount, removedFromAccount, and handlesChanged.  For handles added and removed, optimizations can be used to avoid regeneration.  For handlesChanged, there are too many changes and a regeneration cannot be avoided.

 */

#define PREF_GROUP_CONTACT_LIST		@"Contact List"			//Contact list preference group
#define KEY_CONTACT_LIST_GROUP_STATE	@"Contact List Group State"	//Expand/Collapse state of groups

@interface AIContactListGeneration (PRIVATE)
- (AIListGroup *)_getGroupNamed:(NSString *)serverGroup;
- (void)_correctlyExpandCollapseGroup:(AIListGroup *)group;
- (BOOL)_addHandle:(AIHandle *)handle generatingList:(BOOL)generatingList;
- (NSString *)_groupNameForContact:(AIListContact *)contact;
- (void)_breakDownGroup:(AIListGroup *)inGroup;
- (void)_moveContact:(AIListContact *)contact toGroupNamed:(NSString *)groupName;
@end

@implementation AIContactListGeneration

- (id)initWithContactList:(AIListGroup *)inContactList owner:(id)inOwner
{
    [super init];

    //
    contactList = [inContactList retain];
    owner = [inOwner retain];
    groupDict = [[NSMutableDictionary alloc] init];
    abandonedContacts = [[NSMutableDictionary alloc] init];
    abandonedGroups = [[NSMutableDictionary alloc] init];
    
    return(self);
}

//A handle was added to an account
- (void)handle:(AIHandle *)inHandle addedToAccount:(AIAccount *)inAccount
{
    if([self _addHandle:inHandle generatingList:NO]){ //Add the handle
        //Let everyone know the contact list changed
        [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
    }
}

//A handle was removed from an account
- (void)handle:(AIHandle *)inHandle removedFromAccount:(AIAccount *)inAccount
{
    AIListContact	*containingContact = [inHandle containingContact];
    NSArray		*statusKeyArray;
    NSString		*groupName;

    //Remove ALL status flags from the handle, and give observers a chance to remove their attributes
    statusKeyArray = [[inHandle statusDictionary] allKeys];
    [[inHandle statusDictionary] removeAllObjects];
    [[owner contactController] handleStatusChanged:inHandle modifiedStatusKeys:statusKeyArray delayed:NO silent:YES];

    //Remove the handle
    [containingContact removeHandle:inHandle];

    //If the contact isn't empty, make sure it is still in the proper group
    if([containingContact numberOfHandles]){
        groupName = [self _groupNameForContact:containingContact];
        if([groupName compare:[[containingContact containingGroup] UID]] != 0){
            [self _moveContact:containingContact toGroupNamed:groupName]; //Move contact to the correct group
        }
    }
        
    //Let everyone know the contact list changed
    [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
}

//Handles have changed and the contact list must be rebuild
- (void)handlesChangedForAccount:(AIAccount *)inAccount
{
    NSEnumerator		*accountEnumerator;
    AIAccount			*account;

    //Flush the existing list
    [self _breakDownGroup:contactList];
    [groupDict release]; groupDict = [[NSMutableDictionary alloc] init];
    
    //Process every handle of every account
    accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [accountEnumerator nextObject])){
        if([account conformsToProtocol:@protocol(AIAccount_Handles)]){
            NSEnumerator	*handleEnumerator;
            AIHandle		*handle;

            handleEnumerator = [[[(AIAccount<AIAccount_Handles> *)account availableHandles] allValues] objectEnumerator];
            while((handle = [handleEnumerator nextObject])){
                [self _addHandle:handle generatingList:YES];
            }
        }
    }
    
    //Let everyone know the contact list changed
    [[owner notificationCenter] postNotificationName:Contact_ListChanged object:nil];
}

//Saves the expand/collapse state of groups
- (void)saveGroupState
{
    NSDictionary	*preferences;
    NSMutableDictionary	*groupStateDict;
    NSEnumerator	*enumerator;
    AIListGroup		*group;
    
    //Get the group state dict
    preferences = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
    groupStateDict = [[preferences objectForKey:KEY_CONTACT_LIST_GROUP_STATE] mutableCopy];
    if(!groupStateDict){
        groupStateDict = [[NSMutableDictionary alloc] init];
    }

    //Set expanded/collapsed state of groups
    enumerator = [contactList objectEnumerator];
    while((group = [enumerator nextObject])){
        [groupStateDict setObject:[NSNumber numberWithBool:[group isExpanded]]
                           forKey:[group UID]];
    }
    
    //Set expanded/collapsed state of abandoned groups
    enumerator = [[abandonedGroups allValues] objectEnumerator];
    while((group = [enumerator nextObject])){
        [groupStateDict setObject:[NSNumber numberWithBool:[group isExpanded]]
                           forKey:[group UID]];
    }

    //Save
    [[owner preferenceController] setPreference:groupStateDict
                                         forKey:KEY_CONTACT_LIST_GROUP_STATE
                                          group:PREF_GROUP_CONTACT_LIST];

    [groupStateDict release];
}

- (AIListContact *)createContactWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
    AIListContact	*contact;
    //We assume this is being called by contact controller, that the contact list has already been searched for this contact, and that it does not exist.
    
    //Does this contact already exist in our abandoned contact cache?
    contact = [abandonedContacts objectForKey:inUID];
    if(!contact){ //If not

        //Create the contact
        contact = [[AIListContact alloc] initWithUID:inUID serviceID:inServiceID];
        [contact setOrderIndex:[[owner contactController] orderIndexOfContact:contact]];

        //Shove it right into our abandoned contact cache (It belongs there because it is empty)
        [abandonedContacts setObject:contact forKey:inUID];
    }

    return(contact);
}


//Private ------------------------------------------------------------------------
//Adds a handle to the contact list
//Returns YES if the contact list was modified (and a listChanged notificatin should be posted)
- (BOOL)_addHandle:(AIHandle *)handle generatingList:(BOOL)generatingList
{
    NSString		*serverGroup = [handle serverGroup];
    NSString		*handleUID = [handle UID];
    AIListContact	*contact;
    BOOL		updateList = NO;

//attempt at simple dynamic temp group
    if([handle temporary]){
        serverGroup = @"Strangers";
        NSLog(@"%@ temporary",handleUID);
    }
       

    //Does a contact for this handle already exist on our list?
    contact = [[owner contactController] contactInGroup:contactList withService:[handle serviceID] UID:handleUID serverGroup:nil];
    if(contact){ //If it does
        NSString	*groupName;

        //Add our handle
        [contact addHandle:handle];

        //we skip this step (for a bit of speed) when generating the list
        if(!generatingList){
            //Make sure the contact is still in the proper group
            groupName = [self _groupNameForContact:contact];
            if([groupName compare:[[contact containingGroup] UID]] != 0){
                [self _moveContact:contact toGroupNamed:groupName]; //Move contact to the correct group
                updateList = YES;
            }
        }
        
    }else{ //If it doesn't
        //Does a contact for this handle already exist on the abandoned contact cache?
        contact = [abandonedContacts objectForKey:handleUID];
        if(contact){ //If it does
            //Move it back to the contact list
            [[self _getGroupNamed:serverGroup] addObject:contact];
            [abandonedContacts removeObjectForKey:handleUID];

            //Add our handle
            [contact addHandle:handle];

        }else{ //If it doesn't
            //create a new contact
            contact = [[AIListContact alloc] initWithUID:handleUID serviceID:[handle serviceID]];
            [contact setOrderIndex:[[owner contactController] orderIndexOfContact:contact]];

            [[self _getGroupNamed:serverGroup] addObject:contact];

            //Add our handle
            [contact addHandle:handle];
        }
    }

    //Give observers a chance to add attributes for the new handle
    [[owner contactController] handleStatusChanged:handle modifiedStatusKeys:nil delayed:YES silent:YES];

    return(updateList);
}

//Returns the specified group, creating or recycling if necessary
- (AIListGroup *)_getGroupNamed:(NSString *)serverGroup
{
    AIListGroup		*group;

    //Does the group already exist?
    group = [groupDict objectForKey:serverGroup];
    if(!group){ //If it doesn't
        //Does the group already exist in the abandoned group cache?
        group = [abandonedGroups objectForKey:serverGroup];
        if(group){ //If it does
            //Move it back to the contact list
            [contactList addObject:group];			//Add the group to our contact list
            [groupDict setObject:group forKey:serverGroup];	//Add it to our group tracking dict
            [abandonedGroups removeObjectForKey:serverGroup]; 	//remove it from the abandoned cache
            
        }else{ //If it doesn't
            //Create the group
            group = [[[AIListGroup alloc] initWithUID:serverGroup] autorelease];
            [group setOrderIndex:[[owner contactController] orderIndexOfGroup:group]];

            [self _correctlyExpandCollapseGroup:group];		//Correctly set the group as expanded or collapsed
            [contactList addObject:group];			//Add the group to our contact list
            [groupDict setObject:group forKey:serverGroup];	//Add it to our group tracking dict
        }
    }

    //Return the group
    return(group);
}    

//Sets the specified group to the correct expanded/collapsed state
- (void)_correctlyExpandCollapseGroup:(AIListGroup *)group
{
    NSNumber	*expandedNum = [[[[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST] objectForKey:KEY_CONTACT_LIST_GROUP_STATE] objectForKey:[group UID]];
    BOOL	expanded;

    //Default to expanded
    if(expandedNum){
        expanded = [expandedNum boolValue];
    }else{
        expanded = YES;
    }

    //Correctly expand/collapse the group
    [group setExpanded:expanded]; 
}

//Returns the group requested (for this contact) by the highest account in the account list that is currently available
- (NSString *)_groupNameForContact:(AIListContact *)contact
{
    NSEnumerator	*accountEnumerator;
    AIAccount		*account;

    //Walk our way down the account list, looking for the first account with a handle in this contact
    accountEnumerator = [[[owner accountController] accountArray] objectEnumerator];
    while((account = [accountEnumerator nextObject])){
        AIHandle		*contactHandle;

        if(contactHandle = [contact handleForAccount:account]){ //We found one
            return([contactHandle serverGroup]);
        }
    }

    return(nil);
}

//Move the contact to another group
- (void)_moveContact:(AIListContact *)contact toGroupNamed:(NSString *)groupName
{
    AIListGroup		*containingGroup;
    
    [contact retain]; //Hold onto it temporarily

    //Remove the contact from its current group, and resort
    containingGroup = [contact containingGroup];
    [containingGroup removeObject:contact];	
    [[owner contactController] sortListGroup:containingGroup mode:AISortGroupAndSuperGroups];

    //Add the contact from its new group, and resort
    containingGroup = [self _getGroupNamed:groupName];
    [containingGroup addObject:contact];
    [[owner contactController] sortListGroup:containingGroup mode:AISortGroupAndSuperGroups];

    [contact release];
}

//Moves all contacts and groups into the abandoned cache
- (void)_breakDownGroup:(AIListGroup *)inGroup
{
    NSEnumerator	*enumerator;
    AIListObject	*object;

    //Scan through and process all objects in this group
    enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIListContact class]]){
            //Empty and cache the contact
            [(AIListContact *)object removeAllHandles];
            [abandonedContacts setObject:object forKey:[object UID]];

        }else if([object isKindOfClass:[AIListGroup class]]){
            //Breakdown the subgroup
            [self _breakDownGroup:(AIListGroup *)object];

        }

        [object setContainingGroup:nil];
    }

    //Process this group
    [inGroup removeAllObjects];
    if(inGroup != contactList){ //We don't want to cache the root contact list group
        [abandonedGroups setObject:inGroup forKey:[inGroup UID]]; //Empty and cache the group
    }
}

@end
