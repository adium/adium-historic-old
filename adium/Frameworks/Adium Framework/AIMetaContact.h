//
//  AIMetaContact.h
//  Adium XCode
//
//  Created by Adam Iser on Wed Jan 28 2004.

#import "AIListGroup.h"

@interface AIMetaContact : AIListContact {
	NSMutableArray			*objectArray;		//Objects we contain
	NSMutableDictionary		*statusCacheDict;	//Cache of the status of our contained objects
}

- (unsigned)count;
- (void)addObject:(AIListContact *)inObject;
- (NSEnumerator *)objectEnumerator;
- (id)objectAtIndex:(unsigned)index;
- (void)removeObject:(AIListContact *)inObject;
- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible;
- (NSArray *)containedObjects;

@end
