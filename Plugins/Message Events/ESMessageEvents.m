//
//  ESMessageEvents.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 27 2004.
//

#import "ESMessageEvents.h"

@implementation ESMessageEvents

- (void)installPlugin
{
	//Register the events we generate
	[[adium contactAlertsController] registerEventID:CONTENT_MESSAGE_SENT withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	[[adium contactAlertsController] registerEventID:CONTENT_MESSAGE_RECEIVED withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	[[adium contactAlertsController] registerEventID:CONTENT_MESSAGE_RECEIVED_FIRST withHandler:self inGroup:AIMessageEventHandlerGroup globalOnly:NO];
	
	//Install our observers
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(handleMessageEvent:) 
									   name:Content_DidSendContent 
									 object:nil];
    [[adium notificationCenter] addObserver:self
								   selector:@selector(handleMessageEvent:) 
									   name:Content_DidReceiveContent
									 object:nil];
    [[adium notificationCenter] addObserver:self 
								   selector:@selector(handleMessageEvent:)
									   name:Content_FirstContentRecieved 
									 object:nil];

	//Observe chat changes
	[[adium contentController] registerChatObserver:self];
}

- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTENT_MESSAGE_SENT]){
		description = AILocalizedString(@"Is sent a message",nil);
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]){
		description = AILocalizedString(@"Sends a message",nil);
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]){
		description = AILocalizedString(@"Sends an initial message",nil);
	}else{
		description = @"";
	}
	
	return(description);
}

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTENT_MESSAGE_SENT]){
		description = AILocalizedString(@"You sent a message",nil);
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]){
		description = AILocalizedString(@"You receive any message",nil);
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]){
		description = AILocalizedString(@"You receive an initial message",nil);
	}else{
		description = @"";
	}
	
	return(description);
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if([eventID isEqualToString:CONTENT_MESSAGE_SENT]){
		description = @"Message Sent";
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]){
		description = @"Message Received";
	}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]){
		description = @"Message Received (New)";
	}else{
		description = @"";
	}
	
	return(description);
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{
	NSString	*description = nil;
	
	if(listObject){
		NSString	*name;
		NSString	*format;
		
		if([eventID isEqualToString:CONTENT_MESSAGE_SENT]){
			format = AILocalizedString(@"When you send %@ a message",nil);
		}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]){
			format = AILocalizedString(@"When %@ sends a message to you",nil);
		}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]){
			format = AILocalizedString(@"When %@ sends an initial message to you",nil);
		}else{
			format = nil;
		}
		
		if(format){
			name = ([listObject isKindOfClass:[AIListGroup class]] ?
					[NSString stringWithFormat:AILocalizedString(@"a member of %@",nil),[listObject displayName]] :
					[listObject displayName]);
			
			description = [NSString stringWithFormat:format, name];
		}
			
	}else{
		if([eventID isEqualToString:CONTENT_MESSAGE_SENT]){
			description = AILocalizedString(@"When you send a message",nil);
		}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED]){
			description = AILocalizedString(@"When you receive any message",nil);
		}else if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST]){
			description = AILocalizedString(@"When you receive an initial message",nil);
		}
	}

	return(description);
}

- (void)handleMessageEvent:(NSNotification *)notification
{
	AIChat			*chat = [notification object];
	AIListObject	*listObject = [chat listObject];
	
	if ([[notification name] isEqualToString:Content_DidSendContent]){
		[[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_SENT
										 forListObject:listObject
											  userInfo:chat];

	}else if ([[notification name] isEqualToString:Content_DidReceiveContent]){
		[[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED
										 forListObject:listObject
											  userInfo:chat];
		
	}else if ([[notification name] isEqualToString:Content_FirstContentRecieved]){
		[[adium contactAlertsController] generateEvent:CONTENT_MESSAGE_RECEIVED_FIRST
										 forListObject:listObject
											  userInfo:chat];

	}
}


- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (inModifiedKeys == nil ||
		[inModifiedKeys containsObject:KEY_CHAT_TIMED_OUT] ||
		[inModifiedKeys containsObject:KEY_CHAT_CLOSED_WINDOW] ||
		[inModifiedKeys containsObject:KEY_CHAT_ERROR]){

		NSString		*message = nil;
		NSString		*type = nil;
		AIListObject	*listObject = [inChat listObject];
		AIContentStatus	*content;
		
		if ([inChat statusObjectForKey:KEY_CHAT_ERROR] != nil){
		
			AIChatErrorType errorType = [inChat integerStatusObjectForKey:KEY_CHAT_ERROR];
			switch(errorType){
				case AIChatUnknownError:
					message = [NSString stringWithFormat:AILocalizedString(@"Unknown conversation error.",nil)];
					type = @"unknown-error";
					break;
					
				case AIChatUserNotAvailable:
					message = [NSString stringWithFormat:AILocalizedString(@"Could not send because %@ is not available.",nil),[listObject formattedUID]];
					type = @"user-unavailable";
					break;
				
				case AIChatMessageSendingTooLarge:
					message = AILocalizedString(@"Could not send the last message because it was too large.",nil);
					type = @"sending-tooLarge";
					break;

				case AIChatMessageReceivingMissedTooLarge:
					message = AILocalizedString(@"Could not receive the last message because it was too large.",nil);
					type = @"missed-tooLarge";
					break;
					
				case AIChatMessageReceivingMissedInvalid:
					message = AILocalizedString(@"Could not receive the last message because it was invalid.",nil);
					type = @"missed-invalid";
					break;
					
				case AIChatMessageReceivingMissedRateLimitExceeded:
					message = AILocalizedString(@"Could not receive because the rate limit has been exceeded.",nil);
					type = @"missed-ratelimit";

					break;
				case AIChatMessageReceivingMissedRemoteIsTooEvil:
					message = [NSString stringWithFormat:AILocalizedString(@"Could not receive; %@ is too evil.",nil),[listObject formattedUID]];
					type = @"missed-remoteTooEvil";

					break;
				case AIChatMessageReceivingMissedLocalIsTooEvil:
					message = AILocalizedString(@"Could not receive: you are too evil.",nil);
					type = @"missed-localTooEvil";

					break;
				
				case AIChatCommandFailed:
					message = AILocalizedString(@"Command failed.",nil);
					type = @"command-failed";
					
					break;
				
				case AIChatInvalidNumberOfArguments:
					message = AILocalizedString(@"Incorrect number of command argments.",nil);
					type = @"command-incorrect-arguments";
					
					break;
			}
			
		}else if ([inChat integerStatusObjectForKey:KEY_CHAT_CLOSED_WINDOW] && listObject){
			message = [NSString stringWithFormat:AILocalizedString(@"%@ closed the conversation window.",nil),[listObject displayName]];
			type = @"closed";
		}else if ([inChat integerStatusObjectForKey:KEY_CHAT_TIMED_OUT] && listObject){
			message = [NSString stringWithFormat:AILocalizedString(@"The conversation with %@ timed out.",nil),[listObject displayName]];			
			type = @"timed_out";
		}
		
		if (message){
			//Create our content object
			content = [AIContentStatus statusInChat:inChat
										 withSource:listObject
										destination:[inChat account]
											   date:[NSDate date]
											message:[[[NSAttributedString alloc] initWithString:message
																					 attributes:[[adium contentController] defaultFormattingAttributes]] autorelease]
										   withType:type];
			
			//Add the object
			[[adium contentController] receiveContentObject:content];
		}
	}
	
	return(nil);
}

@end
