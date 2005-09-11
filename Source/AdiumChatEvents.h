//
//  AdiumChatEvents.h
//  Adium
//
//  Created by Evan Schoenberg on 9/10/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Adium/AIObject.h>

@class AIChat, AIListContact;
@protocol AIEventHandler;

@interface AdiumChatEvents : AIObject <AIEventHandler> {

}

- (void)controllerDidLoad;
- (void)chat:(AIChat *)chat addedListContact:(AIListContact *)inContact;
- (void)chat:(AIChat *)chat removedListContact:(AIListContact *)inContact;

@end
