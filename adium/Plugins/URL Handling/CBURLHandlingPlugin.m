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
    /* TODO:
        * Prompt the user to change Adium to be the protocol handler for aim:// and/or yahoo:// if we aren't already. Give them the option to agree, disagree, or disagree and never be asked again. 
    */

    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    /* TODO: 
        * add suppport for "stuffing" the inputline with a particluar message. look @ bgannin's emoticon code for help w/ this.
    */

    NSString *string = [[event descriptorAtIndex:1] stringValue];
    NSURL *url = [NSURL URLWithString:string];
    
    if(url){        
        if(![[url resourceSpecifier] hasPrefix:@"//"]){
            string = [NSString stringWithFormat:@"%@://%@", [url scheme], [url resourceSpecifier]];
            url = [NSURL URLWithString:string];
        }
        
        if([[url scheme] isEqualToString:@"aim"]){
            if([[url host] caseInsensitiveCompare:@"goim"] == NSOrderedSame){                                
				NSLog(@"%@\n\n%@",[url queryArgumentForKey:@"message"],[[url queryArgumentForKey:@"message"] stringByDecodingURLEscapes]);
                [self _openChatToContactWithName:[url queryArgumentForKey:@"screenname"] 
									   onService:@"AIM" 
									 withMessage:[[url queryArgumentForKey:@"message"] stringByDecodingURLEscapes]];
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

- (void)_openChatToContactWithName:(NSString *)UID onService:(NSString *)serviceID withMessage:(NSString *)message
{
	AIListContact		*contact;
	AIChat				*chat;

	contact = [[adium contactController] preferredContactWithUID:UID
													andServiceID:serviceID 
										   forSendingContentType:CONTENT_MESSAGE_TYPE];
	
    chat = [[adium contentController] openChatWithContact:contact];

	if (message){
		AIContentMessage	*contentMessage;
		AIAccount			*account;
		
		account = [[adium accountController] accountWithObjectID:[contact accountID]];

		contentMessage = [AIContentMessage messageInChat:chat
											  withSource:account
											 destination:contact
													date:nil
												 message:[[[NSAttributedString alloc] initWithString:message 
																						  attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
											   autoreply:NO];
		[[adium contentController] sendContentObject:contentMessage];
	}
}

@end
