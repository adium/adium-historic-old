//
//  AIChatController.h
//  Adium
//
//  Created by Evan Schoenberg on 6/10/05.
//

#import "AIObject.h"
#import "AIChatControllerProtocol.h"

@class AIChat, AdiumChatEvents;

@interface AIChatController : AIObject <AIChatController> {
    NSMutableSet			*openChats;
	NSMutableArray			*chatObserverArray;
	
    AIChat					*mostRecentChat;	
	
	NSMenuItem				*menuItem_ignore;
	
	AdiumChatEvents			*adiumChatEvents;
}

@end
