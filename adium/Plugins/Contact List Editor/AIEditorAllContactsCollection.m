//
//  AIEditorAllContactsCollection.m
//  Adium
//
//  Created by Adam Iser on Fri May 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContactListEditorPlugin.h"
#import "AIEditorAllContactsCollection.h"
#import "AIEditorListHandle.h"
#import "AIEditorListGroup.h"
#import "AIEditorListObject.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"


@interface AIEditorAllContactsCollection (PRIVATE)
- (id)initWithOwner:(id)inOwner plugin:(id)inPlugin;
- (AIEditorListGroup *)generateEditorListGroup;
- (void)_processCollectionGroup:(AIEditorListGroup *)collectionGroup intoEditorGroup:(AIEditorListGroup *)editorGroup;
- (AIEditorListHandle *)_handleNamed:(NSString *)name inGroup:(AIEditorListGroup *)group;
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
    [super init];

    plugin = [inPlugin retain];
    owner = [inOwner retain];
    list = nil;

    [[owner notificationCenter] addObserver:self selector:@selector(collectionAddedObject:) name:Editor_AddedObjectToCollection object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(collectionRemovedObject:) name:Editor_RemovedObjectFromCollection object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(collectionRenamedObject:) name:Editor_RenamedObjectOnCollection object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(collectionContentChanged:) name:Editor_CollectionContentChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(collectionArrayChanged:) name:Editor_CollectionArrayChanged object:nil];
    
    return(self);
}

//Return our text description
- (NSString *)name{
    return(@"Adium Contact List");
}

//Does our list contain the handle?
- (BOOL)containsHandleWithUID:(NSString *)UID serviceID:(NSString *)serviceID
{
    if([self _handleNamed:UID inGroup:list]){
        return(YES);
    }else{
        return(NO);
    }
}

- (NSString *)subLabel{
    return(@"All Avaliable Contacts");
}

- (NSString *)collectionDescription{
    return(@"Adium Contact List");
}

- (BOOL)showOwnershipColumns{
    return(YES);
}
- (BOOL)showCustomEditorColumns{
    return(YES);
}

- (BOOL)includeInOwnershipColumn
{
    return(NO);
}

//Return a unique identifier
- (NSString *)UID{
    return(@"AdiumContactList");
}

- (NSString *)serviceID
{
    return(@"");
}

//Return our icon description
- (NSImage *)icon{
    return([AIImageUtilities imageNamed:@"AllContacts" forClass:[self class]]);
}

//Return YES if this collection is enabled
- (BOOL)enabled{
    return(YES);
}

//Return an Editor List Group containing everything in this collection
- (AIEditorListGroup *)list{
    return(list);
}

//Add an object to the collection
- (void)addObject:(AIEditorListObject *)inObject
{
    if([inObject isKindOfClass:[AIEditorListHandle class]]){
        NSString		*groupName = [[inObject containingGroup] UID];
        BOOL			serviceIDSet = NO;
        NSEnumerator		*enumerator;
        id <AIEditorCollection>	collection;

        //Add the object to all available collections (for now)
        enumerator = [[plugin collectionsArray] objectEnumerator];
        while((collection = [enumerator nextObject])){
            if([collection includeInOwnershipColumn] && [collection enabled]){
                AIEditorListGroup	*group;
                
                //Correctly set the object's service ID (for now)
                if(!serviceIDSet){
                    AIServiceType	*serviceType = [[owner accountController] serviceTypeWithID:[collection serviceID]];
                    
                    [(AIEditorListHandle *)inObject setServiceID:[serviceType identifier]];	//Set the correct serviceID
                    [inObject setUID:[serviceType filterUID:[inObject UID]]];			//Correctly filter the UID
                    serviceIDSet = YES;
                }
                
                //Get a local instance of the containing group
                group = [plugin groupNamed:groupName onCollection:collection];
                if(!group){ //If the group doesn't exist, create it
                    group = [plugin createGroupNamed:groupName onCollection:collection temporary:NO];
                }

                //Add the handle to this collection
                [plugin createHandleNamed:[inObject UID] inGroup:group onCollection:collection temporary:NO];
            }
        }
    }
}

//Delete an object from the collection
- (void)deleteObject:(AIEditorListObject *)inObject
{
    BOOL			isGroup = [inObject isKindOfClass:[AIEditorListGroup class]];
    NSEnumerator		*enumerator;
    id <AIEditorCollection>	collection;
    
    //Delete the object from all owning collections
    enumerator = [[plugin collectionsArray] objectEnumerator];
    while((collection = [enumerator nextObject])){
        if([collection includeInOwnershipColumn] && [collection enabled]){
            AIEditorListObject	*object;

            //Get the instance of the object on this collection
            if(!isGroup){
                object = [plugin handleNamed:[inObject UID] onCollection:collection];
            }else{
                object = [plugin groupNamed:[inObject UID] onCollection:collection];
            }

            //Remove the object
            if(object){
                [plugin deleteObject:object fromCollection:collection];
            }
        }
    }
}

//Rename an existing object
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName
{
    BOOL			isGroup = [inObject isKindOfClass:[AIEditorListGroup class]];
    NSEnumerator		*enumerator;
    id <AIEditorCollection>	collection;

    //Rename the object on all owning collections
    enumerator = [[plugin collectionsArray] objectEnumerator];
    while((collection = [enumerator nextObject])){
        if([collection includeInOwnershipColumn] && [collection enabled]){
            AIEditorListObject	*object;

            //Get the instance of the object on this collection
            if(!isGroup){
                object = [plugin handleNamed:[inObject UID] onCollection:collection];
            }else{
                object = [plugin groupNamed:[inObject UID] onCollection:collection];
            }

            //Rename the object
            if(object){
                [plugin renameObject:object onCollection:collection to:newName];
            }
        }
    }
}

//Move an existing object
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup
{
    NSString			*groupName = [inGroup UID];
    NSEnumerator		*enumerator;
    id <AIEditorCollection>	collection;
    AIEditorListHandle		*handle;
    AIEditorListGroup		*group;

    if([inObject isKindOfClass:[AIEditorListHandle class]]){

        //Move the Handle on all owning collections
        enumerator = [[plugin collectionsArray] objectEnumerator];
        while((collection = [enumerator nextObject])){
            if([collection includeInOwnershipColumn] && [collection enabled]){
                //Get the instance of the handle on this collection
                handle = [plugin handleNamed:[inObject UID] onCollection:collection];

                //Get a local instance of the containing group
                group = [plugin groupNamed:groupName onCollection:collection];
                if(!group){ //If the group doesn't exist, create it
                    group = [plugin createGroupNamed:groupName onCollection:collection temporary:NO];
                }

                //Move the handle
                if(handle){
                    [plugin moveObject:handle fromCollection:collection toGroup:group collection:collection];
                }
            }
        }

        //Move the handle on our list (to avoid regeneration of our editor list group)
        handle = [plugin handleNamed:[inObject UID] onCollection:self];
        group = [plugin groupNamed:groupName onCollection:self];

        [handle retain];
        [[handle containingGroup] removeObject:handle];
        [group addObject:handle];
        [handle release];
    }

}


//Creates and returns the editor list (editor groups and handles)
- (AIEditorListGroup *)generateEditorListGroup
{
    AIEditorListGroup		*editorGroup;
    NSEnumerator		*enumerator;
    id <AIEditorCollection>	collection;

    NSLog(@"Rebuilding list");
    
    //Create the editor group
    editorGroup = [[[AIEditorListGroup alloc] initWithUID:@"" temporary:NO] autorelease];

    //Process the ownership enabled collections' groups
    enumerator = [[plugin collectionsArray] objectEnumerator];
    while((collection = [enumerator nextObject])){
        if([collection includeInOwnershipColumn] && [collection enabled]){
            [self _processCollectionGroup:[collection list] intoEditorGroup:editorGroup];
        }
    }

    return(editorGroup);
}

- (void)_processCollectionGroup:(AIEditorListGroup *)collectionGroup intoEditorGroup:(AIEditorListGroup *)editorGroup
{
    NSEnumerator	*enumerator;
    AIEditorListObject	*object;
    
    enumerator = [collectionGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIEditorListGroup class]]){
            AIEditorListGroup	*newGroup = nil;
            
            //Create the group (if necessary) and process its contents
            newGroup = (AIEditorListGroup *)[editorGroup objectNamed:[object UID] isGroup:YES];
            if(!newGroup){
                newGroup = [[[AIEditorListGroup alloc] initWithUID:[object UID] temporary:NO] autorelease];
                [editorGroup addObject:newGroup];
            }
            [self _processCollectionGroup:(AIEditorListGroup *)object intoEditorGroup:newGroup];

        }else if([object isKindOfClass:[AIEditorListHandle class]]){
            AIEditorListHandle	*newHandle;

            //Create the handle and add it to the group (if necessary)
            if(![editorGroup objectNamed:[object UID] isGroup:NO]){
                newHandle = [[[AIEditorListHandle alloc] initWithServiceID:[(AIEditorListHandle *)object serviceID] UID:[object UID] temporary:NO] autorelease];
                [editorGroup addObject:newHandle];
            }
            
        }
    }    
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



//A collection's content has changed
- (void)collectionContentChanged:(NSNotification *)notification
{
    id <AIEditorCollection>	collection = [notification object];

    if([collection includeInOwnershipColumn] && collection != self){        
        //Rebuild our content list
        NSLog(@"collectionContentChanged (All contacts collection)");

        [list release];
        list = [[self generateEditorListGroup] retain];

        //Let the contact list know our handles changed
        [[owner notificationCenter] postNotificationName:Editor_CollectionContentChanged object:self];
    }
}

- (void)collectionArrayChanged:(NSNotification *)notification
{
    //Rebuild our content list
    [list release];
    list = [[self generateEditorListGroup] retain];

    //Let the contact list know our handles changed
    [[owner notificationCenter] postNotificationName:Editor_CollectionContentChanged object:self];
}

- (void)collectionAddedObject:(NSNotification *)notification
{
    id <AIEditorCollection>	collection = [notification object];
    AIEditorListHandle		*object = [[notification userInfo] objectForKey:@"Object"];
    BOOL			isGroup = [object isKindOfClass:[AIEditorListGroup class]];

    NSLog(@"collectionAddedObject: %@",[object UID]);

    if([collection includeInOwnershipColumn] && collection != self){
        
        //If object isn't already on our list
        if(!isGroup && ![self containsHandleWithUID:[object UID] serviceID:[collection serviceID]]){
            //Rebuild our list (It'd be faster to just add the new handle here, however)
            [list release];
            list = [[self generateEditorListGroup] retain];
        }
    }
}

- (void)collectionRemovedObject:(NSNotification *)notification
{
    id <AIEditorCollection>	collection = [notification object];
    AIEditorListHandle		*handle = [[notification userInfo] objectForKey:@"Object"];
    
    NSLog(@"collectionRemovedObject: %@",[[[notification userInfo] objectForKey:@"Object"] UID]);
    if([collection includeInOwnershipColumn] && collection != self){
        NSString	*serviceID = [collection serviceID];
        NSString	*handleUID = [handle UID];
        NSEnumerator	*enumerator;

        //Scan all the collections
        enumerator = [[plugin collectionsArray] objectEnumerator];
        while((collection = [enumerator nextObject]) && (![collection includeInOwnershipColumn] || ![collection containsHandleWithUID:handleUID serviceID:serviceID]));

        //If the object is no longer owned by any of the collections, remove it from our list
        if(!collection){
            AIEditorListHandle	*ourHandle;
            NSLog(@"no more %@",handleUID);

            //Remove the handle from our list
            ourHandle = [self _handleNamed:handleUID inGroup:list];
            [[ourHandle containingGroup] removeObject:ourHandle];

            //Let the contact list editor know our handles changed
            [[owner notificationCenter] postNotificationName:Editor_CollectionContentChanged object:self];
        }else{
            NSLog(@"%@ still in %@",handleUID,[collection name]);
        }
    }
}

- (void)collectionRenamedObject:(NSNotification *)notification
{
    //Rebuild our list (for now)
    [list release];
    list = [[self generateEditorListGroup] retain];

    /*    id <AIEditorCollection>	collection = [notification object];
    NSLog(@"collectionRenamedObject: %@",[[[notification userInfo] objectForKey:@"Object"] UID]);
    if([collection includeInOwnershipColumn] && collection != self){
        //treat newly named object as a new one... shouldn't I do this anyway?
    }*/
}


//A collection's status has changed
- (void)collectionStatusChanged:(NSNotification *)notification
{
    //Redisplay our content view
    NSLog(@"collectionStatusChanged (All contacts collection)");
}


@end














