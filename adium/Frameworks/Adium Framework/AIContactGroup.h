/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <Cocoa/Cocoa.h>
#import "AIContactObject.h"

@class AIAccount;

@interface AIContactGroup : AIContactObject {
    NSString		*name;			//The name of this group
    NSMutableArray    	*contactArray;		//Manual ordered array of contents
    NSMutableArray    	*sortedContactArray;	//Dynamically sorted array of contents
    int			sortedCount;		//The number of visible buddies in the sorted array
}

+ (id)contactGroupWithName:(NSString *)inName;
- (void)setName:(NSString *)inName;
- (NSString *)displayName;
- (unsigned)count;
- (id)objectAtIndex:(unsigned)index;
- (unsigned)sortedCount;
- (id)sortedObjectAtIndex:(unsigned)index;
- (void)sortGroupAndSubGroups:(BOOL)subGroups;
- (int)contentsBelongToAccount:(AIAccount *)inAccount;

//Semi-Private
- (void)addObject:(AIContactObject *)inObject;
- (void)replaceObject:(AIContactObject *)oldObject with:(AIContactObject *)newObject;
- (void)removeObject:(AIContactObject *)inObject;

@end
