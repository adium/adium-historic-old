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

#import "AIAdium.h"
#import "AIEditorCollection.h"
#import	"AIEditorListGroup.h"
#import	"AIEditorListHandle.h"
#import "AIContactListEditorPlugin.h"

@implementation AIEditorCollection

- (id)initWithOwner:(id)inOwner
{
    [super init];

    owner = [inOwner retain];
    list = [[NSMutableArray alloc] init];
    sortMode = AISortByName;
    controlledChanges = NO;
    //The controlledChanges variable is used to make things faster by avoiding unnecessary regeneration of the editor list group.  Before making changes, we set controlledChanges to YES.  If changes are received when none are expected, we regenerate the list.
    
    return(self);
}

- (void)dealloc
{
    [owner release];
    [list release];
    
    [super dealloc];
}

//Basic configuration of this collection
- (NSString *)name{
    return(@"");
}
- (NSString *)UID{
    return(@"");
}
- (NSImage *)icon{
    return(nil);
}
- (BOOL)enabled{
    return(NO);
}
- (BOOL)editable{
    return(NO);
}
- (BOOL)showOwnershipColumns{
    return(NO);
}
- (BOOL)showCustomEditorColumns{
    return(NO);
}
- (BOOL)showIndexColumn{
    return(YES);
}
- (NSString *)collectionDescription{
    return(@"");
}
- (BOOL)includeInOwnershipColumn{
    return(NO);
}
- (NSString *)serviceID{
    return(@"");
}
- (NSMutableArray *)list{
    return(list);
}


//Sorting
int _nameSort(AIEditorListHandle *objectA, id objectB, void *context){
    return([[objectA UID] caseInsensitiveCompare:[objectB UID]]);
}
int _indexSort(AIEditorListHandle *objectA, AIEditorListHandle *objectB, void *context){
    float orderA = [objectA orderIndex];
    float orderB = [objectB orderIndex];

    if(orderA < orderB){
        return(NSOrderedAscending);
    }else if(orderA > orderB){
        return(NSOrderedDescending);
    }else{
        return(NSOrderedSame);
    }
}

//Sort the collection using the specified mode and direction
- (void)sortUsingMode:(AICollectionSortMode)mode
{
    NSEnumerator	*enumerator;
    AIEditorListGroup	*group;

    //Save the new sort mode & direction
    sortMode = mode;

    //Sort the groups
    [self sortGroupArray];
    
    //Sort the group contents
    enumerator = [list objectEnumerator];
    while((group = [enumerator nextObject])){
        [self sortGroup:group]; 
    }
}

//Sort a group's contents
- (void)sortGroup:(AIEditorListGroup *)group
{
    if(sortMode == AISortByName){
        [[group contentArray] sortUsingFunction:_nameSort context:nil];
    }else if(sortMode == AISortByIndex){
        [[group contentArray] sortUsingFunction:_indexSort context:nil];
    }
}

//Sort the list of groups
- (void)sortGroupArray
{
    if(sortMode == AISortByName){
        NSLog(@"name SortList");
        [list sortUsingFunction:_nameSort context:nil];
    }else if(sortMode == AISortByIndex){
        NSLog(@"index SortList");
        [list sortUsingFunction:_indexSort context:nil];
    }
}

//Returns the last used sort mode / direction
- (AICollectionSortMode)sortMode{
    return(sortMode);
}


//Add a group
- (AIEditorListGroup *)addGroupNamed:(NSString *)name temporary:(BOOL)temporary
{
    AIEditorListGroup	*group;

    controlledChanges = YES;

    //If a group with this UID doesn't already exist on our collection, create it
    group = [self groupWithUID:name];
    if(!group){
        group = [[AIEditorListGroup alloc] initWithUID:name temporary:temporary];
        [self _addGroup:group];

        //Resort our groups
        [self sortGroupArray];
    }

    controlledChanges = NO;

    return(group);
}

//Move a group
- (void)moveGroup:(AIEditorListGroup *)inGroup toIndex:(int)index
{
    if(index == -1) index = [list count];

    controlledChanges = YES;

    [inGroup retain]; //Temporarily hold onto the group
    [self _moveGroup:inGroup toIndex:index];
    [inGroup release];

    //Resort our groups
    [self sortGroupArray];

    controlledChanges = NO;
}

//Rename a Group
- (void)renameGroup:(AIEditorListGroup *)inGroup to:(NSString *)newName
{
    NSString	*oldName;
    BOOL 	nameDidChange;
    BOOL 	newNameIsUnique;

    //Setup
    oldName = [inGroup UID];
    nameDidChange = ([oldName compare:newName] != 0);
    newNameIsUnique = ([self groupWithUID:newName] == nil);
    controlledChanges = YES;

    if([inGroup temporary]){ //If the group was temporary
        //Delete it
        [self deleteGroup:inGroup];

        //Add a new (non-temporary) one with the correct name (or the original name if the new one is invalid)
        if(nameDidChange && newNameIsUnique){
            [self addGroupNamed:newName temporary:NO];
        }else{
            [self addGroupNamed:oldName temporary:NO];
        }

    }else{ //If the group was regular
        if(nameDidChange){ //Ignore if the name didn't change
            if(!newNameIsUnique){
                NSRunAlertPanel(@"Group already exists.", [NSString stringWithFormat:@"A group named \"%@\" already exists on this list.  Choose another name or use the existing group.",newName] , nil, nil, nil);
            }else{
                [self _renameGroup:inGroup to:newName];
            }
            
        }
    }

    //Resort our groups
    [self sortGroupArray];

    controlledChanges = NO;
}

//Delete a group
- (void)deleteGroup:(AIEditorListGroup *)inGroup
{
    controlledChanges = YES;
    [inGroup retain]; //Hold onto the group temporarily
    [self _deleteGroup:inGroup];
    [inGroup release];

    //Resort our groups
    [self sortGroupArray];

    controlledChanges = NO;
}


//Add a handle
- (AIEditorListHandle *)addHandleNamed:(NSString *)inName inGroup:(AIEditorListGroup *)group index:(int)index temporary:(BOOL)temporary
{
    AIEditorListHandle	*handle;

    controlledChanges = YES;
    if(index == -1) index = [group count];

    //Make sure a handle with this UID doesn't already exist on our collection
    if(handle = [self handleWithUID:inName]){
        //Move the existing handle to the new group, and return it
        [self moveHandle:handle toGroup:group index:index];

    }else{
        //Create a new handle
        handle = [[AIEditorListHandle alloc] initWithUID:inName temporary:temporary];
        [self _addHandle:handle toGroup:group index:index];

    }

    //Resort our handles
    [self sortGroup:group];

    controlledChanges = NO;

    return(handle);
}

//Move a handle
- (void)moveHandle:(AIEditorListHandle *)inHandle toGroup:(AIEditorListGroup *)inGroup index:(int)index
{
    AIEditorListGroup	*oldGroup = [inHandle containingGroup];

    controlledChanges = YES;

    if(index == -1) index = [inGroup count];

    [inHandle retain]; //Temporarily hold onto the handle

//    if(oldGroup != inGroup){ //Swap it from one group to the other
//        [self _deleteHandle:inHandle];
//        [self _addHandle:inHandle toGroup:inGroup index:index];
//    }else{ //Move it within the group
        [self _moveHandle:inHandle toGroup:inGroup index:index];
//    }

    [inHandle release];

    //Resort our handles
    if(oldGroup != inGroup) [self sortGroup:oldGroup];
    [self sortGroup:inGroup];

    controlledChanges = NO;
}

//Delete a handle
- (void)deleteHandle:(AIEditorListHandle *)inHandle
{
    AIEditorListGroup	*group = [inHandle containingGroup];

    controlledChanges = YES;

    [inHandle retain]; //Temporarily hold onto the handle
    [self _deleteHandle:inHandle];
    [inHandle release];

    //Resort our handles
    [self sortGroup:group];

    controlledChanges = NO;
}

//Rename a handle
- (void)renameHandle:(AIEditorListHandle *)inHandle to:(NSString *)newName
{
    controlledChanges = YES;

    if([inHandle temporary]){ //Temporary Handle
        AIEditorListGroup	*group = [inHandle containingGroup];
        int			index = [group indexOfHandle:inHandle];

        //If the handle was temporary, we delete it and create a new (non temporary) one with the correct name
        [self deleteHandle:inHandle];
        [self addHandleNamed:newName inGroup:group index:index temporary:NO];

    }else{ //Regular Handle
        if([[inHandle UID] compare:newName] != 0){ //Ignore if the name didn't change
            AIEditorListHandle	*existingHandle;
    
            //Make sure a handle with the new UID doesn't already exist on the collection
            if(existingHandle = [self handleWithUID:newName]){
                [self deleteHandle:existingHandle]; //Delete the existing handle
            }
    
            //Rename the handle
            [self _renameHandle:inHandle to:newName];

            //Resort our handles
            [self sortGroup:[inHandle containingGroup]];
        }
    }

    controlledChanges = NO;
}

//Returns YES if we contain the handle
- (BOOL)containsHandleWithUID:(NSString *)targetHandleName
{
    return([self handleWithUID:targetHandleName] != nil);
}

//Return the handle if we contain it
- (AIEditorListHandle *)handleWithUID:(NSString *)targetHandleName
{
    NSEnumerator	*groupEnumerator;
    AIEditorListGroup	*group;
    NSEnumerator	*handleEnumerator;
    AIEditorListHandle	*handle;

    //Scan each group
    groupEnumerator = [list objectEnumerator];
    while((group = [groupEnumerator nextObject])){
        //Scan each handle
        handleEnumerator = [group handleEnumerator];
        while(handle = [handleEnumerator nextObject]){
            //Compare the handle names
            if([targetHandleName compare:[handle UID]] == 0) return(handle);
        }
    }

    return(nil);
}

//Return the group if we contain it
- (AIEditorListGroup *)groupWithUID:(NSString *)targetGroupName
{
    NSEnumerator	*groupEnumerator;
    AIEditorListGroup	*group;

    //Scan each group
    groupEnumerator = [list objectEnumerator];
    while((group = [groupEnumerator nextObject])){
        if([[group UID] compare:targetGroupName] == 0) return(group);
    }

    return(nil);
}


//For subclassers:
- (void)_addGroup:(AIEditorListGroup *)group{
    [list addObject:group];
    [[owner notificationCenter] postNotificationName:Editor_AddedObjectToCollection object:self userInfo:[NSDictionary dictionaryWithObject:group forKey:@"Object"]];
}

- (void)_moveGroup:(AIEditorListGroup *)group toIndex:(int)index{
    //If necessary, adjust the index to compensate for the group being removed, which will shift things up
    if([list indexOfObject:group] < index) index--;

    [list removeObject:group];
    [[owner notificationCenter] postNotificationName:Editor_RemovedObjectFromCollection object:self userInfo:[NSDictionary dictionaryWithObject:group forKey:@"Object"]];

    [list insertObject:group atIndex:index];
    [[owner notificationCenter] postNotificationName:Editor_AddedObjectToCollection object:self userInfo:[NSDictionary dictionaryWithObject:group forKey:@"Object"]];
}

- (void)_renameGroup:(AIEditorListGroup *)group to:(NSString *)name{
    [group setUID:name];
    [[owner notificationCenter] postNotificationName:Editor_RenamedObjectOnCollection object:self userInfo:[NSDictionary dictionaryWithObject:group forKey:@"Object"]];
}

- (void)_deleteGroup:(AIEditorListGroup *)group{
    [list removeObject:group];
    [[owner notificationCenter] postNotificationName:Editor_RemovedObjectFromCollection object:self userInfo:[NSDictionary dictionaryWithObject:group forKey:@"Object"]];
}

- (void)_addHandle:(AIEditorListHandle *)handle toGroup:(AIEditorListGroup *)group index:(int)index{
    [group addHandle:handle toIndex:index];
    [[owner notificationCenter] postNotificationName:Editor_AddedObjectToCollection object:self userInfo:[NSDictionary dictionaryWithObject:handle forKey:@"Object"]];
}

- (void)_moveHandle:(AIEditorListHandle *)handle toGroup:(AIEditorListGroup *)group index:(int)index{
    //If necessary, adjust the index to compensate for the handle being removed, which will shift things up
    if([handle containingGroup] == group && [group indexOfHandle:handle] < index) index--;

    [[handle containingGroup] removeHandle:handle];
    [[owner notificationCenter] postNotificationName:Editor_RemovedObjectFromCollection object:self userInfo:[NSDictionary dictionaryWithObject:handle forKey:@"Object"]];

    [group addHandle:handle toIndex:index];
    [[owner notificationCenter] postNotificationName:Editor_AddedObjectToCollection object:self userInfo:[NSDictionary dictionaryWithObject:handle forKey:@"Object"]];
}

- (void)_deleteHandle:(AIEditorListHandle *)handle{
    [[handle containingGroup] removeHandle:handle];
    [[owner notificationCenter] postNotificationName:Editor_RemovedObjectFromCollection object:self userInfo:[NSDictionary dictionaryWithObject:handle forKey:@"Object"]];
}

- (void)_renameHandle:(AIEditorListHandle *)handle to:(NSString *)name{
    [handle setUID:name];
    [[owner notificationCenter] postNotificationName:Editor_RenamedObjectOnCollection object:self userInfo:[NSDictionary dictionaryWithObject:handle forKey:@"Object"]];
}

@end
