/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#define Chat_WillClose								@"Chat_WillClose"
#define Content_ContentObjectAdded					@"Content_ContentObjectAdded"
#define Content_WillSendContent						@"Content_WillSendContent"
#define Content_DidSendContent						@"Content_DidSendContent"
#define Content_WillReceiveContent					@"Content_WillReceiveContent"
#define Content_DidReceiveContent					@"Content_DidReceiveContent"
#define Content_FirstContentRecieved				@"Content_FirstContentRecieved"
#define Content_ChatStatusChanged					@"Content_ChatStatusChanged"
#define Content_ChatParticipatingListObjectsChanged @"Content_ChatParticipatingListObjectsChanged"
#define Content_ChatAccountChanged 					@"Content_ChatAccountChanged"

//Handles the display of a content type
@protocol AIContentHandler 
@end

@protocol AIContentFilter
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inString forContentObject:(AIContentObject *)inObject listObjectContext:(AIListObject *)inListObject;
@end

@interface NSObject (AITextEntryFilter)
//required
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView; 
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
//optional
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView; //keypress
- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView; //delete,copy,paste,etc
@end

@interface AIContentController : NSObject {
    IBOutlet	AIAdium		*owner;
	
    NSMutableArray			*outgoingContentFilterArray;
    NSMutableArray			*incomingContentFilterArray;
    NSMutableArray			*displayingContentFilterArray;
	
    NSMutableArray			*textEntryFilterArray;
    NSMutableArray			*textEntryContentFilterArray;
    NSMutableArray			*textEntryViews;
	
    NSMutableArray			*chatArray;
    
    AIChat					*mostRecentChat;
    
    NSArray					*emoticonsArray;
}

//Chats
- (NSArray *)allChatsWithListObject:(AIListObject *)inObject;
- (AIChat *)openChatWithContact:(AIListContact *)inContact;
- (AIChat *)chatWithContact:(AIListContact *)inContact initialStatus:(NSDictionary *)initialStatus;
- (BOOL)closeChat:(AIChat *)inChat;
- (NSArray *)chatArray;
- (BOOL)switchToMostRecentUnviewedContent;
- (void)switchChat:(AIChat *)chat toAccount:(AIAccount *)newAccount;

//Sending / Receiving content
- (BOOL)availableForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inListObject onAccount:(AIAccount *)inAccount;
- (void)addIncomingContentObject:(AIContentObject *)inObject;
- (BOOL)sendContentObject:(AIContentObject *)inObject;
- (void)displayContentObject:(AIContentObject *)inObject;

//Filtering / Tracking text entry
- (void)registerTextEntryFilter:(id)inFilter;
- (NSArray *)openTextEntryViews;
- (void)stringAdded:(NSString *)inString toTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)contentsChangedInTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)didOpenTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;
- (void)willCloseTextEntryView:(NSText<AITextEntryView> *)inTextEntryView;

//Filtering content
- (void)registerOutgoingContentFilter:(id <AIContentFilter>)inFilter;
- (void)unregisterOutgoingContentFilter:(id <AIContentFilter>)inFilter;
- (void)registerIncomingContentFilter:(id <AIContentFilter>)inFilter;
- (void)unregisterIncomingContentFilter:(id <AIContentFilter>)inFilter;
- (void)registerDisplayingContentFilter:(id <AIContentFilter>)inFilter;
- (void)unregisterDisplayingContentFilter:(id <AIContentFilter>)inFilter;
- (void)filterObject:(AIContentObject *)inObject isOutgoing:(BOOL)isOutgoing;
- (NSAttributedString *)filteredAttributedString:(NSAttributedString *)inString listObjectContext:(AIListObject *)inListObject isOutgoing:(BOOL)isOutgoing;
- (NSAttributedString *)fullyFilteredAttributedString:(NSAttributedString *)inString listObjectContext:(AIListObject *)inListObject;

//Content Source & Destination
- (NSArray *)sourceAccountsForSendingContentType:(NSString *)inType
									toListObject:(AIListObject *)inObject
									   preferred:(BOOL)inPreferred;
- (NSArray *)destinationObjectsForContentType:(NSString *)inType
								 toListObject:(AIListObject *)inObject
									preferred:(BOOL)inPreferred;

//Emoticons
- (void)setEmoticonsArray:(NSArray *)inEmoticonsArray;
- (NSArray *)emoticonsArray;

//Private
- (void)initController;
- (void)closeController;

@end
