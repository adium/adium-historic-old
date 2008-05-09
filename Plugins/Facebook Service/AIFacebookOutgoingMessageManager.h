//
//  AIFacebookOutgoingMessageManager.h
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//

#import <Cocoa/Cocoa.h>

@class AIContentMessage;

@interface AIFacebookOutgoingMessageManager : NSObject {

}

+ (void)sendMessageObject:(AIContentMessage *)inContentMessage;

@end
