//
//  AIEditorAccountCollection.h
//  Adium
//
//  Created by Adam Iser on Fri Mar 28 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIEditorCollection.h"

@class AIAdium, AIAccount, AIEditorListGroup, AIEditorAccountCollection;
@protocol AIAccount_Handles;

@interface AIEditorAccountCollection : NSObject <AIEditorCollection> {
    AIAdium				*owner;
    AIAccount<AIAccount_Handles>	*account;
    AIEditorListGroup			*list;
    BOOL				controlledChanges;
}

+ (AIEditorAccountCollection *)editorCollectionForAccount:(AIAccount *)inAccount withOwner:(id)inOwner;
- (NSString *)name;
- (NSImage *)icon;
- (BOOL)enabled;
- (AIEditorListGroup *)list;
- (void)addObject:(AIEditorListObject *)inObject;
- (void)deleteObject:(AIEditorListObject *)inObject;
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName;
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup;

@end
