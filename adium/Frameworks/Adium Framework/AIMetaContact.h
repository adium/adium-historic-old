//
//  AIMetaContact.h
//  Adium
//
//  Created by Adam Iser on Wed Jan 28 2004.

#import "AIListGroup.h"

@interface AIMetaContact : AIListContact {
	NSNumber				*objectID;
	
	NSMutableDictionary		*statusCacheDict;	//Cache of the status of our contained objects
}

//The objectID is unique to a meta contact and is used as the UID for purposes of AIListContact inheritance
- (id)initWithObjectID:(NSNumber *)objectID;
- (NSNumber *)objectID;

- (AIListContact *)preferredContact;

@end
