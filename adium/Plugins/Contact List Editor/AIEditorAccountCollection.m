//
//  AIEditorAccountCollection.m
//  Adium
//
//  Created by Adam Iser on Fri Mar 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEditorAccountCollection.h"
#import "AIEditorListHandle.h"
#import "AIEditorListGroup.h"
#import "AIEditorListObject.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

@interface AIEditorAccountCollection (PRIVATE)
- (id)initForAccount:(AIAccount *)inAccount;
- (AIEditorListGroup *)generateEditorListGroup;
@end

@implementation AIEditorAccountCollection

//Return a collection for the specified account
+ (AIEditorAccountCollection *)editorCollectionForAccount:(AIAccount *)inAccount
{
    return([[[self alloc] initForAccount:inAccount] autorelease]);    
}

//init
- (id)initForAccount:(AIAccount *)inAccount
{
    [super init];
    
    account = [inAccount retain];
    list = [[self generateEditorListGroup] retain];
    
    return(self);    
}

//Return our text description
- (NSString *)name{
    return([account accountDescription]);
}

//Return our icon description
- (NSImage *)icon{
    return([AIImageUtilities imageNamed:@"AllContacts" forClass:[self class]]);
}

//Return YES if this collection is enabled
- (BOOL)enabled{
    return([account contactListEditable]);
}

//Return an Editor List Group containing everything in this collection
- (AIEditorListGroup *)list{
    return(list);
}

//Add an object to the collection
- (void)addObject:(AIEditorListObject *)inObject
{
    if([inObject isKindOfClass:[AIEditorListHandle class]]){
        AIServiceType	*serviceType = [[account service] handleServiceType];
        
        //Add a new handle
        [account addHandleWithUID:[serviceType filterUID:[(AIEditorListHandle *)inObject UID]]
                      serverGroup:[[(AIEditorListHandle *)inObject containingGroup] UID]
                        temporary:NO];

    }else if([inObject isKindOfClass:[AIEditorListGroup class]]){
        //Not yet
        
    }
}

//Delete an object from the collection
- (void)deleteObject:(AIEditorListObject *)inObject
{
    if([inObject isKindOfClass:[AIEditorListHandle class]]){
        [account removeHandleWithUID:[inObject UID]];
        
    }else if([inObject isKindOfClass:[AIEditorListGroup class]]){
        //Not yet
    }
}

//Rename an existing object
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName
{
    if([inObject isKindOfClass:[AIEditorListHandle class]]){
        NSString	*handleUID = [[inObject UID] retain];
        NSString	*handleGroup = [[(AIEditorListHandle *)inObject containingGroup] UID];

        //Remove the handle, and re-add it with the new name
        [account removeHandleWithUID:handleUID];
        [account addHandleWithUID:handleUID
                      serverGroup:handleGroup
                        temporary:NO];

    }else if([inObject isKindOfClass:[AIEditorListGroup class]]){
        //Not yet
    }
}

//Move an existing object
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup
{
    if([inObject isKindOfClass:[AIEditorListHandle class]]){
        NSString	*handleUID = [[inObject UID] retain];

        //Remove the handle, and re-add it into the correct group
        [account removeHandleWithUID:handleUID];
        [account addHandleWithUID:handleUID serverGroup:[inGroup UID] temporary:NO];

    }else if([inObject isKindOfClass:[AIEditorListGroup class]]){
        //Not yet
    }
}


//Creates and returns the editor list (editor groups and handles)
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
            if(!editorGroup){
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

@end
