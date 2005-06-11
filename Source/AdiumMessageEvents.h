//
//  AdiumMessageEvents.h
//  Adium
//
//  Created by Evan Schoenberg on 6/10/05.
//

#import <Adium/AIObject.h>

@protocol AIEventHandler, AIChatObserver;

@interface AdiumMessageEvents : AIObject<AIEventHandler, AIChatObserver> {

}

@end
