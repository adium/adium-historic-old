//
//  AIEditorBlockedCollection.m
//  Adium
//
//  Created by Adam Iser on Sun May 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEditorBlockedCollection.h"
#import "AIEditorListHandle.h"
#import "AIEditorListGroup.h"
#import "AIEditorListObject.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

@interface AIEditorBlockedCollection (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (AIEditorListGroup *)generateEditorListGroup;
@end

@implementation AIEditorBlockedCollection

- (BOOL)containsHandleWithUID:(NSString *)UID serviceID:(NSString *)serviceID
{
    return(NO);
}

- (NSString *)serviceID
{
    return(@"");
}

//
+ (AIEditorBlockedCollection *)blockedCollectionWithOwner:(id)inOwner;
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
    return(@"Blocked Contacts");
}

- (NSString *)subLabel{
    return(@"");
}

//Return a unique identifier
- (NSString *)UID{
    return(@"BlockedContacts");
}

//Return our icon description
- (NSImage *)icon{
    return([AIImageUtilities imageNamed:@"TrashMailboxLarge" forClass:[self class]]);
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
    return([[[AIEditorListGroup alloc] initWithUID:@"" temporary:NO] autorelease]);
}

@end

