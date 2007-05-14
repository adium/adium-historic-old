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

#import "adiumPurpleConversation.h"
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIContentControllerProtocol.h>
#import <AINudgeBuzzHandlerPlugin.h>

#pragma mark Purple Images

#pragma mark Conversations
static void adiumPurpleConvCreate(PurpleConversation *conv)
{
	//Pass chats along to the account
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {
		
		AIChat *chat = groupChatLookupFromConv(conv);
		
		[accountLookup(conv->account) addChat:chat];
	}
}

static void adiumPurpleConvDestroy(PurpleConversation *conv)
{
	/* Purple is telling us a conv was destroyed.  We've probably already cleaned up, but be sure in case purple calls this
	 * when we don't ask it to (for example if we are summarily kicked from a chat room and purple closes the 'window').
	 */
	AIChat *chat;

	chat = (AIChat *)conv->ui_data;

	//Chat will be nil if we've already cleaned up, at which point no further action is needed.
	if (chat) {
		[chat setIdentifier:nil];
		[chat release];
		conv->ui_data = nil;
	}
}

static void adiumPurpleConvWriteChat(PurpleConversation *conv, const char *who,
								   const char *message, PurpleMessageFlags flags,
								   time_t mtime)
{
	/* We only care about this if:
	 *	1) It does not have the PURPLE_MESSAGE_SEND flag, which is set if Purple is sending a sent message back to us -or-
	 *  2) It is a delayed (history) message from a chat
	 */
	if (!(flags & PURPLE_MESSAGE_SEND) || (flags & PURPLE_MESSAGE_DELAYED)) {
		NSDictionary	*messageDict;
		NSString		*messageString;

		messageString = [NSString stringWithUTF8String:message];
		AILog(@"Source: %s \t Name: %s \t MyNick: %s : Message %@", 
			  who,
			  purple_conversation_get_name(conv),
			  purple_conv_chat_get_nick(PURPLE_CONV_CHAT(conv)),
			  messageString);
		if (!who || (flags & PURPLE_MESSAGE_DELAYED) || (strcmp(who, purple_conv_chat_get_nick(PURPLE_CONV_CHAT(conv))) &&
													   strcmp(who, purple_account_get_username(conv->account)))) {
			NSAttributedString	*attributedMessage = [AIHTMLDecoder decodeHTML:messageString];
			NSNumber			*purpleMessageFlags = [NSNumber numberWithInt:flags];
			NSDate				*date = [NSDate dateWithTimeIntervalSince1970:mtime];
			
			if (who && strlen(who)) {
				messageDict = [NSDictionary dictionaryWithObjectsAndKeys:attributedMessage, @"AttributedMessage",
					[NSString stringWithUTF8String:who], @"Source",
					purpleMessageFlags, @"PurpleMessageFlags",
					date, @"Date",nil];
				
			} else {
				messageDict = [NSDictionary dictionaryWithObjectsAndKeys:attributedMessage, @"AttributedMessage",
					purpleMessageFlags, @"PurpleMessageFlags",
					date, @"Date",nil];
			}
			
			[accountLookup(conv->account) receivedMultiChatMessage:messageDict
															inChat:groupChatLookupFromConv(conv)];
		}
	}
}

static void adiumPurpleConvWriteIm(PurpleConversation *conv, const char *who,
								 const char *message, PurpleMessageFlags flags,
								 time_t mtime)
{
	//We only care about this if it does not have the PURPLE_MESSAGE_SEND flag, which is set if Purple is sending a sent message back to us
	if ((flags & PURPLE_MESSAGE_SEND) == 0) {
		NSDictionary		*messageDict;
		CBPurpleAccount		*adiumAccount = accountLookup(conv->account);
		NSString			*messageString;
		AIChat				*chat;

		messageString = [NSString stringWithUTF8String:message];
		chat = imChatLookupFromConv(conv);

		PurpleDebug (@"adiumPurpleConvWriteIm: Received %@ from %@", messageString, [[chat listObject] UID]);

		//Process any purple imgstore references into real HTML tags pointing to real images
		messageString = processPurpleImages(messageString, adiumAccount);

		messageDict = [NSDictionary dictionaryWithObjectsAndKeys:messageString,@"Message",
			[NSNumber numberWithInt:flags],@"PurpleMessageFlags",
			[NSDate dateWithTimeIntervalSince1970:mtime],@"Date",nil];

		[adiumAccount receivedIMChatMessage:messageDict
									 inChat:chat];
	}
}

static void adiumPurpleConvWriteConv(PurpleConversation *conv, const char *who, const char *alias,
								   const char *message, PurpleMessageFlags flags,
								   time_t mtime)
{
	PurpleDebug (@"adiumPurpleConvWriteConv: Received %s from %s [%i]",message,who,flags);

	AIChat	*chat = nil;
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {
		chat = existingChatLookupFromConv(conv);
	} else if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_IM) {
		chat = imChatLookupFromConv(conv);
	}

	if (chat) {
		if (flags & PURPLE_MESSAGE_NOTIFY) {
			// We received a notification (nudge or buzz). Send a notification of such.

			NSString *type, *messageString = [NSString stringWithUTF8String:message];
			NSDictionary *userInfo;
			
			// Determine what we're actually notifying about.
			if ([messageString rangeOfString:@"Nudge"].location != NSNotFound) {
				type = @"Nudge";
			} else if ([messageString rangeOfString:@"Buzz"].location != NSNotFound) {
				type = @"Buzz";
			} else {
				// Just call an unknown type a "notification"
				type = @"notification";
			}
			
			userInfo = [NSDictionary dictionaryWithObjectsAndKeys:type,@"Type", nil];
			
			[[[AIObject sharedAdiumInstance] notificationCenter] postNotificationName:Chat_NudgeBuzzOccured
																			   object:chat
																			 userInfo:userInfo];
						
		} else if (flags & PURPLE_MESSAGE_SYSTEM) {
			NSString			*messageString = [NSString stringWithUTF8String:message];
			if (messageString) {
				AIChatUpdateType	updateType = -1;

				if ([messageString rangeOfString:@"timed out"].location != NSNotFound) {
					updateType = AIChatTimedOut;
				} else if ([messageString rangeOfString:@"closed the conversation"].location != NSNotFound) {
					updateType = AIChatClosedWindow;
				} else if ([messageString rangeOfString:@"Direct IM established"].location != NSNotFound) {
					//Should reorganize.. this is silly, grafted on top of the previous system which added a signal to Purple
					[accountLookup(conv->account) updateContact:[chat listObject]
													   forEvent:[NSNumber numberWithInt:PURPLE_BUDDY_DIRECTIM_CONNECTED]];

				} else if ([messageString rangeOfString:@" entered the room"].location != NSNotFound ||
						   [messageString rangeOfString:@" left the room"].location != NSNotFound) {
					//We handle entered/left messages directly via the conversation UI ops; don't display this system message
					return;

				} else if ((([messageString rangeOfString:@"Transfer of file"].location != NSNotFound) &&
								([messageString rangeOfString:@"complete"].location != NSNotFound)) ||
						   ([messageString rangeOfString:@"is offering to send file"].location != NSNotFound)) {
								//These file transfer messages are hanlded in ESFileTransferMessagesPlugin; don't show libpurple's version
					return;
				} else if (([messageString rangeOfString:@"The remote user has closed the connection."].location != NSNotFound) ||
						   ([messageString rangeOfString:@"The remote user has declined your request."].location != NSNotFound) ||
						   ([messageString rangeOfString:@"Lost connection with the remote user:"].location != NSNotFound) ||
						   ([messageString rangeOfString:@"Received invalid data on connection with remote user"].location != NSNotFound) ||
						   ([messageString rangeOfString:@"Could not establish a connection with the remote user."].location != NSNotFound)) {
					//Display the message if it's not just the one for the other guy closing it...note that this needs to be localized
					if ([messageString rangeOfString:@"The remote user has closed the connection."].location == NSNotFound) {
						[[[AIObject sharedAdiumInstance] contentController] displayEvent:messageString
																				  ofType:@"directIMDisconnected"
																				  inChat:chat];
					}
					
					[accountLookup(conv->account) updateContact:[chat listObject]
													   forEvent:[NSNumber numberWithInt:PURPLE_BUDDY_DIRECTIM_DISCONNECTED]];	
				}

				if (updateType != -1) {
					[accountLookup(conv->account) updateForChat:chat
														   type:[NSNumber numberWithInt:updateType]];
				} else {
					//If we don't know what to do with this message, display it!
					[[[AIObject sharedAdiumInstance] contentController] displayEvent:messageString
																			  ofType:@"libpurpleMessage"
																			  inChat:chat];
				}					
			}
		} else if (flags & PURPLE_MESSAGE_ERROR) {
			NSString			*messageString = [NSString stringWithUTF8String:message];
			if (messageString) {
				AIChatErrorType	errorType = -1;

				if ([messageString rangeOfString:@"Unable to send message"].location != NSNotFound) {
					/* Unable to send message = generic and AIM errors */
					if (([messageString rangeOfString:@"Not logged in"].location != NSNotFound) ||
					   ([messageString rangeOfString:@"is not online"].location != NSNotFound)) {
						errorType = AIChatMessageSendingUserNotAvailable;

					} else if ([messageString rangeOfString:@"In local permit/deny"].location != NSNotFound) {
						errorType = AIChatMessageSendingUserIsBlocked;

					} else if (([messageString rangeOfString:@"Refused by client"].location != NSNotFound) ||
							 ([messageString rangeOfString:@"message is too large"].location != NSNotFound)) {
						//XXX - there may be other conditions, but this seems the most common so that's how we'll classify it
						errorType = AIChatMessageSendingTooLarge;
					}

				} else if (([messageString rangeOfString:@"Message could not be sent"].location != NSNotFound) ||
						 ([messageString rangeOfString:@"Message may have not been sent"].location != NSNotFound)) {
					/* Message could not be sent = MSN errors */
					if (([messageString rangeOfString:@"because a time out occurred"].location != NSNotFound) ||
						([messageString rangeOfString:@"because a timeout occurred"].location != NSNotFound)) {
						errorType = AIChatMessageSendingTimeOutOccurred;

					} else if ([messageString rangeOfString:@"because the user is offline"].location != NSNotFound) {
						errorType = AIChatMessageSendingUserNotAvailable;
						
					} else if ([messageString rangeOfString:@"not allowed while invisible"].location != NSNotFound) {
						errorType = AIChatMessageSendingNotAllowedWhileInvisible;
						
					} else if (([messageString rangeOfString:@"because a connection error occurred"].location != NSNotFound) ||
							 ([messageString rangeOfString:@"because an error with the switchboard"].location != NSNotFound)) {
						errorType = AIChatMessageSendingConnectionError;
					}

				} else if ([messageString rangeOfString:@"You missed"].location != NSNotFound) {
					if (([messageString rangeOfString:@"because they were too large"].location != NSNotFound) ||
						([messageString rangeOfString:@"because it was too large"].location != NSNotFound)) {
						//The actual message when on AIM via libpurple is "You missed 2 messages" but this is a lie.
						errorType = AIChatMessageReceivingMissedTooLarge;

					} else if (([messageString rangeOfString:@"because it was invalid"].location != NSNotFound) ||
							 ([messageString rangeOfString:@"because they were invalid"].location != NSNotFound)) {
						errorType = AIChatMessageReceivingMissedInvalid;

					} else if ([messageString rangeOfString:@"because the rate limit has been exceeded"].location != NSNotFound) {
						errorType = AIChatMessageReceivingMissedRateLimitExceeded;

					} else if ([messageString rangeOfString:@"because he/she was too evil"].location != NSNotFound) {
						errorType = AIChatMessageReceivingMissedRemoteIsTooEvil;

					} else if ([messageString rangeOfString:@"because you are too evil"].location != NSNotFound) {
						errorType = AIChatMessageReceivingMissedLocalIsTooEvil;

					}

				} else if ([messageString isEqualToString:@"Command failed"]) {
					errorType = AIChatCommandFailed;

				} else if ([messageString isEqualToString:@"Wrong number of arguments"]) {
					errorType = AIChatInvalidNumberOfArguments;

				} else if ([messageString rangeOfString:@"transfer"].location != NSNotFound) {
					//Ignore the transfer errors; we will handle them locally
					errorType = -2;

				} else if ([messageString rangeOfString:@"User information not available"].location != NSNotFound) {
					//Ignore user information errors; they are irrelevent
					errorType = -2;
				}

				if (errorType == -1) {
					errorType = AIChatUnknownError;
				}

				if (errorType != -2) {
					if (errorType != AIChatUnknownError) {
						[accountLookup(conv->account) errorForChat:chat
															  type:[NSNumber numberWithInt:errorType]];
					} else {
						//If we don't know what to do with this message, display it!
						[[[AIObject sharedAdiumInstance] contentController] displayEvent:messageString
																				  ofType:@"libpurpleMessage"
																				  inChat:chat];						
					}
				}

				PurpleDebug (@"*** Conversation error type %i (%@): %@",
						   errorType,
						   ([chat listObject] ? [[chat listObject] UID] : [chat name]),messageString);
			}
		}
	}
}

static void adiumPurpleConvChatAddUsers(PurpleConversation *conv, GList *cbuddies, gboolean new_arrivals)
{
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {
		NSMutableArray	*usersArray = [NSMutableArray array];
		NSMutableArray	*flagsArray = [NSMutableArray array];
		NSMutableArray	*aliasesArray = [NSMutableArray array];
		
		GList *l;
		for (l = cbuddies; l != NULL; l = l->next) {
			PurpleConvChatBuddy *chatBuddy = (PurpleConvChatBuddy *)l->data;
			
			[usersArray addObject:[NSString stringWithUTF8String:chatBuddy->name]];
			[aliasesArray addObject:(chatBuddy->alias ? [NSString stringWithUTF8String:chatBuddy->alias] : @"")];
			[flagsArray addObject:[NSNumber numberWithInt:GPOINTER_TO_INT(chatBuddy->flags)]];
		}

		[accountLookup(conv->account) addUsersArray:usersArray
										  withFlags:flagsArray
										 andAliases:aliasesArray
										newArrivals:[NSNumber numberWithBool:new_arrivals]
											 toChat:existingChatLookupFromConv(conv)];
		
	} else {
		PurpleDebug (@"adiumPurpleConvChatAddUsers: IM");
	}
}

static void adiumPurpleConvChatRenameUser(PurpleConversation *conv, const char *oldName,
										const char *newName, const char *newAlias)
{
	PurpleDebug (@"adiumPurpleConvChatRenameUser: %s: oldName %s, newName %s, newAlias %s",
			   purple_conversation_get_name(conv),
			   oldName, newName, newAlias);
}

static void adiumPurpleConvChatRemoveUsers(PurpleConversation *conv, GList *users)
{
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {
		NSMutableArray	*usersArray = [NSMutableArray array];

		GList *l;
		for (l = users; l != NULL; l = l->next) {
			[usersArray addObject:[NSString stringWithUTF8String:purple_normalize(conv->account, (char *)l->data)]];
		}

		[accountLookup(conv->account) removeUsersArray:usersArray
											  fromChat:existingChatLookupFromConv(conv)];

	} else {
		PurpleDebug (@"adiumPurpleConvChatRemoveUser: IM");
	}
}

static void adiumPurpleConvUpdateUser(PurpleConversation *conv, const char *user)
{
	PurpleDebug (@"adiumPurpleConvUpdateUser: %s",user);
}

static void adiumPurpleConvPresent(PurpleConversation *conv)
{
	
}

//This isn't a function we want Purple doing anything with, I don't think
static gboolean adiumPurpleConvHasFocus(PurpleConversation *conv)
{
	return NO;
}

static void adiumPurpleConvUpdated(PurpleConversation *conv, PurpleConvUpdateType type)
{
	if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_CHAT) {
		PurpleConvChat  *chat = purple_conversation_get_chat_data(conv);
		
		switch(type) {
			case PURPLE_CONV_UPDATE_TOPIC:
				[accountLookup(conv->account) updateTopic:(purple_conv_chat_get_topic(chat) ?
														   [NSString stringWithUTF8String:purple_conv_chat_get_topic(chat)] :
														   nil)
												  forChat:existingChatLookupFromConv(conv)];
				break;
			case PURPLE_CONV_UPDATE_TITLE:
				[accountLookup(conv->account) updateTitle:(purple_conversation_get_title(conv) ?
														   [NSString stringWithUTF8String:purple_conversation_get_title(conv)] :
														   nil)
												  forChat:existingChatLookupFromConv(conv)];
				
				PurpleDebug (@"Update to title: %s",purple_conversation_get_title(conv));
				break;
			case PURPLE_CONV_UPDATE_CHATLEFT:
				PurpleDebug (@"Chat left! %s",purple_conversation_get_name(conv));
				break;
			case PURPLE_CONV_UPDATE_ADD:
			case PURPLE_CONV_UPDATE_REMOVE:
			case PURPLE_CONV_UPDATE_ACCOUNT:
			case PURPLE_CONV_UPDATE_TYPING:
			case PURPLE_CONV_UPDATE_UNSEEN:
			case PURPLE_CONV_UPDATE_LOGGING:
			case PURPLE_CONV_ACCOUNT_ONLINE:
			case PURPLE_CONV_ACCOUNT_OFFLINE:
			case PURPLE_CONV_UPDATE_AWAY:
			case PURPLE_CONV_UPDATE_ICON:
			case PURPLE_CONV_UPDATE_FEATURES:

/*				
				[accountLookup(conv->account) mainPerformSelector:@selector(convUpdateForChat:type:)
													   withObject:existingChatLookupFromConv(conv)
													   withObject:[NSNumber numberWithInt:type]];
*/				
			default:
				break;
		}

	} else if (purple_conversation_get_type(conv) == PURPLE_CONV_TYPE_IM) {
		PurpleConvIm  *im = purple_conversation_get_im_data(conv);
		switch (type) {
			case PURPLE_CONV_UPDATE_TYPING: {

				AITypingState typingState;

				switch (purple_conv_im_get_typing_state(im)) {
					case PURPLE_TYPING:
						typingState = AITyping;
						break;
					case PURPLE_TYPED:
						typingState = AIEnteredText;
						break;
					case PURPLE_NOT_TYPING:
					default:
						typingState = AINotTyping;
						break;
				}

				NSNumber	*typingStateNumber = [NSNumber numberWithInt:typingState];

				[accountLookup(conv->account) typingUpdateForIMChat:imChatLookupFromConv(conv)
															 typing:typingStateNumber];
				break;
			}
			case PURPLE_CONV_UPDATE_AWAY: {
				//If the conversation update is UPDATE_AWAY, it seems to suppress the typing state being updated
				//Reset purple's typing tracking, then update to receive a PURPLE_CONV_UPDATE_TYPING message
				purple_conv_im_set_typing_state(im, PURPLE_NOT_TYPING);
				purple_conv_im_update_typing(im);
				break;
			}
			default:
				break;
		}
	}
}

#pragma mark Custom smileys
gboolean adiumPurpleConvCustomSmileyAdd(PurpleConversation *conv, const char *smile, gboolean remote)
{
	PurpleDebug (@"%s: Added Custom Smiley %s",purple_conversation_get_name(conv),smile);
	[accountLookup(conv->account) chat:chatLookupFromConv(conv)
			 isWaitingOnCustomEmoticon:[NSString stringWithUTF8String:smile]];

	return TRUE;
}

void adiumPurpleConvCustomSmileyWrite(PurpleConversation *conv, const char *smile,
									const guchar *data, gsize size)
{
	PurpleDebug (@"%s: Write Custom Smiley %s (%x %i)",purple_conversation_get_name(conv),smile,data,size);

	[accountLookup(conv->account) chat:chatLookupFromConv(conv)
					 setCustomEmoticon:[NSString stringWithUTF8String:smile]
						 withImageData:[NSData dataWithBytes:data
													  length:size]];
}

void adiumPurpleConvCustomSmileyClose(PurpleConversation *conv, const char *smile)
{
	PurpleDebug (@"%s: Close Custom Smiley %s",purple_conversation_get_name(conv),smile);

	[accountLookup(conv->account) chat:chatLookupFromConv(conv)
				  closedCustomEmoticon:[NSString stringWithUTF8String:smile]];
}

static PurpleConversationUiOps adiumPurpleConversationOps = {
	adiumPurpleConvCreate,
    adiumPurpleConvDestroy,
    adiumPurpleConvWriteChat,
    adiumPurpleConvWriteIm,
    adiumPurpleConvWriteConv,
    adiumPurpleConvChatAddUsers,
    adiumPurpleConvChatRenameUser,
    adiumPurpleConvChatRemoveUsers,
	adiumPurpleConvUpdateUser,
	
	adiumPurpleConvPresent,
	adiumPurpleConvHasFocus,

	/* Custom Smileys */
	adiumPurpleConvCustomSmileyAdd,
	adiumPurpleConvCustomSmileyWrite,
	adiumPurpleConvCustomSmileyClose,
};

PurpleConversationUiOps *adium_purple_conversation_get_ui_ops(void)
{
	return &adiumPurpleConversationOps;
}

void adiumPurpleConversation_init(void)
{	
	purple_conversations_set_ui_ops(adium_purple_conversation_get_ui_ops());

	purple_signal_connect_priority(purple_conversations_get_handle(), "conversation-updated", adium_purple_get_handle(),
								 PURPLE_CALLBACK(adiumPurpleConvUpdated), NULL,
								 PURPLE_SIGNAL_PRIORITY_LOWEST);
	
}
