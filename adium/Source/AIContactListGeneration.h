//
//  AIContactListGeneration.h
//  Adium
//
//  Created by Adam Iser on Sat May 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAdium, AIHandle, AIAccount, AIListGroup, AIListContact;

@interface AIContactListGeneration : NSObject {
    AIAdium			*owner;

    AIListGroup 		*contactList;
    
    NSMutableDictionary		*groupDict;
    NSMutableDictionary		*abandonedContacts;
    NSMutableDictionary		*abandonedGroups;
    
}

- (id)initWithContactList:(AIListGroup *)inContactList owner:(id)inOwner;
- (void)handle:(AIHandle *)inHandle addedToAccount:(AIAccount *)inAccount;
- (void)handle:(AIHandle *)inHandle removedFromAccount:(AIAccount *)inAccount;
- (void)handlesChangedForAccount:(AIAccount *)inAccount;

@end
