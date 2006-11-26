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

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>

#import "AdiumURLHandling.h"
#import "XtrasInstaller.h"
#import "ESTextAndButtonsWindowController.h"
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIURLAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIService.h>

#define GROUP_URL_HANDLING			@"URL Handling Group"
#define KEY_DONT_PROMPT_FOR_URL		@"Don't Prompt for URL"
#define KEY_COMPLETED_FIRST_LAUNCH	@"AdiumURLHandling:CompletedFirstLaunch"

@interface AdiumURLHandling(PRIVATE)
+ (void)registerAsDefaultIMClient;
+ (void)_setHelperAppForKey:(ConstStr255Param)key withInstance:(ICInstance)ICInst;
+ (BOOL)_checkHelperAppForKey:(ConstStr255Param)key withInstance:(ICInstance)ICInst;
+ (void)_openChatToContactWithName:(NSString *)name onService:(NSString *)serviceIdentifier withMessage:(NSString *)body;
+ (void)_openAIMGroupChat:(NSString *)roomname onExchange:(int)exchange;
- (void)promptUser;
@end

@implementation AdiumURLHandling

+ (void)registerURLTypes
{
	/* TODO:
	 * Prompt the user to change Adium to be the protocol handler for aim:// and/or yahoo:// if we aren't already. Give them the option to agree, disagree, or disagree and never be asked again. 
	 */
	ICInstance ICInst;
	OSErr Err = noErr;

	//Start Internet Config, passing it Adium's creator code
	Err = ICStart(&ICInst, 'AdiM');
	if (Err == noErr) {
		//Bracket multiple calls with ICBegin() for efficiency as per documentation
		ICBegin(ICInst, icReadWritePerm);
		BOOL alreadySet = YES;

		//Configure the protocols we want.
		alreadySet &= [self _checkHelperAppForKey:(kICHelper "aim") withInstance:ICInst]; //AIM, official
		alreadySet &= [self _checkHelperAppForKey:(kICHelper "ymsgr") withInstance:ICInst]; //Yahoo!, official
		alreadySet &= [self _checkHelperAppForKey:(kICHelper "yahoo") withInstance:ICInst]; //Yahoo!, unofficial
		alreadySet &= [self _checkHelperAppForKey:(kICHelper "xmpp") withInstance:ICInst]; //Jabber, official
		alreadySet &= [self _checkHelperAppForKey:(kICHelper "jabber") withInstance:ICInst]; //Jabber, unofficial
		alreadySet &= [self _checkHelperAppForKey:(kICHelper "icq") withInstance:ICInst]; //ICQ, unofficial
		alreadySet &= [self _checkHelperAppForKey:(kICHelper "msn") withInstance:ICInst]; //MSN, unofficial
	 
		if(!alreadySet)
		{
			//Ask the user
			AdiumURLHandling *instance = [[AdiumURLHandling alloc] init];
			[instance promptUser];
			[instance release];
		}
		//Adium xtras
		[self _setHelperAppForKey:(kICHelper "adiumxtra") withInstance:ICInst];

		//End whatever it was that ICBegin() began
		ICEnd(ICInst);

		//We're done with Internet Config, so stop it
		Err = ICStop(ICInst);
		
		//How there could be an error stopping Internet Config, I don't know.
		if (Err != noErr) {
			NSLog(@"Error stopping InternetConfig. Error code: %d", Err);
		}
	} else {
		NSLog(@"Error starting InternetConfig. Error code: %d", Err);
	}
}

+ (void)registerAsDefaultIMClient
{
				ICInstance ICInst;
	OSErr Err = noErr;
	
	//Start Internet Config, passing it Adium's creator code
	Err = ICStart(&ICInst, 'AdiM');
	if (Err == noErr) {
		//Bracket multiple calls with ICBegin() for efficiency as per documentation
		ICBegin(ICInst, icReadWritePerm);
		
		//Configure the protocols we want.
		[AdiumURLHandling _setHelperAppForKey:(kICHelper "aim") withInstance:ICInst]; //AIM, official
		[AdiumURLHandling _setHelperAppForKey:(kICHelper "ymsgr") withInstance:ICInst]; //Yahoo!, official
		[AdiumURLHandling _setHelperAppForKey:(kICHelper "yahoo") withInstance:ICInst]; //Yahoo!, unofficial
		[AdiumURLHandling _setHelperAppForKey:(kICHelper "xmpp") withInstance:ICInst]; //Jabber, official
		[AdiumURLHandling _setHelperAppForKey:(kICHelper "jabber") withInstance:ICInst]; //Jabber, unofficial
		[AdiumURLHandling _setHelperAppForKey:(kICHelper "icq") withInstance:ICInst]; //ICQ, unofficial
		[AdiumURLHandling _setHelperAppForKey:(kICHelper "msn") withInstance:ICInst]; //MSN, unofficial
		
		//Adium xtras
		[AdiumURLHandling _setHelperAppForKey:(kICHelper "adiumxtra") withInstance:ICInst];
		
		//End whatever it was that ICBegin() began
		ICEnd(ICInst);
		
		//We're done with Internet Config, so stop it
		Err = ICStop(ICInst);
		
		//How there could be an error stopping Internet Config, I don't know.
		if (Err != noErr) {
			NSLog(@"Error stopping InternetConfig. Error code: %d", Err);
		}
	} else {
		NSLog(@"Error starting InternetConfig. Error code: %d", Err);
	}
}

+ (void)handleURLEvent:(NSString *)eventString
{
	NSURL				*url = [NSURL URLWithString:eventString];
	NSObject<AIAdium>	*sharedAdium = [AIObject sharedAdiumInstance];

	if (url) {
		NSString	*scheme, *newScheme;
		NSString	*serviceID;

		//make sure we have the // in ://, as it simplifies later processing.
		if (![[url resourceSpecifier] hasPrefix:@"//"]) {
			eventString = [NSString stringWithFormat:@"%@://%@", [url scheme], [url resourceSpecifier]];
			url = [NSURL URLWithString:eventString];
		}

		scheme = [url scheme];

		//map schemes to common aliases (like jabber: for xmpp:).
		static NSDictionary *schemeMappingDict = nil;
		if (!schemeMappingDict) {
			schemeMappingDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				@"ymsgr", @"yahoo",
				@"xmpp", @"jabber",
				nil];
		}
		newScheme = [schemeMappingDict objectForKey:scheme];
		if (newScheme) {
			scheme = newScheme;
			eventString = [NSString stringWithFormat:@"%@:%@", scheme, [url resourceSpecifier]];
			url = [NSURL URLWithString:eventString];
		}

		static NSDictionary	*schemeToServiceDict = nil;
		if (!schemeToServiceDict) {
			schemeToServiceDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				@"AIM",    @"aim",
				@"Yahoo!", @"ymsgr",
				@"Jabber", @"xmpp",
				@"ICQ",    @"icq",
				@"MSN",    @"msn",
				nil];
		}
		
		if ((serviceID = [schemeToServiceDict objectForKey:scheme])) {
			NSString *host = [url host];
			if ([host caseInsensitiveCompare:@"goim"] == NSOrderedSame) {
				// aim://goim?screenname=tekjew
				NSString	*name = [[[url queryArgumentForKey:@"screenname"] stringByDecodingURLEscapes] compactedString];

				if (name) {
					[self _openChatToContactWithName:name
										   onService:serviceID 
										 withMessage:[[url queryArgumentForKey:@"message"] stringByDecodingURLEscapes]];
				}

			} else if ([host caseInsensitiveCompare:@"addbuddy"] == NSOrderedSame) {
				// aim://addbuddy?screenname=tekjew
				// aim://addbuddy?listofscreennames=screen+name1,screen+name+2&groupname=buddies
				NSString	*name = [[[url queryArgumentForKey:@"screenname"] stringByDecodingURLEscapes] compactedString];
				AIService	*service = [[sharedAdium accountController] firstServiceWithServiceID:serviceID];
				
				if (name) {
					[[sharedAdium contactController] requestAddContactWithUID:name
																service:service];
					
				} else {
					NSString		*listOfNames = [url queryArgumentForKey:@"listofscreennames"];
					NSArray			*names = [listOfNames componentsSeparatedByString:@","];
					NSEnumerator	*enumerator;
					
					enumerator = [names objectEnumerator];
					while ((name = [enumerator nextObject])) {
						NSString	*decodedName = [[name stringByDecodingURLEscapes] compactedString];
						[[sharedAdium contactController] requestAddContactWithUID:decodedName
																	service:service];
					}
				}

			} else if ([host caseInsensitiveCompare:@"sendim"] == NSOrderedSame) {
				// ymsgr://sendim?tekjew
				NSString *name = [[[url query] stringByDecodingURLEscapes] compactedString];
				
				if (name) {
					[self _openChatToContactWithName:name
										   onService:serviceID
										 withMessage:nil];
				}
				
			} else if ([host caseInsensitiveCompare:@"im"] == NSOrderedSame) {
				// ymsgr://im?to=tekjew
				NSString *name = [[[url queryArgumentForKey:@"to"] stringByDecodingURLEscapes] compactedString];
				
				if (name) {
					[self _openChatToContactWithName:name
										   onService:serviceID
										 withMessage:nil];
				}
				
			} else if ([host caseInsensitiveCompare:@"gochat"]  == NSOrderedSame) {
				// aim://gochat?RoomName=AdiumRocks
				NSString	*roomname = [[url queryArgumentForKey:@"roomname"] stringByDecodingURLEscapes];
				NSString	*exchangeString = [url queryArgumentForKey:@"exchange"];
				if (roomname) {
					int exchange = 0;
					if (exchangeString) {
						exchange = [exchangeString intValue];	
					}
					
					[self _openAIMGroupChat:roomname onExchange:(exchange ? exchange : 4)];
				}

			} else if ([url queryArgumentForKey:@"openChatToScreenName"]) {
				// aim://openChatToScreenname?tekjew  [?]
				NSString *name = [[[url queryArgumentForKey:@"openChatToScreenname"] stringByDecodingURLEscapes] compactedString];
				
				if (name) {
					[self _openChatToContactWithName:name
										   onService:serviceID
										 withMessage:nil];
				}
			} else if ([host caseInsensitiveCompare:@"BuddyIcon"] == NSOrderedSame) {
				//aim:BuddyIcon?src=http://www.nbc.com//Heroes/images/wallpapers/heroes-downloads-icon-single-48x48-07.gif
				NSString *urlString = [url queryArgumentForKey:@"src"];
				if ([urlString length]) {
					NSURL *urlToDownload = [[NSURL alloc] initWithString:urlString];
					NSData *imageData = (urlToDownload ? [NSData dataWithContentsOfURL:urlToDownload] : nil);
					[urlToDownload release];
					
					//Should prompt for where to apply the icon?
					if (imageData &&
						[[[NSImage alloc] initWithData:imageData] autorelease]) {
						//If we successfully got image data, and that data makes a valid NSImage, set it as our global buddy icon
						[[[AIObject sharedAdiumInstance] preferenceController] setPreference:imageData
																					  forKey:KEY_USER_ICON
																					   group:GROUP_ACCOUNT_STATUS];
					}
				}
				
			} else {
				//Default to opening the host as a name.

				NSString	*user = [url user];
				NSString	*host = [url host];
				NSString	*name;
				if (user && [user length]) {
					// jabber://tekjew@jabber.org
					// msn://jdoe@hotmail.com
					name = [NSString stringWithFormat:@"%@@%@",[url user],[url host]];
				} else {
					// aim://tekjew
					name = host;
				}
				
				[self _openChatToContactWithName:[name compactedString]
									   onService:serviceID
									 withMessage:nil];
			}
			
		} else if ([scheme isEqualToString:@"adiumxtra"]) {
			//Installs an adium extra
			// adiumxtra://www.adiumxtras.com/path/to/xtra.zip

			[[XtrasInstaller installer] installXtraAtURL:url];
		}
	}
}

+ (void)_setHelperAppForKey:(ConstStr255Param)key withInstance:(ICInstance)ICInst
{
	OSErr		Err;
	ICAppSpec	Spec;
	ICAttr		Junk;
	long		TheSize;

	TheSize = sizeof(Spec);

	// Get the current aim helper app, to fill the Spec and TheSize variables
	Err = ICGetPref(ICInst, key, &Junk, &Spec, &TheSize);

	//Set the name and creator codes
	if (Spec.fCreator != 'AdIM') {
		Spec.name[0] = sprintf((char *) &Spec.name[1], "Adium.app");
		Spec.fCreator = 'AdIM';

		//Set the helper app to Adium
		Err = ICSetPref(ICInst, key, kICAttrNoChange, &Spec, TheSize);
	}
}

+ (BOOL)_checkHelperAppForKey:(ConstStr255Param)key withInstance:(ICInstance)ICInst
{
	OSErr		Err;
	ICAppSpec	Spec;
	ICAttr		Junk;
	long		TheSize;
	
	TheSize = sizeof(Spec);
	
	// Get the current aim helper app, to fill the Spec and TheSize variables
	Err = ICGetPref(ICInst, key, &Junk, &Spec, &TheSize);
	
	//Set the name and creator codes
	return Spec.fCreator == 'AdIM';
}

+ (void)_openChatToContactWithName:(NSString *)UID onService:(NSString *)serviceID withMessage:(NSString *)message
{
	AIListContact		*contact;
	NSObject<AIAdium>	*sharedAdium = [AIObject sharedAdiumInstance];
	
	contact = [[sharedAdium contactController] preferredContactWithUID:UID
														  andServiceID:serviceID 
												 forSendingContentType:CONTENT_MESSAGE_TYPE];
	if (contact) {
		//Open the chat and set it as active
		[[sharedAdium interfaceController] setActiveChat:[[sharedAdium chatController] openChatWithContact:contact
																						onPreferredAccount:YES]];
		
		//Insert the message text as if the user had typed it after opening the chat
		NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if (message && [responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]) {
			[responder insertText:message];
		}

	} else {
		NSBeep();
	}
}

+ (void)_openAIMGroupChat:(NSString *)roomname onExchange:(int)exchange
{
	AIAccount		*account;
	NSEnumerator	*enumerator;
	
	//Find an AIM-compatible online account which can create group chats
	enumerator = [[[[AIObject sharedAdiumInstance] accountController] accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if ([account online] &&
			[[account serviceClass] isEqualToString:@"AIM-compatible"] &&
			[[account service] canCreateGroupChats]) {
			break;
		}
	}
	
	if (roomname && account) {
		[[[AIObject sharedAdiumInstance] chatController] chatWithName:roomname
															onAccount:account
													 chatCreationInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		roomname, @"room",
																		[NSNumber numberWithInt:exchange], @"exchange",
																		nil]];
	} else {
		NSBeep();
	}
}

- (void)URLQuestion:(NSNumber *)number info:(id)info
{
	AITextAndButtonsReturnCode ret = [number intValue];
	switch(ret)
	{
		case AITextAndButtonsOtherReturn:
			[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES] forKey:KEY_DONT_PROMPT_FOR_URL group:GROUP_URL_HANDLING];
			break;
		case AITextAndButtonsDefaultReturn:
			[AdiumURLHandling registerAsDefaultIMClient];
			break;
		case AITextAndButtonsAlternateReturn:
		default:
			break;
	}
}

- (void)promptUser
{
	if ([[[adium preferenceController] preferenceForKey:KEY_COMPLETED_FIRST_LAUNCH group:GROUP_URL_HANDLING] boolValue]) {
		if(![[adium preferenceController] preferenceForKey:KEY_DONT_PROMPT_FOR_URL group:GROUP_URL_HANDLING])
			[[adium interfaceController] displayQuestion:AILocalizedString(@"Change default messaging client?", nil)
										 withDescription:AILocalizedString(@"Adium is not your default Instant Messaging client. The default client is loaded when you click messaging URLs in web pages. Would you like Adium to become the default?", nil)
										 withWindowTitle:nil
										   defaultButton:AILocalizedString(@"Yes", nil)
										 alternateButton:AILocalizedString(@"No", nil)
											 otherButton:AILocalizedString(@"Never", nil)
												  target:self
												selector:@selector(URLQuestion:info:)
												userInfo:nil];
	} else {
		//On the first launch, simply register. If the user uses another IM client which takes control of the protocols again, we'll prompt for what to do.
		[AdiumURLHandling registerAsDefaultIMClient];
		
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
											 forKey:KEY_COMPLETED_FIRST_LAUNCH
											  group:GROUP_URL_HANDLING];
	}
}

@end
