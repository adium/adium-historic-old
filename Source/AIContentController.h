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

#define Content_ContentObjectAdded					@"Content_ContentObjectAdded"
#define Content_ChatDidFinishAddingUntrackedContent	@"Content_ChatDidFinishAddingUntrackedContent"
#define Content_WillSendContent						@"Content_WillSendContent"
#define Content_WillReceiveContent					@"Content_WillReceiveContent"

//Not displayed, but used for internal identification of the encryption menu
#define ENCRYPTION_MENU_TITLE						@"Encryption Menu"

@protocol AITextEntryView, AIEventHandler;

@class AIAccount, AIChat, AIListContact, AIListObject, AIContentObject, NDRunLoopMessenger;

typedef enum {
	AIFilterContent = 0,		// Changes actual message and non-message content
	AIFilterDisplay,			// Changes only how non-message content is displayed locally (Profiles, aways, auto-replies, ...)
	AIFilterMessageDisplay,  	// Changes only how messages are displayed locally
	
	//A special content mode for AIM auto-replies that will only apply to bounced away messages.  This allows us to
	//filter %n,%t,... just like the official client.  A small tumor in our otherwise beautiful filter system *cry*/
	AIFilterAutoReplyContent
	
} AIFilterType;
#define FILTER_TYPE_COUNT 4

typedef enum {
	AIFilterIncoming = 0,   // Content we are receiving
	AIFilterOutgoing		// Content we are sending
} AIFilterDirection;
#define FILTER_DIRECTION_COUNT 2

//Observer which receives notifications of changes in chat status
@protocol AIChatObserver
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
@end

//Handles the display of a content type
@protocol AIContentHandler 
@end

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

@interface NSObject (AITextEntryFilter)
//required
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView; 
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
//optional
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView; //keypress
- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView; //delete,copy,paste,etc
@end

@interface AIContentController : NSObject <AIEventHandler> {
    IBOutlet	AIAdium		*adium;
	
    NSMutableArray			*textEntryFilterArray;
    NSMutableArray			*textEntryContentFilterArray;
    NSMutableArray			*textEntryViews;
	NSDictionary			*defaultFormattingAttributes;
	
    NSMutableArray			*chatArray;
	NSMutableArray			*chatObserverArray;

    AIChat					*mostRecentChat;
    
    NSArray					*emoticonsArray;
    NSArray					*emoticonPacks;
	
	NSMutableArray			*contentFilter[FILTER_TYPE_COUNT][FILTER_DIRECTION_COUNT];
	NSMutableArray			*threadedContentFilter[FILTER_TYPE_COUNT][FILTER_DIRECTION_COUNT];
}

//Chats
- (NSSet *)allChatsWithContact:(AIListContact *)inContact;
- (AIChat *)openChatWithContact:(AIListContact *)inContact;
- (AIChat *)chatWithContact:(AIListContact *)inContact;
- (AIChat *)existingChatWithContact:(AIListContact *)inContact;
- (AIChat *)existingChatWithUniqueChatID:(NSString *)uniqueChatID;
- (AIChat *)chatWithName:(NSString *)inName onAccount:(AIAccount *)account chatCreationInfo:(NSDictionary *)chatCreationInfo;
- (AIChat *)existingChatWithName:(NSString *)inName onAccount:(AIAccount *)account;
- (void)openChat:(AIChat *)chat;
- (BOOL)closeChat:(AIChat *)inChat;
- (NSArray *)chatArray;
- (BOOL)switchToMostRecentUnviewedContent;
- (void)switchChat:(AIChat *)chat toAccount:(AIAccount *)newAccount;
- (void)switchChat:(AIChat *)chat toListContact:(AIListContact *)inContact usingContactAccount:(BOOL)useContactAccount;

//Status
- (void)registerChatObserver:(id <AIChatObserver>)inObserver;
- (void)unregisterChatObserver:(id <AIChatObserver>)inObserver;
- (void)chatStatusChanged:(AIChat *)inChat modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
- (void)updateAllChatsForObserver:(id <AIChatObserver>)observer;


//Unviewed Content Status
- (void)increaseUnviewedContentOfChat:(AIChat *)inChat;
- (void)clearUnviewedContentOfChat:(AIChat *)inChat;

//Sending / Receiving content
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact onAccount:(AIAccount *)inAccount;
- (void)receiveContentObject:(AIContentObject *)inObject;
- (BOOL)sendContentObject:(AIContentObject *)inObject;
- (void)displayStatusMessage:(NSString *)message ofType:(NSString *)type inChat:(AIChat *)inChat;
- (void)displayContentObject:(AIContentObject *)inObject;
- (void)displayContentObject:(AIContentObject *)inObject immediately:(BOOL)immediately;
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters;
- (void)displayContentObject:(AIContentObject *)inObject usingContentFilters:(BOOL)useContentFilters immediately:(BOOL)immediately;
- (void)displayStatusMessage:(NSString *)message ofType:(NSString *)type inChat:(AIChat *)inChat;

//Filtering / Tracking text entry
- (void)registerTextEntryFilter:(id)inFilter;
- (NSArray *)openTextEntryViews;
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)setDefaultFormattingAttributes:(NSDictionary *)inDict;
- (NSDictionary *)defaultFormattingAttributes;

//Filtering content
- (void)registerContentFilter:(id <AIContentFilter>)inFilter
					   ofType:(AIFilterType)type
					direction:(AIFilterDirection)direction;
- (void)registerContentFilter:(id <AIContentFilter>)inFilter
					   ofType:(AIFilterType)type
					direction:(AIFilterDirection)direction
					 threaded:(BOOL)threaded;
- (void)unregisterContentFilter:(id <AIContentFilter>)inFilter;
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
- (NDRunLoopMessenger *)filterRunLoopMessenger;

//Content Source & Destination
- (NSArray *)sourceAccountsForSendingContentType:(NSString *)inType
									toListObject:(AIListObject *)inObject
									   preferred:(BOOL)inPreferred;
- (NSArray *)destinationObjectsForContentType:(NSString *)inType
								 toListObject:(AIListObject *)inObject
									preferred:(BOOL)inPreferred;

//Encryption
- (NSMenu *)encryptionMenuNotifyingTarget:(id)target withDefault:(BOOL)withDefault;

//Private
- (void)initController;
- (void)closeController;

@end
