//
//  CBURLHandlingPlugin.m
//  Adium
//
//  Created by Colin Barrett on Tue Mar 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CBURLHandlingPlugin.h"

@interface CBURLHandlingPlugin(PRIVATE)
- (void)_openChatToContactWithName:(NSString *)name onService:(NSString *)serviceIdentifier withMessage:(NSString *)body;
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
                [self _openChatToContactWithName:[url queryArgumentForKey:@"screenname"] onService:@"AIM" withMessage:nil];
            }
            
        }else if([[url scheme] isEqualToString:@"ymsgr"]){
            if([[url host] caseInsensitiveCompare:@"sendim"] == NSOrderedSame){
                [self _openChatToContactWithName:[url query] onService:@"Yahoo!" withMessage:nil];
            }
        }
    }else{
        NSLog(@"invalid URL");
    }
}

- (void)uninstallPlugin
{

}

- (void)_openChatToContactWithName:(NSString *)name onService:(NSString *)serviceIdentifier withMessage:(NSString *)body
{
    AIAccount *account = [[adium accountController] preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE 
                                                                             toListObject:[[[AIListObject alloc] initWithUID:name 
                                                                                                                   serviceID:serviceIdentifier] 
                                                                                                                autorelease]];
    AIListContact *contact = [[[AIListContact alloc] initWithUID:name 
                                                        accountID:[account uniqueObjectID]
                                                        serviceID:serviceIdentifier]
                                                    autorelease];
    
    [[adium contentController] openChatWithContact:contact];
}

@end
