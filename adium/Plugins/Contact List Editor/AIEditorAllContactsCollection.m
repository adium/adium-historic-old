//
//  AIEditorAllContactsCollection.m
//  Adium
//
//  Created by Adam Iser on Fri May 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEditorAllContactsCollection.h"
#import "AIEditorListHandle.h"
#import "AIEditorListGroup.h"
#import "AIEditorListObject.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"


@interface AIEditorAllContactsCollection (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (AIEditorListGroup *)generateEditorListGroup;
- (void)_processListGroup:(AIListGroup *)listGroup intoEditorGroup:(AIEditorListGroup *)editorGroup;
@end


@implementation AIEditorAllContactsCollection

//Return a collection for all contacts
+ (AIEditorAllContactsCollection *)allContactsCollectionWithOwner:(id)inOwner;
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//init
- (id)initWithOwner:(id)inOwner
{
    [super init];

    owner = [inOwner retain];
    list = [[self generateEditorListGroup] retain];

    return(self);
}

//Return our text description
- (NSString *)name{
    return(@"Adium Contact List");
}

- (BOOL)containsHandleWithUID:(NSString *)UID serviceID:(NSString *)serviceID
{
    return(NO);
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
}

//Delete an object from the collection
- (void)deleteObject:(AIEditorListObject *)inObject
{
}

//Rename an existing object
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName
{
}

//Move an existing object
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup
{
}


//Creates and returns the editor list (editor groups and handles)
- (AIEditorListGroup *)generateEditorListGroup
{
    AIEditorListGroup	*editorGroup = [[[AIEditorListGroup alloc] initWithUID:@"" temporary:NO] autorelease];

    //
    [self _processListGroup:[[owner contactController] contactList]
            intoEditorGroup:editorGroup];

    return(editorGroup);
}

- (void)_processListGroup:(AIListGroup *)listGroup intoEditorGroup:(AIEditorListGroup *)editorGroup
{
    NSEnumerator	*enumerator;
    AIListObject	*object;
    
    enumerator = [listGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIListGroup class]]){
            AIEditorListGroup	*newGroup;
            
            //Create the group and process its contents
            newGroup = [[[AIEditorListGroup alloc] initWithUID:[object UID] temporary:NO] autorelease];
            [editorGroup addObject:newGroup];
            [self _processListGroup:(AIListGroup *)object intoEditorGroup:newGroup];

        }else if([object isKindOfClass:[AIListContact class]]){
            AIEditorListHandle	*newHandle;

            //Create the handle and add it to the group
            newHandle = [[[AIEditorListHandle alloc] initWithServiceID:[(AIListContact *)object serviceID] UID:[object UID] temporary:NO] autorelease];
            [editorGroup addObject:newHandle];
        }
    }    
}

@end














