//
//  CBURLHandlingPlugin.m
//  Adium
//
//  Created by Colin Barrett on Tue Mar 23 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "CBURLHandlingPlugin.h"
#import "XtrasInstaller.h"

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
	
	//Configure the protocols we want.  Note that this file needs to remain in MacRoman encoding for that � (option-8)
	//to be recognized properly.
	[self setHelperAppForKey:"\pHelper�aim" withInstance:ICInst];
	[self setHelperAppForKey:"\pHelper�ymsgr" withInstance:ICInst];
	[self setHelperAppForKey:"\pHelper�xmpp" withInstance:ICInst];
	[self setHelperAppForKey:"\pHelper�adiumxtra" withInstance:ICInst];
/*
	[self setHelperAppForKey:"\pHelper�jabber" withInstance:ICInst];
	[self setHelperAppForKey:"\pHelper�icq" withInstance:ICInst];
	[self setHelperAppForKey:"\pHelper�msn" withInstance:ICInst];
*/	

	//We're done with Internet Config, so stop it
	Err = ICStop(ICInst);

    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)setHelperAppForKey:(ConstStr255Param)key withInstance:(ICInstance)ICInst
{
	OSErr		Err;
	ICAppSpec	Spec;
	ICAttr		Junk;
	long		TheSize;

	TheSize = sizeof(Spec);
	// Get the current aim helper app, to fill the Spec and TheSize variables
	Err = ICGetPref(ICInst, key, &Junk, &Spec, &TheSize);

	//Set the name and creator codes
	if (Spec.fCreator != 'AdIM'){
		Spec.name[0] = sprintf((char *) &Spec.name[1], "Adium.app");
		Spec.fCreator = 'AdIM';

		//Set the helper app to Adium
		Err = ICSetPref(ICInst, key, Junk, &Spec, TheSize);
	}
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
				NSString *name = [[[url queryArgumentForKey:@"screenname"] stringByDecodingURLEscapes] compactedString];
				if (name){
					[self _openChatToContactWithName:name
										   onService:@"AIM" 
										 withMessage:[[url queryArgumentForKey:@"message"] stringByDecodingURLEscapes]];
				}
            } else if ([[url host] caseInsensitiveCompare:@"addbuddy"] == NSOrderedSame) {
				NSString *name = [[[url queryArgumentForKey:@"screenname"] stringByDecodingURLEscapes] compactedString];				
				[[adium contactController] requestAddContactWithUID:name
															service:[[adium accountController] firstServiceWithServiceID:@"AIM"]];
			}
            
        }else if([[url scheme] isEqualToString:@"ymsgr"]){
            if([[url host] caseInsensitiveCompare:@"sendim"] == NSOrderedSame){
				NSString *name = [[[url query] stringByDecodingURLEscapes] compactedString];
                [self _openChatToContactWithName:name
									   onService:@"Yahoo!"
									 withMessage:nil];
            }
        }else if([[url scheme] isEqualToString:@"xmpp"]){
            NSString *name = [NSString stringWithFormat:@"%@@%@",[[url user] compactedString],[[url host] compactedString]];

            [self _openChatToContactWithName:name
                                                onService:@"Jabber"
                                                withMessage:nil];
        }else if ([[url scheme] isEqualToString:@"jabber"]){
			//Not an official URL scheme, used for internal applescript and such communication
			NSString *name = [[url queryArgumentForKey:@"openChatToScreenname"] compactedString];
			
			if (name){
				[self _openChatToContactWithName:name
									   onService:@"Jabber"
									 withMessage:nil];
			}
		}else if ([[url scheme] isEqualToString:@"icq"]){
			//Not an official URL scheme, used for internal applescript and such communication
			NSString *name = [[[url queryArgumentForKey:@"openChatToScreenname"] stringByDecodingURLEscapes] compactedString];
			
			if (name){
				[self _openChatToContactWithName:name
									   onService:@"ICQ"
									 withMessage:nil];
			}
		}else if ([[url scheme] isEqualToString:@"msn"]){
			//Not an official URL scheme, used for internal applescript and such communication
			NSString *name = [[url queryArgumentForKey:@"openChatToScreenname"] compactedString];
			
			if (name){
				[self _openChatToContactWithName:name
									   onService:@"MSN"
									 withMessage:nil];
			}
		}else if ([[url scheme] isEqualToString:@"adiumxtra"]){
			//Installs an adium extra
			[[XtrasInstaller installer] installXtraAtURL:url];
		}
    }
}

- (void)uninstallPlugin
{

}

- (void)_openChatToContactWithName:(NSString *)UID onService:(NSString *)serviceID withMessage:(NSString *)message
{
	AIListContact   *contact;
	
	contact = [[adium contactController] preferredContactWithUID:UID
													andServiceID:serviceID 
										   forSendingContentType:CONTENT_MESSAGE_TYPE];
	if(contact){
		//Open the chat and set it as active
		[[adium interfaceController] setActiveChat:[[adium contentController] openChatWithContact:contact]];
		
		//Insert the message text as if the user had typed it after opening the chat
		NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if(message && [responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]){
			[responder insertText:message];
		}
	}
}

@end
