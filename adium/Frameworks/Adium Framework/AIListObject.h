/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@class AIMutableOwnerArray, AIListGroup, AISortController;

typedef enum {
	AIAvailableStatus = 'avaL',
	AIAwayStatus = 'awaY',
	AIIdleStatus = 'idlE',
	AIAwayAndIdleStatus = 'aYiE',
	AIOfflineStatus = 'offL',
	AIUnknownStatus = 'unkN'
} AIStatusSummary;

@interface AIListObject : AIObject {
    NSString				*UID;
    NSString				*serviceID;
	NSString				*uniqueObjectID;
	BOOL					visible;				//Visibility of this object
	
	//Status and display
    NSMutableDictionary		*displayDictionary;		//A dictionary of values affecting this object's display
    NSMutableDictionary		*statusDictionary;
    NSMutableArray			*changedStatusKeys;		//Status keys that have changed since the last notification
	NSMutableArray			*delayedStatusTimers;

	//Grouping, Manual ordering
    AIListObject			*containingObject;		//The group this object is in
	float					orderIndex;				//Placement of this contact within a group
	
	NSMutableArray			*containedObjects;			//Manually ordered array of contents
}

- (NSEnumerator *)statusKeyEnumerator;


//
- (id)initWithUID:(NSString *)inUID serviceID:(NSString *)inServiceID;

//Identifying information
- (NSString *)UID;
- (NSString *)serviceID;
- (NSString *)uniqueObjectID;
- (NSString *)ultraUniqueObjectID;
+ (NSString *)uniqueObjectIDForUID:(NSString *)inUID serviceID:(NSString *)inServiceID;

//Visibility
- (void)setVisible:(BOOL)inVisible;
- (BOOL)visible;

//Grouping
- (AIListGroup *)containingObject;
- (float)orderIndex;

//Display
- (NSString *)formattedUID;
- (NSString *)longDisplayName;
- (NSString *)displayServiceID;
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey;
- (AIMutableOwnerArray *)displayArrayForKey:(NSString *)inKey create:(BOOL)create;

//Prefs
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName ignoreInheritedValues:(BOOL)ignore;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName;
- (NSArray *)allPreferencesForKey:(NSString *)inKey group:(NSString *)groupName;
- (NSString *)pathToPreferences;

//Status
- (void)setStatusObject:(id)value forKey:(NSString *)key notify:(BOOL)notify;
- (void)setStatusObject:(id)value forKey:(NSString *)key afterDelay:(NSTimeInterval)delay;
- (void)delayedStatusChange:(NSDictionary *)statusChangeDict;
- (void)notifyOfChangedStatusSilently:(BOOL)silent;
- (id)statusObjectForKey:(NSString *)key;
- (void)listObject:(AIListObject *)inObject didSetStatusObject:(id)value forKey:(NSString *)key notify:(BOOL)notify;

- (id)statusObjectForKey:(NSString *)key;
- (int)integerStatusObjectForKey:(NSString *)key;
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key;
- (NSNumber *)numberStatusObjectForKey:(NSString *)key;
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key;

//Alter the placement of this object in a group (PRIVATE: These are for AIListGroup ONLY)
- (void)setOrderIndex:(float)inIndex;

//Grouping (PRIVATE: These are for AIListGroup and AIMetaContact ONLY)
- (void)setContainingObject:(AIListObject *)inGroup;

//Key-Value pairing
- (BOOL)online;
- (AIStatusSummary)statusSummary;

- (NSString *)displayName;
- (void)setDisplayName:(NSString *)alias;

- (NSString *)notes;
- (void)setNotes:(NSString *)notes;

//Containing contacts (for subclassing)
- (BOOL)addObject:(AIListObject *)inObject;
- (void)removeObject:(AIListObject *)inObject;
- (void)visibilityOfContainedObject:(AIListObject *)inObject changedTo:(BOOL)inVisible;
- (void)sortListObject:(AIListObject *)inObject sortController:(AISortController *)sortController;

//Containing contacts (handled for subclasses)
- (NSEnumerator *)objectEnumerator;
- (id)objectAtIndex:(unsigned)index;
- (int)indexOfObject:(AIListObject *)inObject;
- (NSArray *)containedObjects;
- (unsigned)containedObjectsCount;
- (AIListObject *)objectWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID;

//mutableOwnerArray delegate and methods
- (void)mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(id)anObject withOwner:(id)inOwner;
- (void)listObject:(AIListObject *)listObject mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(AIListObject *)anObject withOwner:(AIListObject *)inOwner;

@end
