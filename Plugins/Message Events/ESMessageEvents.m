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
	//Observe chat changes
	[[adium contentController] registerChatObserver:self];
}

#pragma mark Message event handling
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
