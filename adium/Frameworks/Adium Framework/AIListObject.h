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

#import <Cocoa/Cocoa.h>

@class AIMutableOwnerArray, AIListGroup;

@interface AIListObject : NSObject {
    NSMutableDictionary	*displayDictionary;	//A dictionary of values affecting this object's display
    AIListGroup 	*containingGroup;	//The group this object is in
    NSString		*UID;
    float		orderIndex;
    NSMutableDictionary	*statusDictionary;
    NSString		*serviceID;

}

- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID;

//Identifying information
- (NSString *)UID;
- (NSString *)serviceID;
- (NSString *)UIDAndServiceID;

//Display
- (NSString *)displayName;
- (NSString *)formattedDisplayName;
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey;

//Nesting
- (void)setContainingGroup:(AIListGroup *)inGroup;
- (AIListGroup *)containingGroup;

//Manual Ordering
- (void)setOrderIndex:(float)inIndex;
- (float)orderIndex;

//Status
- (AIMutableOwnerArray *)statusArrayForKey:(NSString *)inKey;


@end
