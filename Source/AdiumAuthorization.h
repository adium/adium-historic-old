//
//  AdiumAuthorization.h
//  Adium
//
//  Created by Evan Schoenberg on 1/18/06.
//

#import <Adium/AIObject.h>

@class AIAccount;
@protocol AIEventHandler;

@interface AdiumAuthorization : AIObject <AIEventHandler> {

}

- (id)showAuthorizationRequestWithDict:(NSDictionary *)inDict forAccount:(AIAccount *)inAccount;

@end
