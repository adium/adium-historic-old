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

@class AIHandle;
@protocol AIContentObject;

@interface AIListContact : AIListObject {
    NSMutableArray	*contentObjectArray;
    NSMutableDictionary	*statusDictionary;
    NSMutableArray	*handleArray;

    NSString		*serviceID;
    int			index;
}

- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID;
- (NSString *)serviceID;
- (NSString *)UIDAndServiceID;

//Contained Handles
//- (unsigned)handleCount;
//- (id)handleAtIndex:(unsigned)index;
- (NSEnumerator *)handleEnumerator;
- (void)addHandle:(AIHandle *)inHandle;
- (void)removeHandle:(AIHandle *)inHandle;
- (void)removeAllHandles;
- (int)numberOfHandles;

//Content
- (NSArray *)contentObjectArray;
- (void)addContentObject:(id <AIContentObject>)inObject;

//Status
- (AIMutableOwnerArray *)statusArrayForKey:(NSString *)inKey;

//Manual Ordering
- (int)index;
- (void)setIndex:(int)inIndex;

@end
