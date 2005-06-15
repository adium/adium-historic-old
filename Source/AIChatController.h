//
//  AIChatController.h
//  Adium
//
//  Created by Evan Schoenberg on 6/10/05.
//

#import <Adium/AIObject.h>

@class AIChat, AIListContact, AIAccount;
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
- (void)openChat:(AIChat *)chat;
- (BOOL)closeChat:(AIChat *)inChat;
- (NSSet *)openChats;
- (AIChat *)mostRecentUnviewedChat;
- (void)switchChat:(AIChat *)chat toAccount:(AIAccount *)newAccount;
- (void)switchChat:(AIChat *)chat toListContact:(AIListContact *)inContact usingContactAccount:(BOOL)useContactAccount;
- (BOOL)contactIsInGroupChat:(AIListContact *)listContact;

//Status
- (void)registerChatObserver:(id <AIChatObserver>)inObserver;
- (void)unregisterChatObserver:(id <AIChatObserver>)inObserver;
- (void)chatStatusChanged:(AIChat *)inChat modifiedStatusKeys:(NSSet *)inModifiedKeys silent:(BOOL)silent;
- (void)updateAllChatsForObserver:(id <AIChatObserver>)observer;

//Unviewed Content Status
- (void)increaseUnviewedContentOfChat:(AIChat *)inChat;
- (void)clearUnviewedContentOfChat:(AIChat *)inChat;

@end

