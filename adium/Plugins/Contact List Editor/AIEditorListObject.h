//
//  AIEditorListObject.h
//  Adium
//
//  Created by Adam Iser on Sat Mar 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIEditorListGroup;

@interface AIEditorListObject : NSObject {

    NSString		*UID;
    BOOL		temporary;
    AIEditorListGroup	*containingGroup;
}

- (id)initWithUID:(NSString *)inUID temporary:(BOOL)inTemporary;
- (NSString *)UID;
- (void)setUID:(NSString *)inUID;
- (void)setContainingGroup:(AIEditorListGroup *)inGroup;
- (AIEditorListGroup *)containingGroup;
- (BOOL)temporary;

@end
