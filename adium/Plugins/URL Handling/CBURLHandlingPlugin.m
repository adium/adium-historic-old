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
    NSString *longPrefix, *shortPrefix, *newString, *recipient = nil, *message = nil;
    NSString *string = [[event descriptorAtIndex:1] stringValue];
    NSURL *url = [NSURL URLWithString:string];
    
    if(url){
        shortPrefix = [NSString stringWithFormat:@"%@:", [url scheme]];
        longPrefix = [NSString stringWithFormat:@"%@//", shortPrefix];
        
        if(![string hasPrefix:longPrefix] && [string hasPrefix:shortPrefix]){
            newString = [string substringFromIndex:[shortPrefix length]];
            newString = [NSString stringWithFormat:@"%@%@", longPrefix, newString];
            url = [NSURL URLWithString:newString];
        }
        
        if([[url scheme] isEqualToString:@"aim"]){
            if([[url host] compare:@"goim" options:NSCaseInsensitiveSearch] == 0){
                recipient = [url propertyForKey:@"screenname"];
                message = [url propertyForKey:@"message"];
                
                //figure this out later
            }
        }
        /*}else if([[url scheme] isEqualToString:@"ymsgr"]){
            if([[url host] compare:@"sendim" options:NSCaseInsensitiveSearch] == 0){
                recipient = [url query];
                
                //figure this out later
            }*/
    }else{
        NSLog(@"invalid URL");
    }
}

- (void)uninstallPlugin
{

}

@end
