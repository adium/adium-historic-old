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

@class AIMutableOwnerArray, AIListGroup;

@interface AIListObject : AIObject {
    NSMutableDictionary		*displayDictionary;	//A dictionary of values affecting this object's display
    AIListGroup 			*containingGroup;	//The group this object is in
    NSString				*UID;
    float					orderIndex;
    NSMutableDictionary		*statusDictionary;
    NSString				*serviceID;
    NSMutableDictionary 	*prefDict;
    NSMutableArray			*changedStatusKeys;		//Status keys that have changed since the last notification
}

- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID;

//Identifying information
- (NSString *)serviceID;
- (NSString *)UIDAndServiceID;

//Display
- (NSString *)UID;
- (NSString *)serverDisplayName;
- (NSString *)displayName;
- (NSString *)longDisplayName;
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey;

//Prefs
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName ignoreInheritedValues:(BOOL)ignore;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName;
- (NSString *)pathToPreferences;

//Nesting
- (void)setContainingGroup:(AIListGroup *)inGroup;
- (AIListGroup *)containingGroup;

//Manual Ordering
- (void)setOrderIndex:(float)inIndex;
- (float)orderIndex;

//Status
- (AIMutableOwnerArray *)statusArrayForKey:(NSString *)inKey;
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(BOOL)notify;
- (void)setStatusObject:(id)value withOwner:(id)owner forKey:(NSString *)key notify:(BOOL)notify;
- (void)setStatusObject:(id)value withOwner:(id)owner forKey:(NSString *)key afterDelay:(NSTimeInterval)delay;
- (void)notifyOfChangedStatusSilently:(BOOL)silent;
- (id)statusObjectForKey:(NSString *)key;
- (id)statusObjectForKey:(NSString *)key withOwner:(id)owner;

@end
