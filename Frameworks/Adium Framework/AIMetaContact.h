//
//  AIMetaContact.h
//  Adium
//
//  Created by Adam Iser on Wed Jan 28 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIListContact.h"

#define META_SERVICE_STRING					AILocalizedString(@"Meta",nil)
#define	KEY_PREFERRED_DESTINATION_CONTACT	@"Preferred Destination Contact"

@interface AIMetaContact : AIListContact <AIContainingObject> {
	NSNumber				*objectID;
	
	NSMutableDictionary		*statusCacheDict;	//Cache of the status of our contained objects
	
	AIListContact			*_preferredContact;
	NSArray					*_listContacts;
	
	BOOL					containsOnlyOneUniqueContact;
	BOOL					containsOnlyOneService;

	NSMutableArray			*containedObjects;			//Manually ordered array of contents
	BOOL					containedObjectsNeedsSort;
	BOOL					delayContainedObjectSorting;
	BOOL					saveGroupingChanges;
	
    BOOL					expanded;			//Exanded/Collapsed state of this object
	
	float					largestOrder;
	float					smallestOrder;
}

//The objectID is unique to a meta contact and is used as the UID for purposes of AIListContact inheritance
- (id)initWithObjectID:(NSNumber *)objectID;
- (NSNumber *)objectID;
+ (NSString *)internalObjectIDFromObjectID:(NSNumber *)inObjectID;

- (AIListContact *)preferredContact;
- (AIListContact *)preferredContactWithService:(AIService *)inService;

//Used for one metaContact talking to another
- (void)containedMetaContact:(AIMetaContact *)containedMetaContact didChangeContainsOnlyOneUniqueContact:(BOOL)inContainsOnlyOneUniqueContact;
- (void)remoteGroupingOfContainedObject:(AIListObject *)inListObject changedTo:(NSString *)inRemoteGroupName;

//YES if the metaContact has only one UID/serviceID within it - for example, three different accounts' AIListContacts for a particular screen name
- (BOOL)containsOnlyOneUniqueContact;

//Similarly, YES if the metaContact has only one serviceID within it.
- (BOOL)containsOnlyOneService;
- (unsigned)uniqueContainedObjectsCount;
- (AIListObject *)uniqueObjectAtIndex:(int)inIndex;

- (NSDictionary *)dictionaryOfServiceClassesAndListContacts;

- (void)setExpanded:(BOOL)inExpanded;
- (BOOL)isExpanded;

// (PRIVATE: For contact controller ONLY)
- (BOOL)addObject:(AIListObject *)inObject;
- (void)removeObject:(AIListObject *)inObject;

//A flat array of AIListContacts each with a different internalObjectID
- (NSArray *)listContacts;

//Delay sorting the contained object list; this should only be used by the contactController. Be sure to set it back to YES when operations are done
- (void)setDelayContainedObjectSorting:(BOOL)flag;


@end
