//
//  AICoreObject.m
//  Adium
//
//  Created by Adam Iser on Sun Dec 14 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "AIObject.h"


@implementation AIObject

//
static AIAdium *_sharedAdium = nil;
+ (void)_setSharedAdiumInstance:(AIAdium *)shared
{
    NSParameterAssert(_sharedAdium == nil);
    _sharedAdium = [shared retain];
}

//
+ (AIAdium *)sharedAdiumInstance
{
    NSParameterAssert(_sharedAdium != nil);
    return(_sharedAdium);
}

//
- (id)init
{
    [super init];

    NSParameterAssert(_sharedAdium != nil);
    adium = _sharedAdium;

    return(self);
}

@end
