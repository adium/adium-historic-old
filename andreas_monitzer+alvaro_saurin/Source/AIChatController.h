//
//  AIChatController.h
//  Adium
//
//  Created by Evan Schoenberg on 6/10/05.
//

#import <Adium/AIObject.h>

@class AIChat, AIListContact, AIAccount, AdiumChatEvents;
@protocol AIController;

//Observer which receives notifications of changes in chat status
@protocol AIChatObserver
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
@end

@interface AIChatController : AIObject <AIController> {
    NSMutableSet			*openChats;
	NSMutableArray			*chatObserverArray;
	
    AIChat					*mostRecentChat;	
	
	NSMenuItem				*menuItem_ignore;
	
	AdiumChatEvents			*adiumChatEvents;
}

//Chats
- (AIChat *)mostRecentUnviewedChat;
- (NSSet *)allChatsWithContact:(AIListContact *)inContact;
- (AIChat *)openChatWithContact:(AIListContact *)inContact;
- (AIChat *)chatWithContact:(AIListContact *)inContact;
- (AIChat *)existingChatWithContact:(AIListContact *)inContact;
- (AIChat *)existingChatWithUniqueChatID:(NSString *)uniqueChatID;
- (AIChat *)chatWithName:(NSString *)inName onAccount:(AIAccount *)account chatCreationInfo:(NSDictionary *)chatCreationInfo;
- (AIChat *)existingChatWithName:(NSString *)inName onAccount:(AIAccount *)account;
- (BOOL)closeChat:(AIChat *)inChat;
- (NSSet *)openChats;
- (AIChat *)mostRecentUnviewedChat;
- (int) unviewedContentCount;
- (void)switchChat:(AIChat *)chat toAccount:(AIAccount *)newAccount;
- (void)switchChat:(AIChat *)chat toListContact:(AIListContact *)inContact usingContactAccount:(BOOL)useContactAccount;
- (BOOL)contactIsInGroupChat:(AIListContact *)listContact;

//Status
- (void)registerChatObserver:(id <AIChatObserver>)inObserver;
- (void)unregisterChatObserver:(id <AIChatObserver>)inObserver;
- (void)updateAllChatsForObserver:(id <AIChatObserver>)observer;

//Addition/removal of contacts to group chats
- (void)chat:(AIChat *)chat addedListContact:(AIListContact *)inContact notify:(BOOL)notify;
- (void)chat:(AIChat *)chat removedListContact:(AIListContact *)inContact;

- (NSString *)defaultInvitationMessageForRoom:(NSString *)room account:(AIAccount *)inAccount;

@end

@interface AIChatController (AIChatMethods)
- (void)chatStatusChanged:(AIChat *)inChat modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
@end
