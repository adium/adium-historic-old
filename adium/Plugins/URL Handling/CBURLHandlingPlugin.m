//
//  CBURLHandlingPlugin.m
//  Adium
//
//  Created by Colin Barrett on Tue Mar 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CBURLHandlingPlugin.h"

@interface CBURLHandlingPlugin(PRIVATE)
- (void)setHelperAppForKey:(ConstStr255Param)key withInstance:(ICInstance)ICInst;
- (void)_openChatToContactWithName:(NSString *)name onService:(NSString *)serviceIdentifier withMessage:(NSString *)body;
@end

@implementation CBURLHandlingPlugin

- (void)installPlugin
{
    /* TODO:
        * Prompt the user to change Adium to be the protocol handler for aim:// and/or yahoo:// if we aren't already. Give them the option to agree, disagree, or disagree and never be asked again. 
    */
	ICInstance ICInst;
	OSErr Err;

	//Start Internet Config, passing it Adium's creator code
	Err = ICStart(&ICInst, 'AdiM');
	
	//Configure the protocols we want.  Note that this file needs to remain in MacRoman encoding for that ¥ (command-8)
	//to be recognized properly.
	[self setHelperAppForKey:"\pHelper¥aim" withInstance:ICInst];
	[self setHelperAppForKey:"\pHelper¥ymsgr" withInstance:ICInst];
	
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)setHelperAppForKey:(ConstStr255Param)key withInstance:(ICInstance)ICInst
{
	OSErr Err;
	ICAppSpec Spec;
	ICAttr Junk;
	long TheSize;

	TheSize = sizeof(Spec);
	// Get the current aim helper app, to fill the Spec and TheSize variables
	Err = ICGetPref(ICInst, key, &Junk, &Spec, &TheSize);

	//Set the name and creator codes
	Spec.name[0] = sprintf((char *) &Spec.name[1], "Adium.app");
	Spec.fCreator = 'AdIM';

	//Set the helper app to Adium
	Err = ICSetPref(ICInst, key, Junk, &Spec, TheSize);
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
				NSString *name = [url queryArgumentForKey:@"screenname"];
				if (name){
					[self _openChatToContactWithName:name
										   onService:@"AIM" 
										 withMessage:[[url queryArgumentForKey:@"message"] stringByDecodingURLEscapes]];
				}
            } else if ([[url host] caseInsensitiveCompare:@"addbuddy"] == NSOrderedSame) {
				
				[[adium contactController] requestAddContactWithUID:[url queryArgumentForKey:@"screenname"]
														  serviceID:@"AIM"];
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
	AIListContact   *contact;
	AIChat			*chat;
	
	contact = [[adium contactController] preferredContactWithUID:UID
													andServiceID:serviceID 
										   forSendingContentType:CONTENT_MESSAGE_TYPE];
	if (contact){
		//Open the chat and set it as active
		chat = [[adium contentController] openChatWithContact:contact];
		[[adium interfaceController] setActiveChat:chat];
		
		//Insert the message text as if the user had typed it after opening the chat
		NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if(message && [responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]){
			[responder insertText:message];
		}
	}
}

@end
