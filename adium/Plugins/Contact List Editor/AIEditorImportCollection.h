//
//  AIEditorImportCollection.h
//  Adium
//
//  Created by Colin Barrett on Sun Apr 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIEditorCollection.h"
#import "AIEditorListGroup.h"
#import "AIEditorListHandle.h"

@interface AIEditorImportCollection : NSObject <AIEditorCollection>
{
    AIEditorListGroup			*list;
    NSString				*path;
}

+ (AIEditorImportCollection *)editorCollectionWithPath:(NSString *)inPath;
- (NSString *)name;
- (NSImage *)icon;
- (BOOL)enabled;
- (AIEditorListGroup *)list;
//these functions are ignored (they are empty)
- (void)addObject:(AIEditorListObject *)inObject;
- (void)deleteObject:(AIEditorListObject *)inObject;
- (void)renameObject:(AIEditorListObject *)inObject to:(NSString *)newName;
- (void)moveObject:(AIEditorListObject *)inObject toGroup:(AIEditorListGroup *)inGroup;
@end
