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

- (id)initWithUID:(NSString *)inUID temporary:(BOOL)inTemporary
{
    [super init];

    temporary = inTemporary;
    containingGroup = nil;
    UID = [inUID retain];
    
    return(self);
}

- (void)dealloc
{
    [UID release];
    [containingGroup release];
    
    [super dealloc];
}

- (NSString *)UID
{
    return(UID);
}
- (void)setUID:(NSString *)inUID
{
    [UID release];
    UID = [inUID retain];
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

//Temporary = not on the account's list.. for the editor's use only (when creating new)
- (BOOL)temporary
{
    return(temporary);
}
- (void)setTemporary:(BOOL)inTemporary
{
    temporary = inTemporary;
}

@end
