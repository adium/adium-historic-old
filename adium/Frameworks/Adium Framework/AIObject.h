//
//  AICoreObject.h
//  Adium XCode
//
//  Created by Adam Iser on Sun Dec 14 2003.
//

#import <Foundation/Foundation.h>

@class AIAdium;

@interface AIObject : NSObject {
    AIAdium     *adium;
}
+ (void)_setSharedAdiumInstance:(AIAdium *)shared;
+ (AIAdium *)sharedAdiumInstance;
@end
