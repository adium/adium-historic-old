//
//  AIEditorCollection.h
//  Adium
//
//  Created by Adam Iser on Sat Mar 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIEditorListGroup, AIEditorListObject;

@protocol AIEditorCollection <NSObject>
- (NSString *)name;
- (NSString *)UID;
- (NSImage *)icon;
- (BOOL)enabled;
- (AIEditorListGroup *)list;
- (void)addObject:(AIEditorListObject *)inObject;
- (void)deleteObject:(AIEditorListObject *)inObject;
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName;
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup;
@end
