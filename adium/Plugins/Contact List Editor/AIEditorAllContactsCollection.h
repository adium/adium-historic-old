//
//  AIEditorAllContactsCollection.h
//  Adium
//
//  Created by Adam Iser on Fri May 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIEditorCollection.h"

@class AIAdium, AIEditorListGroup, AIEditorAccountCollection, AIContactListEditorPlugin;

@interface AIEditorAllContactsCollection : NSObject <AIEditorCollection> {
    AIAdium				*owner;

    AIEditorListGroup			*list;
    AIContactListEditorPlugin		*plugin;

}

+ (AIEditorAllContactsCollection *)allContactsCollectionWithOwner:(id)inOwner plugin:(id)inPlugin;
- (NSString *)name;
- (NSImage *)icon;
- (BOOL)enabled;
- (AIEditorListGroup *)list;
- (void)addObject:(AIEditorListObject *)inObject;
- (void)deleteObject:(AIEditorListObject *)inObject;
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName;
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup;

@end
