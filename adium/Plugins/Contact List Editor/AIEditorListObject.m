//
//  AIEditorListObject.m
//  Adium
//
//  Created by Adam Iser on Sat Mar 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEditorListObject.h"
#import "AIEditorListGroup.h"

@implementation AIEditorListObject

- (id)initWithUID:(NSString *)inUID
{
    [super init];

    containingGroup = nil;
    UID = [inUID retain];
    
    return(self);
}

- (NSString *)UID
{
    return(UID);
}

- (void)setContainingGroup:(AIEditorListGroup *)inGroup
{
    [containingGroup release];
    containingGroup = [inGroup retain];
}
- (AIEditorListGroup *)containingGroup
{
    return(containingGroup);
}

@end
