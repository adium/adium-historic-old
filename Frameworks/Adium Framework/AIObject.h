//
//  AICoreObject.h
//  Adium
//
//  Created by Adam Iser on Sun Dec 14 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

@class AIAdium;

@interface AIObject : NSObject {
    AIAdium     *adium;
}
+ (void)_setSharedAdiumInstance:(AIAdium *)shared;
+ (AIAdium *)sharedAdiumInstance;
@end
