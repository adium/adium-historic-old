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

@class AIMutableOwnerArray, AIContactGroup, AIAccount;

@interface AIContactObject : NSObject {
    NSMutableDictionary		*displayDictionary;	//A dictionary of values affecting this object's display
    
    AIContactGroup 		*containingGroup;	//The group this object is in

    NSMutableArray		*ownerArray;		//An array of accounts that 'own' this group
    
//    AIAccount			*activeOwner;
}

- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey;
- (NSComparisonResult)compare:(AIContactObject *)object;
- (NSString *)displayName;
- (AIContactGroup *)containingGroup;
- (void)setContainingGroup:(AIContactGroup *)inGroup;
- (void)registerOwner:(AIAccount *)inOwner;
- (void)unregisterOwner:(AIAccount *)inOwner;
- (BOOL)belongsToAccount:(AIAccount *)inAccount;


@end
