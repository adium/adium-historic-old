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

#define Highest_Priority  	0.0
#define High_Priority  		0.25
#define Medium_Priority  	0.5
#define Low_Priority  		0.75
#define Lowest_Priority  	1.0

@interface AIMutableOwnerArray : NSObject {
    NSMutableArray	*contentArray;
    NSMutableArray	*ownerArray;
    NSMutableArray	*priorityArray;
	
	BOOL			valueIsSortedToFront;
}

//Value Storage
- (void)setObject:(id)anObject withOwner:(id)inOwner;
- (void)setObject:(id)anObject withOwner:(id)inOwner priorityLevel:(float)priority;

//Value Retrieval
- (id)objectValue;
- (int)intValue;
- (double)doubleValue;
- (NSDate *)date;
- (id)objectWithOwner:(id)inOwner;
- (NSEnumerator *)objectEnumerator;
- (NSArray *)allValues;
- (unsigned)count;

@end
