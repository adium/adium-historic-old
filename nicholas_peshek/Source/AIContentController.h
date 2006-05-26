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

#import <Adium/AIObject.h>

#define Content_ContentObjectAdded					@"Content_ContentObjectAdded"
#define Content_ChatDidFinishAddingUntrackedContent	@"Content_ChatDidFinishAddingUntrackedContent"
#define Content_WillSendContent						@"Content_WillSendContent"
#define Content_WillReceiveContent					@"Content_WillReceiveContent"

//XXX - This is really UI, but it can live here for now
#define PREF_GROUP_FORMATTING				@"Formatting"
#define KEY_FORMATTING_FONT					@"Default Font"
#define KEY_FORMATTING_TEXT_COLOR			@"Default Text Color"
#define KEY_FORMATTING_BACKGROUND_COLOR		@"Default Background Color"

//Not displayed, but used for internal identification of the encryption menu
#define ENCRYPTION_MENU_TITLE						@"Encryption Menu"

@protocol AIController, AITextEntryView, AIEventHandler;

@class AdiumMessageEvents, AdiumTyping, AdiumFormatting, AdiumContentFiltering, AdiumOTREncryption;
@class AIAccount, AIChat, AIListContact, AIListObject, AIContentObject, NDRunLoopMessenger;

typedef enum {
	AIFilterContent = 0,		// Changes actual message and non-message content
	AIFilterDisplay,			// Changes only how non-message content is displayed locally (Profiles, aways, auto-replies, ...)
	AIFilterMessageDisplay,  	// Changes only how messages are displayed locally
	AIFilterTooltips,			// Changes only information displayed in contact tooltips

	//A special content mode for AIM auto-replies that will only apply to bounced away messages.  This allows us to
	//filter %n,%t,... just like the official client.  A small tumor in our otherwise beautiful filter system *cry*/
	AIFilterAutoReplyContent
	
} AIFilterType;
#define FILTER_TYPE_COUNT 5

typedef enum {
	AIFilterIncoming = 0,   // Content we are receiving
	AIFilterOutgoing		// Content we are sending
} AIFilterDirection;
#define FILTER_DIRECTION_COUNT 2

#define HIGHEST_FILTER_PRIORITY 0
#define HIGH_FILTER_PRIORITY 0.25
#define DEFAULT_FILTER_PRIORITY 0.5
#define LOW_FILTER_PRIORITY 0.75
#define LOWEST_FILTER_PRIORITY 1.0

//AIContentFilters have the opportunity to examine every attributed string.  Non-attributed strings are not passed through these filters.
@protocol AIContentFilter
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context;
- (float)filterPriority;
@end

//Delayed content filters return YES if they begin a delayed filter, NO if they don't.
@protocol AIDelayedContentFilter
- (BOOL)delayedFilterAttributedString:(NSAttributedString *)inAttributedString context:(id)context uniqueID:(unsigned long long)uniqueID;
- (float)filterPriority;
@end

@interface AIContentController : AIObject <AIController> {
	AdiumTyping				*adiumTyping;
	AdiumFormatting			*adiumFormatting;
	AdiumContentFiltering	*adiumContentFiltering;
	AdiumMessageEvents		*adiumMessageEvents;
	AdiumOTREncryption		*adiumOTREncryption;

	NSMutableDictionary		*defaultFormattingAttributes;
	NSMutableSet			*objectsBeingReceived;
}

//Typing
- (void)userIsTypingContentForChat:(AIChat *)chat hasEnteredText:(BOOL)hasEnteredText;

//Formatting
- (NSDictionary *)defaultFormattingAttributes;

//Content Filtering
- (void)registerContentFilter:(id <AIContentFilter>)inFilter
					   ofType:(AIFilterType)type
					direction:(AIFilterDirection)direction;
- (void)registerDelayedContentFilter:(id <AIDelayedContentFilter>)inFilter
							  ofType:(AIFilterType)type
						   direction:(AIFilterDirection)direction;;
- (void)unregisterContentFilter:(id <AIContentFilter>)inFilter;
- (void)registerFilterStringWhichRequiresPolling:(NSString *)inPollString;
- (BOOL)shouldPollToUpdateString:(NSString *)inString;

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)attributedString
							   usingFilterType:(AIFilterType)type
									 direction:(AIFilterDirection)direction
									   context:(id)context;
- (void)filterAttributedString:(NSAttributedString *)attributedString
			   usingFilterType:(AIFilterType)type
					 direction:(AIFilterDirection)direction
				 filterContext:(id)filterContext
			   notifyingTarget:(id)target
					  selector:(SEL)selector
					   context:(id)context;
- (void)delayedFilterDidFinish:(NSAttributedString *)attributedString uniqueID:(unsigned long long)uniqueID;

//Sending / Receiving content
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact onAccount:(AIAccount *)inAccount;
- (void)receiveContentObject:(AIContentObject *)inObject;
- (BOOL)sendContentObject:(AIContentObject *)inObject;
- (void)sendRawMessage:(NSString *)inString toContact:(AIListContact *)inContact;
- (void)displayStatusMessage:(NSString *)message ofType:(NSString *)type inChat:(AIChat *)inChat;
- (void)displayContentObject:(AIContentObject *)inObject;
- (void)displayContentObject:(AIContentObject *)inObject immediately:(BOOL)immediately;
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters;
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters immediately:(BOOL)immediately;
- (void)displayStatusMessage:(NSString *)message ofType:(NSString *)type inChat:(AIChat *)inChat;

//Encryption
- (NSAttributedString *)decodedIncomingMessage:(NSString *)inString
								   fromContact:(AIListContact *)inListContact 
									 onAccount:(AIAccount *)inAccount;
- (NSString *)decryptedIncomingMessage:(NSString *)inString
						   fromContact:(AIListContact *)inListContact
							 onAccount:(AIAccount *)inAccount;

- (NSMenu *)encryptionMenuNotifyingTarget:(id)target withDefault:(BOOL)withDefault;

- (BOOL)chatIsReceivingContent:(AIChat *)chat;

//OTR
- (void)requestSecureOTRMessaging:(BOOL)inSecureMessaging inChat:(AIChat *)inChat;
- (void)promptToVerifyEncryptionIdentityInChat:(AIChat *)inChat;

@end
