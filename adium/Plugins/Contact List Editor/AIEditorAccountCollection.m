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
#import "AIEditorAccountCollection.h"
#import "AIEditorListHandle.h"
#import "AIEditorListGroup.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

@interface AIEditorAccountCollection (PRIVATE)
- (id)initForAccount:(AIAccount *)inAccount withOwner:(id)inOwner;
- (void)generateEditorListArray;
@end

@implementation AIEditorAccountCollection

//Return a collection for the specified account
+ (AIEditorAccountCollection *)editorCollectionForAccount:(AIAccount *)inAccount withOwner:(id)inOwner
{
    return([[[self alloc] initForAccount:inAccount withOwner:inOwner] autorelease]);    
}

//init
- (id)initForAccount:(AIAccount *)inAccount withOwner:(id)inOwner
{
    [super initWithOwner:inOwner];

    //init
    account = [inAccount retain];
    sortMode = AISortByName;

    //Generate our list
    [self generateEditorListArray];

    //Observe our account's changes
    [[owner notificationCenter] addObserver:self selector:@selector(accountPropertiesChanged:) name:Account_PropertiesChanged object:account];
    [[owner notificationCenter] addObserver:self selector:@selector(accountHandlesChanged:) name:Account_HandlesChanged object:account];
    
    return(self);    
}

//dealloc
- (void)dealloc
{
    //Stop observing
    [[owner notificationCenter] removeObserver:self];

    //Cleanup
    [account release];
    [super dealloc];
}

//Large black drawer label
- (NSString *)name{
    return([account accountDescription]); //Return our account's description
}
- (NSString *)UID{
    return([account UID]); //Our UID is just the account UID, this is unique enough
}
- (BOOL)showOwnershipColumns{
    return(NO);
}
- (BOOL)showIndexColumn{
    return(NO);
}
- (BOOL)showCustomEditorColumns{
    return(YES); //We really shouldn't display these, since this information is not stored server-side.  But it's convenient to have those columns, and not too big of a deal :)
}
- (BOOL)includeInOwnershipColumn{
    return(YES);
}
- (NSImage *)icon{
    return([AIImageUtilities imageNamed:@"AccountLarge" forClass:[self class]]); //Use our accounts icon
}
- (NSString *)serviceID{
    return([account serviceID]); //All handles are of the service type of our account
}
- (NSString *)collectionDescription{
    return([NSString stringWithFormat:@"%@'s Contacts",[account accountDescription]]);
}
- (BOOL)enabled{
    return([account contactListEditable]);
}

//Quickly check if a handle with the specified UID is on our account.  For accounts we can figure this out quicker than the default method in AIEditorCollection!
- (BOOL)containsHandleWithUID:(NSString *)targetHandleName
{
    return([[account availableHandles] objectForKey:targetHandleName] != nil);
}

//We override these functions to filter contact names the user enters
- (AIEditorListHandle *)addHandleNamed:(NSString *)inName inGroup:(AIEditorListGroup *)group index:(int)index temporary:(BOOL)temporary
{
    return([super addHandleNamed:[[[account service] handleServiceType] filterUID:inName]
                         inGroup:group
                           index:index
                       temporary:temporary]);
}

- (void)renameHandle:(AIEditorListHandle *)inHandle to:(NSString *)newName
{
    [super renameHandle:inHandle
                     to:[[[account service] handleServiceType] filterUID:newName]];
}

//Add the group to our account
- (void)_addGroup:(AIEditorListGroup *)group
{
    [account addServerGroup:[group UID]];    
    [super _addGroup:group];
}

//Rename on the account
- (void)_renameGroup:(AIEditorListGroup *)group to:(NSString *)name
{
    [account renameServerGroup:[group UID] to:name];
    [super _renameGroup:group to:name];
}

//Delete from the account
- (void)_deleteGroup:(AIEditorListGroup *)group
{
    [account removeServerGroup:[group UID]];
    [super _deleteGroup:group];
}

//Add handle to account
- (void)_addHandle:(AIEditorListHandle *)handle toGroup:(AIEditorListGroup *)group index:(int)index
{    
    [account addHandleWithUID:[handle UID] serverGroup:[group UID] temporary:NO];
    [super _addHandle:handle toGroup:group index:index];
}

- (void)_moveHandle:(AIEditorListHandle *)handle toGroup:(AIEditorListGroup *)group index:(int)index
{
    if([handle containingGroup] != group){
        [account removeHandleWithUID:[handle UID]];
        [account addHandleWithUID:[handle UID] serverGroup:[group UID] temporary:NO];
    }

    [super _moveHandle:handle toGroup:group index:index];
}

//Delete handle from account
- (void)_deleteHandle:(AIEditorListHandle *)handle
{
    [account removeHandleWithUID:[handle UID]];
    [super _deleteHandle:handle];
}

//Rename handle on the account
- (void)_renameHandle:(AIEditorListHandle *)handle to:(NSString *)name
{
    NSString	*handleGroup = [[handle containingGroup] UID];

    //Remove the handle, and re-add it with the new name
    [account removeHandleWithUID:[handle UID]];
    [account addHandleWithUID:name serverGroup:handleGroup temporary:NO];

    //
    [super _renameHandle:handle to:name];
}

//Create the editor list (editor groups and handles)
- (void)generateEditorListArray
{
    NSEnumerator	*enumerator;
    AIHandle		*handle;
    NSMutableDictionary	*tempGroupDict;

    //Create the main list array
    [list release];
    list = [[NSMutableArray alloc] init];

    //Set up a temporary dictionary to hold our subgroups
    tempGroupDict = [[[NSMutableDictionary alloc] init] autorelease];
    
    //Process the handles
    enumerator = [[[account availableHandles] allValues] objectEnumerator];
    while((handle = [enumerator nextObject])){
        NSString		*serverGroup = [handle serverGroup];
        AIEditorListGroup	*editorGroup;
        AIEditorListHandle	*editorHandle;

        if(![handle temporary]){
            //Make sure a group exists for this handle
            editorGroup = [tempGroupDict objectForKey:serverGroup];
            if(!editorGroup){ //Create and add the group
                editorGroup = [[[AIEditorListGroup alloc] initWithUID:serverGroup temporary:NO] autorelease];
                [editorGroup setOrderIndex:[[owner contactController] orderIndexOfKey:serverGroup]];
                [list addObject:editorGroup];
                [tempGroupDict setObject:editorGroup forKey:serverGroup];
            }

            //Create the handle and add it to the group
            editorHandle = [[[AIEditorListHandle alloc] initWithUID:[handle UID] serviceID:[self serviceID] temporary:NO] autorelease];
            [editorGroup addHandle:editorHandle];
        }
    }

    [self sortUsingMode:[self sortMode]];
}

//Our account's status changed
- (void)accountStatusChanged:(NSNotification *)notification
{
    //Let the contact list know our enabled state changed
    [[owner notificationCenter] postNotificationName:Editor_CollectionStatusChanged object:self];
}

//Our account's handles changed
- (void)accountHandlesChanged:(NSNotification *)notification
{
    if(!controlledChanges){
        //Regenerate our list
        [self generateEditorListArray];

        //Let the contact list know our handles changed
        [[owner notificationCenter] postNotificationName:Editor_CollectionContentChanged object:self];
    }
}

//Our account properties have changed
- (void)accountPropertiesChanged:(NSNotification *)notification
{
    //Let the contact list know our name changed
    [[owner notificationCenter] postNotificationName:Editor_CollectionStatusChanged object:self];
}

@end
