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

#import "adiumGaimConversation.h"
#import <AIUtilities/AIObjectAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIContentControllerProtocol.h>

#pragma mark Gaim Images

#pragma mark Conversations
static void adiumGaimConvCreate(GaimConversation *conv)
{
	//Pass chats along to the account
	if (gaim_conversation_get_type(conv) == GAIM_CONV_TYPE_CHAT) {
		
		AIChat *chat = groupChatLookupFromConv(conv);
		
		[accountLookup(conv->account) addChat:chat];
	}
}

static void adiumGaimConvDestroy(GaimConversation *conv)
{
	//Gaim is telling us a conv was destroyed.  We've probably already cleaned up, but be sure in case gaim calls this
	//when we don't ask it to (for example if we are summarily kicked from a chat room and gaim closes the 'window').
	AIChat *chat;

	chat = (AIChat *)conv->ui_data;

	//Chat will be nil if we've already cleaned up, at which point no further action is needed.
	if (chat) {
		//The chat's uniqueChatID may have changed before we got here.  Make sure we are talking about the proper conv
		//before removing its NSValue from the chatDict
		NSMutableDictionary	*chatDict = get_chatDict();
		if (conv == [[chatDict objectForKey:[chat uniqueChatID]] pointerValue]) {
			[chatDict removeObjectForKey:[chat uniqueChatID]];
		}

		[chat release];
		conv->ui_data = nil;
	}
}

static void adiumGaimConvWriteChat(GaimConversation *conv, const char *who,
								   const char *message, GaimMessageFlags flags,
								   time_t mtime)
{
	/* We only care about this if:
	 *	1) It does not have the GAIM_MESSAGE_SEND flag, which is set if Gaim is sending a sent message back to us -or-
	 *  2) It is a delayed (history) message from a chat
	 */
	if (!(flags & GAIM_MESSAGE_SEND) || (flags & GAIM_MESSAGE_DELAYED)) {
		NSDictionary	*messageDict;
		NSString		*messageString;

		messageString = [NSString stringWithUTF8String:message];
		AILog(@"Source: %s \t Name: %s \t MyNick: %s : Message %@", 
			  who,
			  gaim_conversation_get_name(conv),
			  gaim_conv_chat_get_nick(GAIM_CONV_CHAT(conv)),
			  messageString);
		if (!who || (flags & GAIM_MESSAGE_DELAYED) || (strcmp(who, gaim_conv_chat_get_nick(GAIM_CONV_CHAT(conv))) &&
													   strcmp(who, gaim_account_get_username(conv->account)))) {
			NSAttributedString	*attributedMessage = [AIHTMLDecoder decodeHTML:messageString];
			NSNumber			*gaimMessageFlags = [NSNumber numberWithInt:flags];
			NSDate				*date = [NSDate dateWithTimeIntervalSince1970:mtime];
			
			if (who && strlen(who)) {
				messageDict = [NSDictionary dictionaryWithObjectsAndKeys:attributedMessage, @"AttributedMessage",
					[NSString stringWithUTF8String:who], @"Source",
					gaimMessageFlags, @"GaimMessageFlags",
					date, @"Date",nil];
				
			} else {
				messageDict = [NSDictionary dictionaryWithObjectsAndKeys:attributedMessage, @"AttributedMessage",
					gaimMessageFlags, @"GaimMessageFlags",
					date, @"Date",nil];
			}
			
			[accountLookup(conv->account) receivedMultiChatMessage:messageDict
															inChat:groupChatLookupFromConv(conv)];
		}
	}
}

static void adiumGaimConvWriteIm(GaimConversation *conv, const char *who,
								 const char *message, GaimMessageFlags flags,
								 time_t mtime)
{
	//We only care about this if it does not have the GAIM_MESSAGE_SEND flag, which is set if Gaim is sending a sent message back to us
	if ((flags & GAIM_MESSAGE_SEND) == 0) {
		NSDictionary		*messageDict;
		CBGaimAccount		*adiumAccount = accountLookup(conv->account);
		NSString			*messageString;
		AIChat				*chat;

		messageString = [NSString stringWithUTF8String:message];
		chat = imChatLookupFromConv(conv);

		GaimDebug (@"adiumGaimConvWriteIm: Received %@ from %@", messageString, [[chat listObject] UID]);

		//Process any gaim imgstore references into real HTML tags pointing to real images
		messageString = processGaimImages(messageString, adiumAccount);

		messageDict = [NSDictionary dictionaryWithObjectsAndKeys:messageString,@"Message",
			[NSNumber numberWithInt:flags],@"GaimMessageFlags",
			[NSDate dateWithTimeIntervalSince1970:mtime],@"Date",nil];

		[adiumAccount receivedIMChatMessage:messageDict
									 inChat:chat];
	}
}

static void adiumGaimConvWriteConv(GaimConversation *conv, const char *who, const char *alias,
								   const char *message, GaimMessageFlags flags,
								   time_t mtime)
{
	GaimDebug (@"adiumGaimConvWriteConv: Received %s from %s [%i]",message,who,flags);

	AIChat	*chat = nil;
	if (gaim_conversation_get_type(conv) == GAIM_CONV_TYPE_CHAT) {
		chat = existingChatLookupFromConv(conv);
	} else if (gaim_conversation_get_type(conv) == GAIM_CONV_TYPE_IM) {
		chat = imChatLookupFromConv(conv);
	}

	if (chat) {
		if (flags & GAIM_MESSAGE_SYSTEM) {
			NSString			*messageString = [NSString stringWithUTF8String:message];
			if (messageString) {
				AIChatUpdateType	updateType = -1;

				if ([messageString rangeOfString:@"timed out"].location != NSNotFound) {
					updateType = AIChatTimedOut;
				} else if ([messageString rangeOfString:@"closed the conversation"].location != NSNotFound) {
					updateType = AIChatClosedWindow;
				} else if ([messageString rangeOfString:@"Direct IM established"].location != NSNotFound) {
					//Should reorganize.. this is silly, grafted on top of the previous system which added a signal to Gaim
					[accountLookup(conv->account) updateContact:[chat listObject]
													   forEvent:[NSNumber numberWithInt:GAIM_BUDDY_DIRECTIM_CONNECTED]];

				} else if ([messageString rangeOfString:@" entered the room"].location != NSNotFound ||
						   [messageString rangeOfString:@" left the room"].location != NSNotFound) {
					//We handle entered/left messages directly via the conversation UI ops; don't display this system message
					return;

				} else if ((([messageString rangeOfString:@"Transfer of file"].location != NSNotFound) &&
								([messageString rangeOfString:@"complete"].location != NSNotFound)) ||
						   ([messageString rangeOfString:@"is offering to send file"].location != NSNotFound)) {
								//These file transfer messages are hanlded in ESFileTransferMessagesPlugin; don't show libgaim's version
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
													   forEvent:[NSNumber numberWithInt:GAIM_BUDDY_DIRECTIM_DISCONNECTED]];	
				}

				if (updateType != -1) {
					[accountLookup(conv->account) updateForChat:chat
														   type:[NSNumber numberWithInt:updateType]];
				} else {
					//If we don't know what to do with this message, display it!
					[[[AIObject sharedAdiumInstance] contentController] displayEvent:messageString
																			  ofType:@"libgaimMessage"
																			  inChat:chat];
				}					
			}
		} else if (flags & GAIM_MESSAGE_ERROR) {
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
						//The actual message when on AIM via libgaim is "You missed 2 messages" but this is a lie.
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
																				  ofType:@"libgaimMessage"
																				  inChat:chat];						
					}
				}

				GaimDebug (@"*** Conversation error type %i (%@): %@",
						   errorType,
						   ([chat listObject] ? [[chat listObject] UID] : [chat name]),messageString);
			}
		}
	}
}

static void adiumGaimConvChatAddUsers(GaimConversation *conv, GList *cbuddies, gboolean new_arrivals)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_TYPE_CHAT) {
		NSMutableArray	*usersArray = [NSMutableArray array];
		NSMutableArray	*flagsArray = [NSMutableArray array];
		NSMutableArray	*aliasesArray = [NSMutableArray array];
		
		GList *l;
		for (l = cbuddies; l != NULL; l = l->next) {
			GaimConvChatBuddy *chatBuddy = (GaimConvChatBuddy *)l->data;
			
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
		GaimDebug (@"adiumGaimConvChatAddUsers: IM");
	}
}

static void adiumGaimConvChatRenameUser(GaimConversation *conv, const char *oldName,
										const char *newName, const char *newAlias)
{
	GaimDebug (@"adiumGaimConvChatRenameUser: %s: oldName %s, newName %s, newAlias %s",
			   gaim_conversation_get_name(conv),
			   oldName, newName, newAlias);
}

static void adiumGaimConvChatRemoveUsers(GaimConversation *conv, GList *users)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_TYPE_CHAT) {
		NSMutableArray	*usersArray = [NSMutableArray array];

		GList *l;
		for (l = users; l != NULL; l = l->next) {
			[usersArray addObject:[NSString stringWithUTF8String:gaim_normalize(conv->account, (char *)l->data)]];
		}

		[accountLookup(conv->account) removeUsersArray:usersArray
											  fromChat:existingChatLookupFromConv(conv)];

	} else {
		GaimDebug (@"adiumGaimConvChatRemoveUser: IM");
	}
}

static void adiumGaimConvUpdateUser(GaimConversation *conv, const char *user)
{
	GaimDebug (@"adiumGaimConvUpdateUser: %s",user);
}

static void adiumGaimConvPresent(GaimConversation *conv)
{
	
}

//This isn't a function we want Gaim doing anything with, I don't think
static gboolean adiumGaimConvHasFocus(GaimConversation *conv)
{
	return NO;
}

static void adiumGaimConvUpdated(GaimConversation *conv, GaimConvUpdateType type)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_TYPE_CHAT) {
		GaimConvChat  *chat = gaim_conversation_get_chat_data(conv);
		
		switch(type) {
			case GAIM_CONV_UPDATE_TOPIC:
				[accountLookup(conv->account) updateTopic:(gaim_conv_chat_get_topic(chat) ?
														   [NSString stringWithUTF8String:gaim_conv_chat_get_topic(chat)] :
														   nil)
												  forChat:existingChatLookupFromConv(conv)];
				break;
			case GAIM_CONV_UPDATE_TITLE:
				[accountLookup(conv->account) updateTitle:(gaim_conversation_get_title(conv) ?
														   [NSString stringWithUTF8String:gaim_conversation_get_title(conv)] :
														   nil)
												  forChat:existingChatLookupFromConv(conv)];
				
				GaimDebug (@"Update to title: %s",gaim_conversation_get_title(conv));
				break;
			case GAIM_CONV_UPDATE_CHATLEFT:
				GaimDebug (@"Chat left! %s",gaim_conversation_get_name(conv));
				break;
			case GAIM_CONV_UPDATE_ADD:
			case GAIM_CONV_UPDATE_REMOVE:
			case GAIM_CONV_UPDATE_ACCOUNT:
			case GAIM_CONV_UPDATE_TYPING:
			case GAIM_CONV_UPDATE_UNSEEN:
			case GAIM_CONV_UPDATE_LOGGING:
			case GAIM_CONV_ACCOUNT_ONLINE:
			case GAIM_CONV_ACCOUNT_OFFLINE:
			case GAIM_CONV_UPDATE_AWAY:
			case GAIM_CONV_UPDATE_ICON:
			case GAIM_CONV_UPDATE_FEATURES:

/*				
				[accountLookup(conv->account) mainPerformSelector:@selector(convUpdateForChat:type:)
													   withObject:existingChatLookupFromConv(conv)
													   withObject:[NSNumber numberWithInt:type]];
*/				
			default:
				break;
		}

	} else if (gaim_conversation_get_type(conv) == GAIM_CONV_TYPE_IM) {
		GaimConvIm  *im = gaim_conversation_get_im_data(conv);
		switch (type) {
			case GAIM_CONV_UPDATE_TYPING: {

				AITypingState typingState;

				switch (gaim_conv_im_get_typing_state(im)) {
					case GAIM_TYPING:
						typingState = AITyping;
						break;
					case GAIM_TYPED:
						typingState = AIEnteredText;
						break;
					case GAIM_NOT_TYPING:
					default:
						typingState = AINotTyping;
						break;
				}

				NSNumber	*typingStateNumber = [NSNumber numberWithInt:typingState];

				[accountLookup(conv->account) typingUpdateForIMChat:imChatLookupFromConv(conv)
															 typing:typingStateNumber];
				break;
			}
			case GAIM_CONV_UPDATE_AWAY: {
				//If the conversation update is UPDATE_AWAY, it seems to suppress the typing state being updated
				//Reset gaim's typing tracking, then update to receive a GAIM_CONV_UPDATE_TYPING message
				gaim_conv_im_set_typing_state(im, GAIM_NOT_TYPING);
				gaim_conv_im_update_typing(im);
				break;
			}
			default:
				break;
		}
	}
}

#pragma mark Custom smileys
gboolean adiumGaimConvCustomSmileyAdd(GaimConversation *conv, const char *smile, gboolean remote)
{
	GaimDebug (@"%s: Added Custom Smiley %s",gaim_conversation_get_name(conv),smile);
	[accountLookup(conv->account) chat:chatLookupFromConv(conv)
			 isWaitingOnCustomEmoticon:[NSString stringWithUTF8String:smile]];

	return TRUE;
}

void adiumGaimConvCustomSmileyWrite(GaimConversation *conv, const char *smile,
									const guchar *data, gsize size)
{
	GaimDebug (@"%s: Write Custom Smiley %s (%x %i)",gaim_conversation_get_name(conv),smile,data,size);

	[accountLookup(conv->account) chat:chatLookupFromConv(conv)
					 setCustomEmoticon:[NSString stringWithUTF8String:smile]
						 withImageData:[NSData dataWithBytes:data
													  length:size]];
}

void adiumGaimConvCustomSmileyClose(GaimConversation *conv, const char *smile)
{
	GaimDebug (@"%s: Close Custom Smiley %s",gaim_conversation_get_name(conv),smile);

	[accountLookup(conv->account) chat:chatLookupFromConv(conv)
				  closedCustomEmoticon:[NSString stringWithUTF8String:smile]];
}

static GaimConversationUiOps adiumGaimConversationOps = {
	adiumGaimConvCreate,
    adiumGaimConvDestroy,
    adiumGaimConvWriteChat,
    adiumGaimConvWriteIm,
    adiumGaimConvWriteConv,
    adiumGaimConvChatAddUsers,
    adiumGaimConvChatRenameUser,
    adiumGaimConvChatRemoveUsers,
	adiumGaimConvUpdateUser,
	
	adiumGaimConvPresent,
	adiumGaimConvHasFocus,

	/* Custom Smileys */
	adiumGaimConvCustomSmileyAdd,
	adiumGaimConvCustomSmileyWrite,
	adiumGaimConvCustomSmileyClose,
};

GaimConversationUiOps *adium_gaim_conversation_get_ui_ops(void)
{
	return &adiumGaimConversationOps;
}

void adiumGaimConversation_init(void)
{	
	gaim_conversations_set_ui_ops(adium_gaim_conversation_get_ui_ops());

	gaim_signal_connect_priority(gaim_conversations_get_handle(), "conversation-updated", adium_gaim_get_handle(),
								 GAIM_CALLBACK(adiumGaimConvUpdated), NULL,
								 GAIM_SIGNAL_PRIORITY_LOWEST);
	
}
