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

#define PREF_GROUP_OBJECT_STATUS_CACHE  @"Object Status Cache"
#define KEY_FORMATTED_UID				@"FormattedUID"
#define KEY_DISPLAY_SERVICE_ID			@"DisplayServiceID"

@class AIMutableOwnerArray, AIListGroup;

@interface AIListObject : AIObject {
    NSString				*UID;
    NSString				*serviceID;
	BOOL					visible;				//Visibility of this object
	
	//Status and display
    NSMutableDictionary		*displayDictionary;		//A dictionary of values affecting this object's display
    NSMutableDictionary		*statusDictionary;
    NSMutableArray			*changedStatusKeys;		//Status keys that have changed since the last notification
	NSMutableArray			*delayedStatusTimers;

	//Grouping, Manual ordering
    AIListGroup				*containingGroup;		//The group this object is in
	float					orderIndex;				//Placement of this contact within a group
	
	//
}

- (NSEnumerator *)statusKeyEnumerator;


//
- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID;

//Identifying information
- (NSString *)UID;
- (NSString *)serviceID;
- (NSString *)uniqueObjectID;

//Visibility
- (void)setVisible:(BOOL)inVisible;
- (BOOL)isVisible;

//Grouping
- (AIListGroup *)containingGroup;
- (float)orderIndex;

//Display
- (NSString *)formattedUID;
- (NSString *)displayName;
- (NSString *)longDisplayName;
- (NSString *)displayServiceID;
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey;

//Prefs
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName ignoreInheritedValues:(BOOL)ignore;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName;
- (NSArray *)allPreferencesForKey:(NSString *)inKey group:(NSString *)groupName;
- (NSString *)pathToPreferences;

//Status
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(BOOL)notify;
- (void)setStatusObject:(id)value forKey:(NSString *)key afterDelay:(NSTimeInterval)delay;
- (void)notifyOfChangedStatusSilently:(BOOL)silent;
- (id)statusObjectForKey:(NSString *)key;
- (void)listObject:(AIListObject *)inObject didSetStatusObject:(id)value forKey:(NSString *)key;

- (id)statusObjectForKey:(NSString *)key;
- (int)integerStatusObjectForKey:(NSString *)key;
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key;
- (NSNumber *)numberStatusObjectForKey:(NSString *)key;

//Alter the placement of this object in a group (PRIVATE: These are for AIListGroup ONLY)
- (void)setOrderIndex:(float)inIndex;

//Grouping (PRIVATE: These are for AIListGroup ONLY)
- (void)setContainingGroup:(AIListGroup *)inGroup;

@end
