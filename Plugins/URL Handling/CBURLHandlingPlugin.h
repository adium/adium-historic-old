//
//  CBURLHandlingPlugin.h
//  Adium
//
//  Created by Colin Barrett on Tue Mar 23 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface CBURLHandlingPlugin : AIPlugin {

}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;

@end
