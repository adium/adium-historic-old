//
//  AIMetaContact.h
//  Adium XCode
//
//  Created by Adam Iser on Wed Jan 28 2004.

#import "AIListGroup.h"

@interface AIMetaContact : AIListContact {
	NSMutableArray		*objectArray;
}

- (unsigned)count;
- (void)addObject:(AIListContact *)inObject;
- (NSEnumerator *)objectEnumerator;
- (id)objectAtIndex:(unsigned)index;
- (void)removeObject:(AIListContact *)inObject;
- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible;
- (NSArray *)containedObjects;
- (void)_updateStatusArrayDictionaryWithObject:(id)inObject andOwner:(id)inOwner forKey:(NSString *)key;
@end
