//
//  AIPreviewContentMessage.h
//  Adium
//
//  Created by Evan Schoenberg on 8/26/07.
//

#import <Cocoa/Cocoa.h>

#import <Adium/AIContentMessage.h>

@interface AIPreviewContentMessage : AIContentMessage {

}

- (void)setIsOutgoing:(BOOL)inOutgoing;

@end
