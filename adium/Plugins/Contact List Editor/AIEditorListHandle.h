//
//  AIEditorListHandle.h
//  Adium
//
//  Created by Adam Iser on Sat Mar 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIEditorListObject.h"

@class AIHandle;

@interface AIEditorListHandle : AIEditorListObject {
    NSString		*serviceID;
}

- (id)initWithServiceID:(NSString *)inServiceID UID:(NSString *)inUID temporary:(BOOL)inTemporary;
- (NSString *)serviceID;

@end
