//
//  CBURLHandlingPlugin.m
//  Adium
//
//  Created by Colin Barrett on Tue Mar 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CBURLHandlingPlugin.h"

@interface CBURLHandlingPlugin(PRIVATE)

@end

@implementation CBURLHandlingPlugin

- (void)installPlugin
{
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSLog([[event descriptorAtIndex:1] stringValue]);
    NSURL *url = [NSURL URLWithString:[[event descriptorAtIndex:1] stringValue]];
    
    if(url){
        if([[url scheme] isEqualToString:@"aim"]){
            NSLog([url path]);
            NSLog([url host]);
        }else{
            NSLog(@"not aim://");
        }
    }else{
        NSLog(@"invalid URL");
    }
}

- (void)uninstallPlugin
{

}

@end
