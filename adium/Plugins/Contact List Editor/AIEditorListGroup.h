//
//  AIEditorListGroup.h
//  Adium
//
//  Created by Adam Iser on Sat Mar 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIEditorListObject.h"

@interface AIEditorListGroup : AIEditorListObject {
    NSMutableArray	*contents;
    BOOL		expanded;
}

- (id)initWithUID:(NSString *)inUID temporary:(BOOL)inTemporary;
- (void)addObject:(AIEditorListObject *)inObject;
- (AIEditorListObject *)objectAtIndex:(unsigned)index;
- (void)removeObject:(AIEditorListObject *)inObject;
- (NSEnumerator *)objectEnumerator;
- (unsigned)count;
- (void)setExpanded:(BOOL)inExpanded;
- (BOOL)isExpanded;
- (void)sort;

@end
