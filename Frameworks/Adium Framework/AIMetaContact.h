//
//  AIMetaContact.h
//  Adium
//
//  Created by Adam Iser on Wed Jan 28 2004.

#import "AIListContact.h"

#define META_SERVICE_STRING				AILocalizedString(@"Meta",nil)

@interface AIMetaContact : AIListContact <AIContainingObject> {
	NSNumber				*objectID;
	
	NSMutableDictionary		*statusCacheDict;	//Cache of the status of our contained objects
	
	AIListContact			*_preferredContact;
	NSArray					*_listContacts;
	
	BOOL					containsOnlyOneUniqueContact;
	BOOL					containsOnlyOneService;

	NSMutableArray			*containedObjects;			//Manually ordered array of contents
}

//The objectID is unique to a meta contact and is used as the UID for purposes of AIListContact inheritance
- (id)initWithObjectID:(NSNumber *)objectID;
- (NSNumber *)objectID;
+ (NSString *)internalObjectIDFromObjectID:(NSNumber *)inObjectID;

- (AIListContact *)preferredContact;
- (AIListContact *)preferredContactWithService:(AIService *)inService;

- (void)containedMetaContact:(AIMetaContact *)containedMetaContact didChangeContainsOnlyOneUniqueContact:(BOOL)inContainsOnlyOneUniqueContact;

- (BOOL)containsOnlyOneUniqueContact;
- (BOOL)containsOnlyOneService;
- (int)uniqueContainedObjectsCount;
- (AIListObject *)uniqueObjectAtIndex:(int)inIndex;
- (NSArray *)listContacts;

- (NSDictionary *)dictionaryOfServicesAndListContacts;

@end
