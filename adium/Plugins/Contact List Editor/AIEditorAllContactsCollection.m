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

#import "AIContactListEditorPlugin.h"
#import "AIEditorAllContactsCollection.h"
#import "AIEditorListHandle.h"
#import "AIEditorListGroup.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"


@interface AIEditorAllContactsCollection (PRIVATE)
- (id)initWithOwner:(id)inOwner plugin:(id)inPlugin;
- (void)generateEditorListGroup;
- (void)_positionHandle:(AIEditorListHandle *)handle atIndex:(int)index inGroup:(AIEditorListGroup *)group;
- (void)_positionGroup:(AIEditorListGroup *)group atIndex:(int)index;
- (void)allCollectionsPerformSelector:(SEL)selector onObject:(id)listObject withObject:(id)object;
- (void)collectionArrayChanged:(NSNotification *)notification;
@end


@implementation AIEditorAllContactsCollection

 //Return a collection for all contacts
+ (AIEditorAllContactsCollection *)allContactsCollectionWithOwner:(id)inOwner plugin:(id)inPlugin
{
    return([[[self alloc] initWithOwner:inOwner plugin:inPlugin] autorelease]);
}

//init
- (id)initWithOwner:(id)inOwner plugin:(id)inPlugin
{
    [super initWithOwner:inOwner];

    plugin = [inPlugin retain];
    sortMode = AISortByIndex;

    [[owner notificationCenter] addObserver:self selector:@selector(collectionAddedObject:) name:Editor_AddedObjectToCollection object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(collectionRemovedObject:) name:Editor_RemovedObjectFromCollection object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(collectionRenamedObject:) name:Editor_RenamedObjectOnCollection object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(collectionContentChanged:) name:Editor_CollectionContentChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(collectionArrayChanged:) name:Editor_CollectionArrayChanged object:nil];
    [self collectionArrayChanged:nil];
    
    return(self);
}

- (void)dealloc
{
    //Stop observing
    [[owner notificationCenter] removeObserver:self];

    //Cleanup
    [plugin release];
    
    [super dealloc];
}

- (NSString *)name{
    return(@"All Available Contacts"); //Return our text description
}
- (NSString *)collectionDescription{
    return(@"All Available Contacts");
}
- (BOOL)showOwnershipColumns{
    return(YES);
}
- (BOOL)showCustomEditorColumns{
    return(YES);
}
- (BOOL)showIndexColumn{
    return(YES);
}
- (BOOL)includeInOwnershipColumn{
    return(NO);
}
- (NSString *)UID{
    return(@"AdiumContactList"); //Return a unique identifier
}
- (NSString *)serviceID{
    return(@"");
}
- (NSImage *)icon{
    return([AIImageUtilities imageNamed:@"AllContacts" forClass:[self class]]); //Return our icon description
}
- (BOOL)enabled{
    return(YES); //Return YES if this collection is enabled
}
- (BOOL)editable{
    return(NO);
}





//Add the group to our account
- (void)_addGroup:(AIEditorListGroup *)group
{
    NSEnumerator		*enumerator;
    AIEditorCollection		*collection;

    //Add the object to all available collections (for now)
    enumerator = [[plugin collectionsArray] objectEnumerator];
    while((collection = [enumerator nextObject])){
        if([collection includeInOwnershipColumn] && [collection enabled]){
            [collection addGroupNamed:[group UID] temporary:[group temporary]];
        }
    }

    //Setup its index
    [self _positionGroup:group atIndex:[list count]];
    [super _addGroup:group];
}

//
- (void)_moveGroup:(AIEditorListGroup *)group toIndex:(int)index
{
    //Setup its index
    [self _positionGroup:group atIndex:index];
    [super _moveGroup:group toIndex:index];
}

//
- (void)_addHandle:(AIEditorListHandle *)handle toGroup:(AIEditorListGroup *)group index:(int)index
{
    NSEnumerator		*enumerator;
    AIEditorCollection		*collection;
    AIEditorListGroup		*localGroup;

    //
    enumerator = [[plugin collectionsArray] objectEnumerator];
    while((collection = [enumerator nextObject])){
        if([collection includeInOwnershipColumn] && [collection enabled]){
            localGroup = [collection groupWithUID:[group UID]];
            if(!localGroup){
                localGroup = [collection addGroupNamed:[group UID] temporary:NO];
            }

            [collection addHandleNamed:[handle UID] inGroup:localGroup index:-1 temporary:[handle temporary]];

            //Set the handle's service type correctly
            [handle setServiceID:[collection serviceID]];
        }
    }


    //
    [self _positionHandle:handle atIndex:index inGroup:group];
    [super _addHandle:handle toGroup:group index:index];
}

//
- (void)_moveHandle:(AIEditorListHandle *)handle toGroup:(AIEditorListGroup *)group index:(int)index
{
    NSEnumerator		*enumerator;
    AIEditorCollection		*collection;
    AIEditorListHandle		*localHandle;
    AIEditorListGroup		*localGroup;

    //
    enumerator = [[plugin collectionsArray] objectEnumerator];
    while((collection = [enumerator nextObject])){
        if([collection includeInOwnershipColumn] && [collection enabled]){

            if(localHandle = [collection handleWithUID:[handle UID]]){
                localGroup = [collection groupWithUID:[group UID]];
                if(!localGroup){
                    localGroup = [collection addGroupNamed:[group UID] temporary:NO];
                }

                [collection moveHandle:localHandle toGroup:localGroup index:-1];
            }
        }
    }

    //
    [self _positionHandle:handle atIndex:index inGroup:group];
    [super _moveHandle:handle toGroup:group index:index];
}


//These functions are similar enough that I can combine them to reduce all the redundant code
//Rename on the account
- (void)_renameGroup:(AIEditorListGroup *)group to:(NSString *)name
{
    [self allCollectionsPerformSelector:@selector(renameGroup:to:) onObject:group withObject:name];
    [super _renameGroup:group to:name];
}

//Delete from the account
- (void)_deleteGroup:(AIEditorListGroup *)group
{
    [self allCollectionsPerformSelector:@selector(deleteGroup:) onObject:group withObject:nil];
    [super _deleteGroup:group];
}


//
- (void)_deleteHandle:(AIEditorListHandle *)handle
{
    [self allCollectionsPerformSelector:@selector(deleteHandle:) onObject:handle withObject:nil];
    [super _deleteHandle:handle];
}

//
- (void)_renameHandle:(AIEditorListHandle *)handle to:(NSString *)name
{
    [self allCollectionsPerformSelector:@selector(renameHandle:to:) onObject:handle withObject:name];
    [super _renameHandle:handle to:name];
}


//..prevent all that redundant code
- (void)allCollectionsPerformSelector:(SEL)selector onObject:(id)listObject withObject:(id)object
{
    NSEnumerator		*enumerator;
    AIEditorCollection		*collection;
    AIEditorListGroup		*localGroup;
    AIEditorListHandle		*localHandle;
    BOOL			isGroup;

    //Determine what the object is
    isGroup = [listObject isKindOfClass:[AIEditorListGroup class]];
    
    //
    enumerator = [[plugin collectionsArray] objectEnumerator];
    while((collection = [enumerator nextObject])){
        if([collection includeInOwnershipColumn] && [collection enabled]){
            if(isGroup && (localGroup = [collection groupWithUID:[listObject UID]])){
                [collection performSelector:selector withObject:localGroup withObject:object];
            }else if(!isGroup && (localHandle = [collection handleWithUID:[listObject UID]])){
                [collection performSelector:selector withObject:localHandle withObject:object];
            }
        }
    }
}

//Used internally.  Correctly sets a contact's order index for the desired position
- (void)_positionHandle:(AIEditorListHandle *)handle atIndex:(int)index inGroup:(AIEditorListGroup *)group
{
    float	orderIndex;

    if([group count] == 0){ //If the group is empty, use the group's index as a starting point (anything would work here)
        orderIndex = [group orderIndex];

    }else if(index == [group count]){ //When placing at the bottom of a group, we place 1 below the current bottom
        orderIndex = [[group handleAtIndex:index-1] orderIndex] + 2;

    }else{ //Otherwise, we place at the current index (which will push any existing handles down)
        orderIndex = [[group handleAtIndex:index] orderIndex];

    }

    //Set the new index
    orderIndex = [[owner contactController] setOrderIndexOfContactWithServiceID:[handle serviceID] UID:[handle UID] to:orderIndex];
    [handle setOrderIndex:orderIndex];
}

//Used internally.  Correctly sets a group's order index for the desired position
- (void)_positionGroup:(AIEditorListGroup *)group atIndex:(int)index
{
    float	orderIndex;

    if([list count] == 0){ //If there are no groups, use 1 as a starting point (Anything would work here)
        orderIndex = 1;

    }else if(index == [list count]){ //When placing at the bottom, we place 1 below the current bottom
        orderIndex = [[list objectAtIndex:index-1] orderIndex] + 2;

    }else{ //Otherwise, we place at the current index (which will push any existing group down)
        orderIndex = [[list objectAtIndex:index] orderIndex];

    }

    //Set the new index
    orderIndex = [[owner contactController] setOrderIndexOfGroupWithUID:[group UID] to:orderIndex];
    [group setOrderIndex:orderIndex];
}

//Creates and returns the editor list (editor groups and handles)
- (void)generateEditorListGroup
{
    NSEnumerator		*enumerator, *groupEnumerator, *handleEnumerator;
    AIEditorListGroup		*group, *localGroup;
    AIEditorListHandle		*handle, *localHandle;
    AIEditorCollection		*collection;
    NSString			*groupUID, *handleUID;

    //Create the group array
    [list release];
    list = [[NSMutableArray alloc] init];

    //Process all the ownership enabled collections
    enumerator = [[plugin collectionsArray] objectEnumerator];
    while((collection = [enumerator nextObject])){
        if([collection includeInOwnershipColumn]/* && [collection enabled]*/){
            //Process all groups
            groupEnumerator = [[collection list] objectEnumerator];
            while((group = [groupEnumerator nextObject])){
                
                //Create the group locally (if necessary)
                groupUID = [group UID];
                localGroup = [self groupWithUID:groupUID];
                if(!localGroup){
                    localGroup = [[[AIEditorListGroup alloc] initWithUID:groupUID temporary:NO] autorelease];
                    [localGroup setOrderIndex:[[owner contactController] orderIndexOfKey:groupUID]];
                    [list addObject:localGroup];
                }
                
                //Process all handles
                handleEnumerator = [group handleEnumerator];
                while((handle = [handleEnumerator nextObject])){

                    //Create the handle and add it to the group (if necessary)
                    handleUID = [handle UID];
                    localHandle = [localGroup handleNamed:handleUID];
                    if(!localHandle){
                        localHandle = [[[AIEditorListHandle alloc] initWithUID:handleUID serviceID:[collection serviceID] temporary:NO] autorelease];
                        [localHandle setOrderIndex:[[owner contactController] orderIndexOfKey:[NSString stringWithFormat:@"%@.%@",[collection serviceID],[handle UID]]]];
                        [localGroup addHandle:localHandle];
                    }
                }
            }
        }
    }

    [self sortUsingMode:[self sortMode]];
}

//A collection's content has changed
- (void)collectionContentChanged:(NSNotification *)notification
{
    AIEditorCollection	*collection = [notification object];

    if([collection includeInOwnershipColumn] && collection != self){        
        //Rebuild our content list
        [self generateEditorListGroup];

        //Let the contact list know our handles changed
        [[owner notificationCenter] postNotificationName:Editor_CollectionContentChanged object:self];
    }
}

- (void)collectionArrayChanged:(NSNotification *)notification
{
    //Rebuild our content list
    [self generateEditorListGroup];

    //Let the contact list know our handles changed
    [[owner notificationCenter] postNotificationName:Editor_CollectionContentChanged object:self];
}

- (void)collectionAddedObject:(NSNotification *)notification
{
    AIEditorCollection		*collection = [notification object];
    AIEditorListHandle		*handle = [[notification userInfo] objectForKey:@"Object"];
    BOOL			isGroup = [handle isKindOfClass:[AIEditorListGroup class]];

    if(!controlledChanges){
        if([collection includeInOwnershipColumn] && collection != self){
            
            //If object isn't already on our list
            if(!isGroup && ![self containsHandleWithUID:[handle UID]]){
                //Rebuild our list (It'd be faster to just add the new handle here, however)
                [self generateEditorListGroup];
            }
        }
    }
}

- (void)collectionRemovedObject:(NSNotification *)notification
{
    AIEditorCollection	*collection = [notification object];
    AIEditorListHandle	*handle = [[notification userInfo] objectForKey:@"Object"];

    if(!controlledChanges){    
        if([collection includeInOwnershipColumn] && collection != self){
            NSString	*handleUID = [handle UID];
            NSEnumerator	*enumerator;
    
            //Scan all the collections
            enumerator = [[plugin collectionsArray] objectEnumerator];
            while((collection = [enumerator nextObject]) && (![collection includeInOwnershipColumn] || ![collection containsHandleWithUID:handleUID]));
    
            //If the object is no longer owned by any of the collections, remove it from our list
            if(!collection){
                AIEditorListHandle	*ourHandle;
    
                //Remove the handle from our list
                ourHandle = [self handleWithUID:handleUID];
                [[ourHandle containingGroup] removeHandle:ourHandle];
    
                //Let the contact list editor know our handles changed
                [[owner notificationCenter] postNotificationName:Editor_CollectionContentChanged object:self];
            }
        }
    }
}

- (void)collectionRenamedObject:(NSNotification *)notification
{
    if(!controlledChanges){    
        //Rebuild our list (for now)
        [self generateEditorListGroup];
    }
}


//A collection's status has changed
- (void)collectionStatusChanged:(NSNotification *)notification
{
}


@end






