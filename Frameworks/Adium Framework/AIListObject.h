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

@class AIService, AIMutableOwnerArray, AIListGroup, AISortController, ESObjectWithStatus;

#import "ESObjectWithStatus.h"

#define	KEY_ORDER_INDEX	@"Order Index"

typedef enum {
	AIAvailableStatus = 'avaL',
	AIAwayStatus = 'awaY',
	AIIdleStatus = 'idlE',
	AIAwayAndIdleStatus = 'aYiE',
	AIOfflineStatus = 'offL',
	AIUnknownStatus = 'unkN'
} AIStatusSummary;

@protocol AIContainingObject
- (NSArray *)containedObjects;
- (unsigned)containedObjectsCount;
- (BOOL)containsObject:(AIListObject *)inObject;

- (id)objectAtIndex:(unsigned)index;
- (int)indexOfObject:(AIListObject *)inObject;
- (AIListObject *)objectWithService:(AIService *)inService UID:(NSString *)inUID;

//Enumerator of -[containedObjects]
- (NSEnumerator *)objectEnumerator;

//Should list each list contact only once (for groups, this is the same as the objectEnumerator)
- (NSEnumerator *)listContactsEnumerator;

- (BOOL)addObject:(AIListObject *)inObject;

- (void)removeObject:(AIListObject *)inObject;
- (void)removeAllObjects;

- (void)setExpanded:(BOOL)inExpanded;
- (BOOL)isExpanded;
- (float)smallestOrder;
- (float)largestOrder;
- (void)listObject:(AIListObject *)listObject didSetOrderIndex:(float)inOrderIndex;
- (unsigned)visibleCount;
@end

@interface AIListObject : ESObjectWithStatus{
	AIService				*service;
	
    NSString				*UID;
	NSString				*internalObjectID;
	BOOL					visible;				//Visibility of this object

	//Grouping, Manual ordering
    AIListObject <AIContainingObject>	*containingObject;		//The group/metacontact this object is in
	float								orderIndex;				//Placement of this contact within a group
}

//
- (id)initWithUID:(NSString *)inUID service:(AIService *)inService;

//Identifying information
- (NSString *)UID;
- (AIService *)service;
- (NSString *)serviceClass;
- (NSString *)internalObjectID;
+ (NSString *)internalObjectIDForServiceID:(NSString *)inServiceID UID:(NSString *)inUID;

//Visibility
- (void)setVisible:(BOOL)inVisible;
- (BOOL)visible;

//Grouping
- (AIListObject <AIContainingObject> *)containingObject;
- (float)orderIndex;

//Display
- (NSString *)formattedUID;
- (NSString *)longDisplayName;

//Prefs
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName ignoreInheritedValues:(BOOL)ignore;
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName;
- (NSArray *)allPreferencesForKey:(NSString *)inKey group:(NSString *)groupName;
- (NSString *)pathToPreferences;

//Alter the placement of this object in a group (PRIVATE: These are for AIListGroup ONLY)
- (void)setOrderIndex:(float)inIndex;

//Grouping (PRIVATE: These are for AIListGroup and AIMetaContact ONLY)
- (void)setContainingObject:(AIListObject <AIContainingObject> *)inGroup;

//Key-Value pairing
- (BOOL)online;
- (AIStatusSummary)statusSummary;

- (NSString *)displayName;
- (void)setDisplayName:(NSString *)alias;

- (NSString *)notes;
- (void)setNotes:(NSString *)notes;

- (NSImage *)userIcon;
- (NSData *)userIconData;
- (void)setUserIconData:(NSData *)inData;
- (NSImage *)displayUserIcon;
- (void)setDisplayUserIcon:(NSImage *)inImage;
- (void)setDisplayUserIcon:(NSImage *)inImage withOwner:(id)inOwner priorityLevel:(float)inPriorityLevel;

//mutableOwnerArray delegate and methods
- (void)listObject:(AIListObject *)listObject mutableOwnerArray:(AIMutableOwnerArray *)inArray didSetObject:(AIListObject *)anObject withOwner:(AIListObject *)inOwner priorityLevel:(float)priority;

@end
