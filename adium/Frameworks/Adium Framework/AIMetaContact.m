//
//  AIMetaContact.m
//  Adium XCode
//
//  Created by Adam Iser on Wed Jan 28 2004.
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
//
- (void)removeObject:(AIListContact *)inObject
{
	if([objectArray containsObject:inObject]){
		[inObject setContainingGroup:nil];
		[objectArray removeObject:inObject];
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
- (unsigned)count
{
	return([objectArray count]);
}

//Called when the visibility of an object in this group changes
- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible
{

}

//Observe changes in the list objects we contain
- (void)listObject:(AIListObject *)inObject didSetStatusObject:(id)value forKey:(NSString *)key
{
	//Update the status array, creating it if necessary
	[self _updateStatusArrayDictionaryWithObject:[inObject statusObjectForKey:key] andOwner:inObject forKey:key];
}

//Quickly retrieve a status key for this object
- (id)statusObjectForKey:(NSString *)key
{
	return ([[statusArrayDictionary objectForKey:key] objectValue]);
}
- (int)integerStatusObjectForKey:(NSString *)key
{
	AIMutableOwnerArray *array = [statusArrayDictionary objectForKey:key];
    return(array ? [array intValue] : 0);
}
- (double)doubleStatusObjectForKey:(NSString *)key
{
	AIMutableOwnerArray *array = [statusArrayDictionary objectForKey:key];
    return(array ? [array doubleValue] : 0);
}
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key
{
	return ([[statusArrayDictionary objectForKey:key] date]);	
}

//Access to the status array for this object

 //Handled by AIListObject now
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

//Update the status array, creating it if necessary
- (void)_updateStatusArrayDictionaryWithObject:(id)inObject andOwner:(id)inOwner forKey:(NSString *)key
{
	AIMutableOwnerArray *array = [statusArrayDictionary objectForKey:key];
	if(!array){
		array = [[AIMutableOwnerArray alloc] init];
		[statusArrayDictionary setObject:array forKey:key];
		[array release];
	}
	[array setObject:inObject withOwner:inOwner];
}

@end
