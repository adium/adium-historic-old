//
//  AICoreObject.h
//  Adium
//
//  Created by Adam Iser on Sun Dec 14 2003.
//

@class AIAdium;

@interface AIObject : NSObject {
    AIAdium     *adium;
}
+ (void)_setSharedAdiumInstance:(AIAdium *)shared;
+ (AIAdium *)sharedAdiumInstance;
@end
