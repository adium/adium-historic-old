//
//  AIMetaContact.h
//  Adium
//
//  Created by Adam Iser on Wed Jan 28 2004.

#import "AIListContact.h"

#define META_SERVICE_STRING				AILocalizedString(@"Meta",nil)

@interface AIMetaContact : AIListContact {
	NSNumber				*objectID;
	
	NSMutableDictionary		*statusCacheDict;	//Cache of the status of our contained objects
	
	AIListContact			*_preferredContact;
	NSArray					*_listContacts;
	
	BOOL					containsOnlyOneUniqueContact;
	BOOL					containsOnlyOneService;
}

//The objectID is unique to a meta contact and is used as the UID for purposes of AIListContact inheritance
- (id)initWithObjectID:(NSNumber *)objectID;
- (NSNumber *)objectID;

- (AIListContact *)preferredContact;
- (AIListContact *)preferredContactWithServiceID:(NSString *)inServiceID;

- (id)statusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject;
- (NSDate *)earliestDateStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject;
- (int)integerStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject;
- (NSNumber *)numberStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject;
- (NSString *)stringFromAttributedStringStatusObjectForKey:(NSString *)key fromAnyContainedObject:(BOOL)fromAnyContainedObject;

- (void)containedMetaContact:(AIMetaContact *)containedMetaContact didChangeContainsOnlyOneUniqueContact:(BOOL)inContainsOnlyOneUniqueContact;

- (BOOL)containsOnlyOneUniqueContact;
- (BOOL)containsOnlyOneService;
- (int)uniqueContainedObjectsCount;
- (AIListObject *)uniqueObjectAtIndex:(int)inIndex;

@end
