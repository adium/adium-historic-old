/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIInterfaceController.h"
#import "CBURLHandlingPlugin.h"
#import "XtrasInstaller.h"
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/ESURLAdditions.h>
#import <Adium/AIContentMessage.h>

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
	
	//Configure the protocols we want.  Note that this file needs to remain in MacRoman encoding for that ¥ (option-8)
	//to be recognized properly.
	[self setHelperAppForKey:"\pHelper¥aim" withInstance:ICInst]; //AIM, official
	[self setHelperAppForKey:"\pHelper¥ymsgr" withInstance:ICInst]; //Yahoo!, official
	[self setHelperAppForKey:"\pHelper¥xmpp" withInstance:ICInst]; //Jabber, official
	[self setHelperAppForKey:"\pHelper¥jabber" withInstance:ICInst]; //Jabber, unofficial
	[self setHelperAppForKey:"\pHelper¥icq" withInstance:ICInst]; //ICQ, unofficial
	[self setHelperAppForKey:"\pHelper¥msn" withInstance:ICInst]; //MSN, unofficial

	//Adium xtras
	[self setHelperAppForKey:"\pHelper¥adiumxtra" withInstance:ICInst];

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
	NSString *string = [[event descriptorAtIndex:1] stringValue];
	NSURL *url = [NSURL URLWithString:string];

	if(url){
		NSString	*scheme;
		NSString	*service;
		
		static NSDictionary	*schemeToServiceDict = nil;
		if(!schemeToServiceDict){
			schemeToServiceDict = [[NSDictionary dictionaryWithObjectsAndKeys:
				@"AIM", @"aim",
				@"Yahoo!", @"ymsgr",
				@"Yahoo!", @"yahoo"
				@"Jabber", @"jabber",
				@"ICQ", @"icq",
				@"MSN", @"msn",
				nil] retain];
		}
		
		if(![[url resourceSpecifier] hasPrefix:@"//"]){
			string = [NSString stringWithFormat:@"%@://%@", [url scheme], [url resourceSpecifier]];
			url = [NSURL URLWithString:string];
		}
		
		scheme = [url scheme];

		if(service = [schemeToServiceDict objectForKey:scheme]){
			if([[url host] caseInsensitiveCompare:@"goim"] == NSOrderedSame){
				// aim://goim?screenname=tekjew
				NSString *name = [[[url queryArgumentForKey:@"screenname"] stringByDecodingURLEscapes] compactedString];
				if (name){
					[self _openChatToContactWithName:name
										   onService:service 
										 withMessage:[[url queryArgumentForKey:@"message"] stringByDecodingURLEscapes]];
				}
				
			}else if ([[url host] caseInsensitiveCompare:@"addbuddy"] == NSOrderedSame) {
				// aim://addbuddy?screenname=tekjew
				NSString *name = [[[url queryArgumentForKey:@"screenname"] stringByDecodingURLEscapes] compactedString];				
				[[adium contactController] requestAddContactWithUID:name
															service:[[adium accountController] firstServiceWithServiceID:service]];

			}else if([[url host] caseInsensitiveCompare:@"sendim"] == NSOrderedSame){
				// ymsgr://sendim?tekjew
				NSString *name = [[[url query] stringByDecodingURLEscapes] compactedString];
				[self _openChatToContactWithName:name
									   onService:service
									 withMessage:nil];
				
			}else if([url queryArgumentForKey:@"openChatToScreenName"]){
				// aim://openChatToScreenname?tekjew  [?]
				NSString *name = [[url queryArgumentForKey:@"openChatToScreenname"] compactedString];
				
				if (name){
					[self _openChatToContactWithName:name
										   onService:service
										 withMessage:nil];
				}
			}else{
				//Default to opening the host as a name.

				NSString	*user = [url user];
				NSString	*host = [url host];
				NSString	*name;
				if(user && [user length]){
					// jabber://tekjew@jabber.org
					name = [NSString stringWithFormat:@"%@@%@",[url user],[url host]];
				}else{
					// aim://tekjew
					name = host;
				}
				
				[self _openChatToContactWithName:[name compactedString]
									   onService:service
									 withMessage:nil];
			}
			
		}else if([scheme isEqualToString:@"xmpp"]){
			// xmpp://tekjew@jabber.com
			NSString *name = [NSString stringWithFormat:@"%@@%@",[url user],[url host]];
			
			[self _openChatToContactWithName:[name compactedString]
								   onService:@"Jabber"
								 withMessage:nil];

		}else if ([scheme isEqualToString:@"adiumxtra"]){
			//Installs an adium extra
			// adiumxtra://www.adiumxtras.com/path/to/xtra.zip

			[[XtrasInstaller installer] installXtraAtURL:url];
		}
	}
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
