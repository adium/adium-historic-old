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

typedef enum {
    Highest_Priority = 0,
    Medium_Priority = 5,
    Lowest_Priority = 10
} PriorityLevel;

@interface AIMutableOwnerArray : NSObject {
    NSMutableArray	*contentArray;
    NSMutableArray	*ownerArray;
	
	NSMutableArray *contentSubArray[11];
	NSMutableArray *ownerSubArray[11];    
}

- (void)setObject:(id)anObject withOwner:(id)inOwner;
- (void)setObject:(id)anObject withOwner:(id)inOwner priorityLevel:(int)priority;
- (unsigned)count;
- (BOOL)containsAnyIntegerValueOf:(int)inValue;
- (NSColor *)averageColor;
- (id)objectAtIndex:(unsigned)index;
- (id)objectWithOwner:(id)inOwner;
- (id)ownerAtIndex:(unsigned)index;
- (id)ownerWithObject:(id)inObject;
- (int)greatestIntegerValue;
- (double)greatestDoubleValue;
- (NSDate *)earliestDate;
- (NSImage *)firstImage;
- (NSEnumerator *)objectEnumerator;
- (NSEnumerator *)ownerEnumerator;
- (NSArray *)allValues;

@end
