//
//  AIEditorBlockedCollection.h
//  Adium
//
//  Created by Adam Iser on Sun May 11 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIEditorCollection.h"

@class AIAdium, AIEditorListGroup, AIEditorAccountCollection;

@interface AIEditorBlockedCollection : NSObject {
    AIAdium				*owner;

    AIEditorListGroup			*list;
    
}

+ (AIEditorBlockedCollection *)blockedCollectionWithOwner:(id)inOwner;
- (id)initWithOwner:(id)inOwner;
- (NSString *)name;
- (NSImage *)icon;
- (BOOL)enabled;
- (AIEditorListGroup *)list;
- (void)addObject:(AIEditorListObject *)inObject;
- (void)deleteObject:(AIEditorListObject *)inObject;
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName;
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup;

@end