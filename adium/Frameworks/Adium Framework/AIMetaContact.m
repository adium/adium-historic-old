//
//  AIMetaContact.m
//  Adium XCode
//
//  Created by Adam Iser on Wed Jan 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIMetaContact.h"


@implementation AIMetaContact

- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID
{
	[super initWithUID:inUID serviceID:inServiceID];
	
	objectArray = [[NSMutableArray alloc] init];
	
	return(self);
}

//
- (void)dealloc
{
	[objectArray release];
	
	[super dealloc];
}

//
- (void)addObject:(AIListContact *)inObject
{
	if(![objectArray containsObject:inObject]){
		[inObject setContainingGroup:(AIListGroup *)self];
		[objectArray addObject:inObject];
	}
}

//Return an enumerator of our contents
- (NSEnumerator *)objectEnumerator
{
    return([objectArray objectEnumerator]);
}

//Retrieve an object by index
- (id)objectAtIndex:(unsigned)index
{	
	
    return([objectArray objectAtIndex:index]);
}

- (NSArray *)containedObjects
{
	return(objectArray);
}

//
- (void)removeObject:(AIListContact *)inObject
{
	if([objectArray containsObject:inObject]){
		[inObject setContainingGroup:nil];
		[objectArray removeObject:inObject];
	}
}

//
- (unsigned)count
{
	return([objectArray count]);
}

//Called when the visibility of an object in this group changes
- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible
{

}

//Access to the status array for this object
- (AIMutableOwnerArray *)statusArrayForKey:(NSString *)inKey
{
    AIMutableOwnerArray	*array = [[AIMutableOwnerArray alloc] init];
    NSEnumerator		*enumerator = [objectArray objectEnumerator];
    AIListContact		*contact;
	
    //Merge the status of our contained objects  
    while(contact = [enumerator nextObject]){
		[array setObject:[contact statusObjectForKey:inKey] withOwner:contact];
    }
	
    return([array autorelease]);
}

//
//- (NSString *)displayName
//{
//    return([[super displayName] stringByAppendingFormat:@" [%i]",[objectArray count]]);
//}

- (void)sortListObject:(AIListObject *)inObject sortController:(AISortController *)sortController
{
	NSLog(@"sortListObject:%@ sent to meta contact %@",[inObject displayName],[self displayName]); 
}

//Returns our desired placement within a group
- (float)orderIndex
{
	return([[objectArray objectAtIndex:0] orderIndex]);
}

//Alter the placement of this object in a group (PRIVATE: These are for AIListGroup ONLY)
- (void)setOrderIndex:(float)inIndex
{
	NSEnumerator	*enumerator = [objectArray objectEnumerator];
	AIListObject	*object;
	
	while(object = [enumerator nextObject]){
		[object setOrderIndex:inIndex];
	}
}

@end
