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

#import "AIContentController.h"
#import "ESMessageEvents.h"
#import <Adium/AIAdium.h>
#import <Adium/AIChat.h>
#import <Adium/AIListContact.h>

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
		AIListContact	*listObject = [inChat listObject];
		
		if ([inChat statusObjectForKey:KEY_CHAT_ERROR] != nil){
		
			AIChatErrorType errorType = [inChat integerStatusObjectForKey:KEY_CHAT_ERROR];
			type = @"chat-error";

			switch(errorType){
				case AIChatUnknownError:
					message = [NSString stringWithFormat:AILocalizedString(@"Unknown conversation error.",nil)];
					break;
					
				case AIChatMessageSendingUserNotAvailable:
					message = [NSString stringWithFormat:AILocalizedString(@"Could not send because %@ is not available.",nil),[listObject formattedUID]];
					break;
				
				case AIChatMessageSendingUserIsBlocked:
					message = [NSString stringWithFormat:AILocalizedString(@"Could not send because %@ is blocked.",nil),[listObject formattedUID]];
					break;

				case AIChatMessageSendingTooLarge:
					message = AILocalizedString(@"Could not send the last message because it was too large.",nil);
					break;
					
				case AIChatMessageSendingTimeOutOccurred:
					message = AILocalizedString(@"A message may not have been sent; a timeout occurred.",nil);
					break;

				case AIChatMessageReceivingMissedTooLarge:
					message = AILocalizedString(@"Could not receive the last message because it was too large.",nil);
					break;
					
				case AIChatMessageReceivingMissedInvalid:
					message = AILocalizedString(@"Could not receive the last message because it was invalid.",nil);
					break;
					
				case AIChatMessageReceivingMissedRateLimitExceeded:
					message = AILocalizedString(@"Could not receive because the rate limit has been exceeded.",nil);
					break;

				case AIChatMessageReceivingMissedRemoteIsTooEvil:
					message = [NSString stringWithFormat:AILocalizedString(@"Could not receive; %@ is too evil.",nil),[listObject formattedUID]];

					break;
				case AIChatMessageReceivingMissedLocalIsTooEvil:
					message = AILocalizedString(@"Could not receive: you are too evil.",nil);
					break;
				
				case AIChatCommandFailed:
					message = AILocalizedString(@"Command failed.",nil);
					break;
				
				case AIChatInvalidNumberOfArguments:
					message = AILocalizedString(@"Incorrect number of command argments.",nil);
					break;
					
				case AIChatMessageSendingConnectionError:
					message = AILocalizedString(@"Could not send; a connection error occurred.",nil);
					break;
					
				case AIChatMessageSendingNotAllowedWhileInvisible:
					message = AILocalizedString(@"Could not send; not allowed while invisible.",nil);
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
			[[adium contentController] displayStatusMessage:message
													 ofType:type
													 inChat:inChat];
		}
	}
	
	return(nil);
}

@end
