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

#pragma mark Gaim Images
#define MESSAGE_IMAGE_CACHE_NAME		@"TEMP-Image_%@_%i"

static NSString* _messageImageCachePath(int imageID, CBGaimAccount* adiumAccount)
{
    NSString    *messageImageCacheFilename = [NSString stringWithFormat:MESSAGE_IMAGE_CACHE_NAME, [adiumAccount internalObjectID], imageID];
    return [[[[AIObject sharedAdiumInstance] cachesPath] stringByAppendingPathComponent:messageImageCacheFilename] stringByAppendingPathExtension:@"png"];
}

static NSString* _processGaimImages(NSString* inString, CBGaimAccount* adiumAccount)
{
	NSScanner			*scanner;
    NSString			*chunkString = nil;
    NSMutableString		*newString;
	NSString			*targetString = @"<IMG ID=\"";
    int imageID;

    //set up
	newString = [[NSMutableString alloc] init];

    scanner = [NSScanner scannerWithString:inString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

	//A gaim image tag takes the form <IMG ID="12"></IMG> where 12 is the reference for use in GaimStoredImage* gaim_imgstore_get(int)

	//Parse the incoming HTML
    while (![scanner isAtEnd]) {

		//Find the beginning of a gaim IMG ID tag
		if ([scanner scanUpToString:targetString intoString:&chunkString]) {
			[newString appendString:chunkString];
		}

		if ([scanner scanString:targetString intoString:&chunkString]) {

			//Get the image ID from the tag
			[scanner scanInt:&imageID];

			//Scan up to ">
			[scanner scanString:@"\">" intoString:nil];

			//Get the image, then write it out as a png
			GaimStoredImage		*gaimImage = gaim_imgstore_get(imageID);
			if (gaimImage) {
				NSString			*imagePath = _messageImageCachePath(imageID, adiumAccount);

				//First make an NSImage, then request a TIFFRepresentation to avoid an obscure bug in the PNG writing routines
				//Exception: PNG writer requires compacted components (bits/component * components/pixel = bits/pixel)
				NSImage				*image = [[NSImage alloc] initWithData:[NSData dataWithBytes:gaim_imgstore_get_data(gaimImage)
																						  length:gaim_imgstore_get_size(gaimImage)]];
				NSData				*imageTIFFData = [image TIFFRepresentation];
				NSBitmapImageRep	*bitmapRep = [NSBitmapImageRep imageRepWithData:imageTIFFData];

				//If writing the PNG file is successful, write an <IMG SRC="filepath"> tag to our string
				if ([[bitmapRep representationUsingType:NSPNGFileType properties:nil] writeToFile:imagePath atomically:YES]) {
					[newString appendString:[NSString stringWithFormat:@"<IMG SRC=\"%@\">",imagePath]];
				}

				[image release];
			} else {
				//If we didn't get a gaimImage, just leave the tag for now.. maybe it was important?
				[newString appendString:chunkString];
			}
		}
	}

	return ([newString autorelease]);
}

#pragma mark Conversations
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

static void adiumGaimConvWriteChat(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	//We only care about this if it does not have the GAIM_MESSAGE_SEND flag, which is set if Gaim is sending a sent message back to us
	if ((flags & GAIM_MESSAGE_SEND) == 0) {
		NSDictionary	*messageDict;
		NSString		*messageString;

		messageString = [NSString stringWithUTF8String:message];
		AILog(@"Source: %s \t Name: %s \t MyNick: %s : Message %@", 
			  who,
			  gaim_conversation_get_name(conv),
			  gaim_conv_chat_get_nick(GAIM_CONV_CHAT(conv)),
			  messageString);
		if (!who || strcmp(who,gaim_conv_chat_get_nick(GAIM_CONV_CHAT(conv)))) {
			NSAttributedString	*attributedMessage = [AIHTMLDecoder decodeHTML:messageString];
			NSNumber			*gaimMessageFlags = [NSNumber numberWithInt:flags];
			NSDate				*date = [NSDate dateWithTimeIntervalSince1970:mtime];
			
			if (who && strlen(who)) {
				messageDict = [NSDictionary dictionaryWithObjectsAndKeys:attributedMessage, @"AttributedMessage",
					[NSString stringWithUTF8String:who], @"Source",
					gaimMessageFlags, @"GaimMessageFlags",
					[NSString stringWithUTF8String:who], @"Source",
					[NSNumber numberWithInt:flags], @"GaimMessageFlags",
					date, @"Date",nil];
				
			} else {
				messageDict = [NSDictionary dictionaryWithObjectsAndKeys:attributedMessage, @"AttributedMessage",
					gaimMessageFlags, @"GaimMessageFlags",
					date, @"Date",nil];
			}
			
			[accountLookup(conv->account) mainPerformSelector:@selector(receivedMultiChatMessage:inChat:)
												   withObject:messageDict
												   withObject:chatLookupFromConv(conv)];
		}
	}
}

static void adiumGaimConvWriteIm(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	//We only care about this if it does not have the GAIM_MESSAGE_SEND flag, which is set if Gaim is sending a sent message back to us
	if ((flags & GAIM_MESSAGE_SEND) == 0) {
		NSDictionary		*messageDict;
		CBGaimAccount		*adiumAccount = accountLookup(conv->account);
		NSString			*messageString;
		AIChat				*chat;

		messageString = [NSString stringWithUTF8String:message];
		chat = imChatLookupFromConv(conv);

		GaimDebug (@"adiumGaimConvWriteIm: Received %@ from %@",messageString,[[chat listObject] UID]);

		//Process any gaim imgstore references into real HTML tags pointing to real images
		if ([messageString rangeOfString:@"<IMG ID=\"" options:NSCaseInsensitiveSearch].location != NSNotFound) {
			messageString = _processGaimImages(messageString, adiumAccount);
		}

		messageDict = [NSDictionary dictionaryWithObjectsAndKeys:[AIHTMLDecoder decodeHTML:messageString],@"AttributedMessage",
			[NSNumber numberWithInt:flags],@"GaimMessageFlags",
			[NSDate dateWithTimeIntervalSince1970:mtime],@"Date",nil];

		[adiumAccount mainPerformSelector:@selector(receivedIMChatMessage:inChat:)
							   withObject:messageDict
							   withObject:chat];
	}
}

static void adiumGaimConvWriteConv(GaimConversation *conv, const char *who, const char *message, GaimMessageFlags flags, time_t mtime)
{
	AIChat	*chat = nil;
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT) {
		chat = existingChatLookupFromConv(conv);
	} else if (gaim_conversation_get_type(conv) == GAIM_CONV_IM) {
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
				}

				if (updateType != -1) {
					[accountLookup(conv->account) mainPerformSelector:@selector(updateForChat:type:)
														   withObject:chat
														   withObject:[NSNumber numberWithInt:updateType]];
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
					if ([messageString rangeOfString:@"because a time out occurred"].location != NSNotFound) {
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
					[accountLookup(conv->account) mainPerformSelector:@selector(errorForChat:type:)
														   withObject:chat
														   withObject:[NSNumber numberWithInt:errorType]];
				}

				GaimDebug (@"*** Conversation error type %i (%@): %@",
						   errorType,
						   ([chat listObject] ? [[chat listObject] UID] : [chat name]),messageString);
			}
		}
	}
}

static void adiumGaimConvChatAddUser(GaimConversation *conv, const char *user, gboolean new_arrival)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT) {
		GaimDebug (@"adiumGaimConvChatAddUser: CHAT: add %s",user);
		//We pass the name as given, not normalized, so we can use its formatting as a formattedUID.
		//The account is responsible for normalization if needed.
		[accountLookup(conv->account) mainPerformSelector:@selector(addUser:toChat:)
											   withObject:[NSString stringWithUTF8String:user]
											   withObject:existingChatLookupFromConv(conv)];
	} else {
		GaimDebug (@"adiumGaimConvChatAddUser: IM: add %s",user);
	}

}

static void adiumGaimConvChatAddUsers(GaimConversation *conv, GList *users)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT) {
		NSMutableArray	*usersArray = [NSMutableArray array];

		GList *l;
		for (l = users; l != NULL; l = l->next) {
			[usersArray addObject:[NSString stringWithUTF8String:(char *)l->data]];
		}

		[accountLookup(conv->account) mainPerformSelector:@selector(addUsersArray:toChat:)
											   withObject:usersArray
											   withObject:existingChatLookupFromConv(conv)];

	} else {
		GaimDebug (@"adiumGaimConvChatAddUsers: IM");
	}
}

static void adiumGaimConvChatRenameUser(GaimConversation *conv, const char *oldName, const char *newName)
{
	GaimDebug (@"adiumGaimConvChatRenameUser");
}

static void adiumGaimConvChatRemoveUser(GaimConversation *conv, const char *user)
{
 	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT) {
		[accountLookup(conv->account) mainPerformSelector:@selector(removeUser:fromChat:)
											   withObject:[NSString stringWithUTF8String:gaim_normalize(conv->account, user)]
											   withObject:existingChatLookupFromConv(conv)];
	} else {
		GaimDebug (@"adiumGaimConvChatRemoveUser: IM: remove %s",user);
	}

}

static void adiumGaimConvChatRemoveUsers(GaimConversation *conv, GList *users)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT) {
		NSMutableArray	*usersArray = [NSMutableArray array];

		GList *l;
		for (l = users; l != NULL; l = l->next) {
			[usersArray addObject:[NSString stringWithUTF8String:gaim_normalize(conv->account, (char *)l->data)]];
		}

		[accountLookup(conv->account) mainPerformSelector:@selector(removeUsersArray:fromChat:)
											   withObject:usersArray
											   withObject:existingChatLookupFromConv(conv)];

	} else {
		GaimDebug (@"adiumGaimConvChatRemoveUser: IM");
	}
}

static void adiumGaimConvUpdateUser(GaimConversation *conv, const char *user)
{
	GaimDebug (@"adiumGaimConvUpdateUser: %s",user);
}

static void adiumGaimConvUpdateProgress(GaimConversation *conv, float percent)
{
    GaimDebug (@"adiumGaimConvUpdateProgress %f",percent);
}

//This isn't a function we want Gaim doing anything with, I don't think
static gboolean adiumGaimConvHasFocus(GaimConversation *conv)
{
	return NO;
}

static void adiumGaimConvUpdated(GaimConversation *conv, GaimConvUpdateType type)
{
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT) {
		GaimConvChat  *chat = gaim_conversation_get_chat_data(conv);
		
		switch(type) {
			case GAIM_CONV_UPDATE_TOPIC:
				[accountLookup(conv->account) mainPerformSelector:@selector(updateTopic:forChat:)
													   withObject:(gaim_conv_chat_get_topic(chat) ?
																   [NSString stringWithUTF8String:gaim_conv_chat_get_topic(chat)] :
																   nil)
													   withObject:existingChatLookupFromConv(conv)];
				break;
			case GAIM_CONV_UPDATE_TITLE:
				[accountLookup(conv->account) mainPerformSelector:@selector(updateTitle:forChat:)
													   withObject:(gaim_conversation_get_title(conv) ?
																   [NSString stringWithUTF8String:gaim_conversation_get_title(conv)] :
																   nil)
													   withObject:existingChatLookupFromConv(conv)];
				
				GaimDebug (@"Update to title: %s",gaim_conversation_get_title(conv));
				break;
			case GAIM_CONV_UPDATE_CHATLEFT:
				GaimDebug (@"Chat left! %s",gaim_conversation_get_name(conv));
				break;
				
			default:
				break;
		}
		
		[accountLookup(conv->account) mainPerformSelector:@selector(convUpdateForChat:type:)
											   withObject:existingChatLookupFromConv(conv)
											   withObject:[NSNumber numberWithInt:type]];

	} else if (gaim_conversation_get_type(conv) == GAIM_CONV_IM) {
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

				[accountLookup(conv->account) mainPerformSelector:@selector(typingUpdateForIMChat:typing:)
													   withObject:imChatLookupFromConv(conv)
													   withObject:typingStateNumber];
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

static GaimConversationUiOps adiumGaimConversationOps = {
    adiumGaimConvDestroy,
    adiumGaimConvWriteChat,
    adiumGaimConvWriteIm,
    adiumGaimConvWriteConv,
    adiumGaimConvChatAddUser,
    adiumGaimConvChatAddUsers,
    adiumGaimConvChatRenameUser,
    adiumGaimConvChatRemoveUser,
    adiumGaimConvChatRemoveUsers,
	adiumGaimConvUpdateUser,
    adiumGaimConvUpdateProgress,
	adiumGaimConvHasFocus,
    adiumGaimConvUpdated
};

GaimConversationUiOps *adium_gaim_conversation_get_ui_ops(void)
{
	return &adiumGaimConversationOps;
}

#pragma mark Conversation Window
// Conversation Window ---------------------------------------------------------------------------------------------
static GaimConversationUiOps *adiumGaimConvWindowGetConvUiOps()
{
    return adium_gaim_conversation_get_ui_ops();
}

static void adiumGaimConvWindowNew(GaimConvWindow *win)
{
    //We can put anything we want in win's ui_data
}

static void adiumGaimConvWindowDestroy(GaimConvWindow *win)
{
    //Clean up what we placed in win's ui_data earlier
}

static void adiumGaimConvWindowShow(GaimConvWindow *win)
{
	GaimDebug (@"adiumGaimConvWindowShow");
}

static void adiumGaimConvWindowHide(GaimConvWindow *win)
{
    GaimDebug (@"adiumGaimConvWindowHide");
}

static void adiumGaimConvWindowRaise(GaimConvWindow *win)
{
	GaimDebug (@"adiumGaimConvWindowRaise");
}

static void adiumGaimConvWindowFlash(GaimConvWindow *win)
{
}

static void adiumGaimConvWindowSwitchConv(GaimConvWindow *win, unsigned int index)
{
    GaimDebug (@"adiumGaimConvWindowSwitchConv");
}

static void adiumGaimConvWindowAddConv(GaimConvWindow *win, GaimConversation *conv)
{
	GaimDebug (@"adiumGaimConvWindowAddConv");

	//Pass chats along to the account
	if (gaim_conversation_get_type(conv) == GAIM_CONV_CHAT) {

		AIChat *chat = chatLookupFromConv(conv);

		[accountLookup(conv->account) mainPerformSelector:@selector(addChat:)
											   withObject:chat];
	}
}

static void adiumGaimConvWindowRemoveConv(GaimConvWindow *win, GaimConversation *conv)
{
	GaimDebug (@"adiumGaimConvWindowRemoveConv");
}

static void adiumGaimConvWindowMoveConv(GaimConvWindow *win, GaimConversation *conv, unsigned int newIndex)
{
    GaimDebug (@"adiumGaimConvWindowMoveConv");
}

static int adiumGaimConvWindowGetActiveIndex(const GaimConvWindow *win)
{
    return 0;
}

static GaimConvWindowUiOps adiumGaimWindowOps = {
    adiumGaimConvWindowGetConvUiOps,
    adiumGaimConvWindowNew,
    adiumGaimConvWindowDestroy,
    adiumGaimConvWindowShow,
    adiumGaimConvWindowHide,
    adiumGaimConvWindowRaise,
    adiumGaimConvWindowFlash,
    adiumGaimConvWindowSwitchConv,
    adiumGaimConvWindowAddConv,
    adiumGaimConvWindowRemoveConv,
    adiumGaimConvWindowMoveConv,
    adiumGaimConvWindowGetActiveIndex
};

GaimConvWindowUiOps *adium_gaim_conversation_get_win_ui_ops(void)
{
	return &adiumGaimWindowOps;
}

