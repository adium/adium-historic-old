//
//  CBURLHandlingPlugin.h
//  Adium
//
//  Created by Colin Barrett on Tue Mar 23 2004.
//

@interface CBURLHandlingPlugin : AIPlugin {

}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;

@end
