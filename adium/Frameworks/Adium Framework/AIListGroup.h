/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

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
