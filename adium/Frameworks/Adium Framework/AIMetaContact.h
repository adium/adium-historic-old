//
//  AIMetaContact.h
//  Adium XCode
//
//  Created by Adam Iser on Wed Jan 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

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

@end
