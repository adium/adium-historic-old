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

/*
TODO: 
    o generalize the sending stuff into a single private method
    o add suppport for "stuffing" the inputline with a particluar message 
*/
- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *string = [[event descriptorAtIndex:1] stringValue];
    NSURL *url = [NSURL URLWithString:string];
    
    if(url){        
        if(![[url resourceSpecifier] hasPrefix:@"//"]){
            string = [NSString stringWithFormat:@"%@://%@", [url scheme], [url resourceSpecifier]];
            url = [NSURL URLWithString:string];
        }
        
        if([[url scheme] isEqualToString:@"aim"]){
            if([[url host] caseInsensitiveCompare:@"goim"] == NSOrderedSame){                
                NSString *screenname = [url queryArgumentForKey:@"screenname"]; 
                NSString *service = @"AIM";
                
                AIAccount *account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE 
                                                                                         toListObject:[[[AIListObject alloc] initWithUID:screenname 
                                                                                                                               serviceID:service] 
                                                                                                                            autorelease]];
                AIListContact *contact = [[[AIListContact alloc] initWithUID:screenname 
                                                                    accountID:[account uniqueObjectID]
                                                                    serviceID:service]
                                                                autorelease];
                
                [[adium contentController] openChatWithContact:contact];
            }
            
        // DO NOT OPEN UNTIL XMAS...err...0.76
        }/*else if([[url scheme] isEqualToString:@"ymsgr"]){
            if([[url host] caseInsensitiveCompare:@"sendim"] == NSOrderedSame){
                NSString *screenname = [url query]; 
                NSString *service = @"Yahoo!";
                
                AIAccount *account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE 
                                                                                         toListObject:[[[AIListObject alloc] initWithUID:screenname 
                                                                                                                               serviceID:service] 
                                                                                                                            autorelease]];
                AIListContact *contact = [[[AIListContact alloc] initWithUID:screenname 
                                                                    accountID:[account uniqueObjectID]
                                                                    serviceID:service]
                                                                autorelease];
                
                [[adium contentController] openChatWithContact:contact];
            }
        }*/
    }else{
        NSLog(@"invalid URL");
    }
}

- (void)uninstallPlugin
{

}

@end
