//
//  AIListGroup.h
//  Adium
//
//  Created by Adam Iser on Fri Mar 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIListObject.h"

@protocol AIListSortController;

@interface AIListGroup : AIListObject {
    NSMutableArray    	*objectArray;		//Manual ordered array of contents
    NSMutableArray    	*sortedObjectArray;	//Dynamically sorted array of contents
    int			sortedCount;		//The number of visible buddies in the sorted array
    BOOL		expanded;
//    int			index;
}

- (NSString *)displayName;

//Manual Ordering
/*- (int)index;
- (void)setIndex:(int)inIndex;*/

//Contained Objects
- (NSEnumerator *)objectEnumerator;
- (id)objectAtIndex:(unsigned)index;

//Expanded State
- (void)setExpanded:(BOOL)inExpanded;
- (BOOL)isExpanded;

//Sorting
- (unsigned)sortedCount;
- (id)sortedObjectAtIndex:(unsigned)index;
- (void)sortGroupAndSubGroups:(BOOL)subGroups sortController:(id <AIListSortController>)sortController;

//Editing
- (void)addObject:(AIListObject *)inObject;
- (void)insertObject:(AIListObject *)inObject atIndex:(int)index;
- (void)replaceObject:(AIListObject *)oldObject with:(AIListObject *)newObject;
- (void)removeObject:(AIListObject *)inObject;
- (int)indexOfObject:(AIListObject *)inObject;
- (void)removeAllObjects;

@end
