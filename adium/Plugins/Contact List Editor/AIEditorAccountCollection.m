//
//  AIEditorAccountCollection.m
//  Adium
//
//  Created by Adam Iser on Fri Mar 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContactListEditorPlugin.h"
#import "AIEditorAccountCollection.h"
#import "AIEditorListHandle.h"
#import "AIEditorListGroup.h"
#import "AIEditorListObject.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

@interface AIEditorAccountCollection (PRIVATE)
- (id)initForAccount:(AIAccount *)inAccount withOwner:(id)inOwner;
- (AIEditorListGroup *)generateEditorListGroup;
- (AIEditorListHandle *)_handleNamed:(NSString *)name inGroup:(AIEditorListGroup *)group;
- (AIEditorListGroup *)_groupNamed:(NSString *)name;
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
    [super init];

    owner = [inOwner retain];
    account = [inAccount retain];
    list = [[self generateEditorListGroup] retain];
    controlledChanges = NO;

    //Observe our account's changes
    [[owner notificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_StatusChanged object:account];
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
    [owner release];
    [account release];
    [list release];
    [super dealloc];
}

//Large black drawer label
- (NSString *)name{
    return([account accountDescription]); //Return our account's description
}

//Small gray drawer text label
- (NSString *)subLabel{
    if([account availableHandles] != nil){ //Let the user know this is a server-side list
        return([NSString stringWithFormat:@"%@ Server-Side List",[account serviceID]]);
    }else{
        return([NSString stringWithFormat:@"%@ (Unavailable)",[account serviceID]]);
    }
}

//Used to store group collapse/expand state
- (NSString *)UID{
    return([account UID]); //Our UID is just the account UID, this is unique enough
}

//Display ownership/checkbox column?
- (BOOL)showOwnershipColumns{
    return(NO);
}

//Display custom columns (alias, ...)?
//We really shouldn't display these, since this information is not stored server-side.  But it's convenient to have those columns, and not too big of a deal :)
- (BOOL)showCustomEditorColumns{
    return(YES); 
}

//Does this collection get a check box in the ownership column?
- (BOOL)includeInOwnershipColumn{
    return(YES);
}

//Use our accounts large icon
- (NSImage *)icon{
    return([AIImageUtilities imageNamed:@"AccountLarge" forClass:[self class]]);
}

//All handles are of the service type of our account
- (NSString *)serviceID{
    return([account serviceID]);
}

//Window title when collection is selected
- (NSString *)collectionDescription{
    return([NSString stringWithFormat:@"%@'s Server-Side Contacts",[account accountDescription]]);
}

//Return YES if this collection is enabled
- (BOOL)enabled{
    return([account contactListEditable]);
}

//Return an Editor List Group containing everything in this collection
- (AIEditorListGroup *)list{
    return(list);
}

//Quickly check if a handle with the specified UID is on our account
- (BOOL)containsHandleWithUID:(NSString *)UID serviceID:(NSString *)serviceID
{
    return([[account availableHandles] objectForKey:UID] != nil);
}

- (AIEditorListHandle *)handleWithUID:(NSString *)UID serviceID:(NSString *)serviceID
{
    return([self _handleNamed:UID inGroup:list]);
}

- (AIEditorListGroup *)groupWithUID:(NSString *)UID
{
    return([self _groupNamed:UID]);
}


//Add an object to our account
- (void)addObject:(AIEditorListObject *)inObject
{
    controlledChanges = YES;
    
    if([inObject isKindOfClass:[AIEditorListHandle class]]){        
        //Add a new handle
        [account addHandleWithUID:[(AIEditorListHandle *)inObject UID]
                      serverGroup:[[(AIEditorListHandle *)inObject containingGroup] UID]
                        temporary:NO];

    }else if([inObject isKindOfClass:[AIEditorListGroup class]]){
        [account addServerGroup:[inObject UID]];
        
    }

    controlledChanges = NO;
}

//Delete an object from our account
- (void)deleteObject:(AIEditorListObject *)inObject
{
    controlledChanges = YES;
    
    if([inObject isKindOfClass:[AIEditorListHandle class]]){
        [account removeHandleWithUID:[(AIEditorListHandle *)inObject UID]];
        
    }else if([inObject isKindOfClass:[AIEditorListGroup class]]){
        [account removeServerGroup:[inObject UID]];

    }

    controlledChanges = NO;
}

//Rename an existing object
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName
{
    controlledChanges = YES;

    if([inObject isKindOfClass:[AIEditorListHandle class]]){
        NSString	*handleGroup = [[(AIEditorListHandle *)inObject containingGroup] UID];

        //Remove the handle, and re-add it with the new name
        [account removeHandleWithUID:[inObject UID]];
        [account addHandleWithUID:newName
                      serverGroup:handleGroup
                        temporary:NO];

    }else if([inObject isKindOfClass:[AIEditorListGroup class]]){
        [account renameServerGroup:[inObject UID] to:newName];

    }

    controlledChanges = NO;
}

//Move an existing object
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup
{
    controlledChanges = YES;

    if([inObject isKindOfClass:[AIEditorListHandle class]]){
        NSString	*handleUID = [[[(AIEditorListHandle *)inObject UID] retain] autorelease];

        //Remove the handle, and re-add it into the correct group
        [account removeHandleWithUID:handleUID];
        [account addHandleWithUID:handleUID serverGroup:[inGroup UID] temporary:NO];

    }else if([inObject isKindOfClass:[AIEditorListGroup class]]){
        //Not yet
    }

    controlledChanges = NO;
}

//Create and return the editor list (editor groups and handles)
- (AIEditorListGroup *)generateEditorListGroup
{
    NSEnumerator	*enumerator;
    AIHandle		*handle;
    AIEditorListGroup	*listGroup;
    NSMutableDictionary	*groupDict;

    //Create the main list group
    listGroup = [[[AIEditorListGroup alloc] initWithUID:@"" temporary:NO] autorelease];

    //Set up a dictionary to hold our subgroups
    groupDict = [[[NSMutableDictionary alloc] init] autorelease];
    
    //Process the handles
    enumerator = [[[account availableHandles] allValues] objectEnumerator];
    while((handle = [enumerator nextObject])){
        NSString		*serverGroup = [handle serverGroup];
        AIEditorListGroup	*editorGroup;
        AIEditorListHandle	*editorHandle;

        if(![handle temporary]){
            //Make sure a group exists for this handle
            editorGroup = [groupDict objectForKey:serverGroup];
            if(!editorGroup){ //Create and add the group
                editorGroup = [[[AIEditorListGroup alloc] initWithUID:serverGroup temporary:NO] autorelease];
                [listGroup addObject:editorGroup];
                [groupDict setObject:editorGroup forKey:serverGroup];
            }

            //Create the handle and add it to the group
            editorHandle = [[[AIEditorListHandle alloc] initWithServiceID:[handle serviceID] UID:[handle UID] temporary:NO] autorelease];
            [editorGroup addObject:editorHandle];
        }
    }

    return(listGroup);
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
    //The controlledChanges variable is used to make things faster by avoiding unnecessary regeneration of our editor list group.  Before making changes, we set controlledChanges to the number of accountHandlesChanged messages that are expected.  If more changes are received than expected, or changes are received when none are expected, we regenerate the list.  Yah, it's a messy hack, but it give a huge speed boost that is worth it in the long run.
    
    if(!controlledChanges){
        NSLog(@"accountHandlesChanged / generateEditorListGroup");
        //Regenerate our list
        [list release];
        list = [[self generateEditorListGroup] retain];

        //Let the contact list know our handles changed
        [[owner notificationCenter] postNotificationName:Editor_CollectionContentChanged object:self];
    }else{
        NSLog(@"(ignored)accountHandlesChanged / generateEditorListGroup");
    }
}

//Our account properties have changed
- (void)accountPropertiesChanged:(NSNotification *)notification
{
    //Let the contact list know our name changed
    [[owner notificationCenter] postNotificationName:Editor_CollectionStatusChanged object:self];
}

//Recursively scan for a handle on our list
- (AIEditorListHandle *)_handleNamed:(NSString *)name inGroup:(AIEditorListGroup *)group
{
    NSEnumerator	*enumerator;
    AIEditorListObject	*object;

    //Scan all objects in this group
    enumerator = [group objectEnumerator];
    while(object = [enumerator nextObject]){
        if([object isKindOfClass:[AIEditorListHandle class]]){ //Compare the handle names
            if([name compare:[object UID]] == 0){
                return((AIEditorListHandle *)object);
            }

        }else if([object isKindOfClass:[AIEditorListGroup class]]){ //Scan the subgroup
            if((object = [self _handleNamed:name inGroup:(AIEditorListGroup *)object])){
                return((AIEditorListHandle *)object);
            }
        }
    }

    return(nil);
}

//Scan for a group on our list
- (AIEditorListGroup *)_groupNamed:(NSString *)name
{
    NSEnumerator	*enumerator;
    AIEditorListGroup	*group;

    //Look for this group
    enumerator = [list objectEnumerator];
    while(group = [enumerator nextObject]){
        if([name caseInsensitiveCompare:[group UID]] == 0){
            return(group);
        }
    }

    return(nil);
}

@end









