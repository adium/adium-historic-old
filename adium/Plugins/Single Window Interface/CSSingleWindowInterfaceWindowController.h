//
//  CSSingleWindowInterfaceWindowController.h
//  Adium XCode
//
//  Created by Chris Serino on Wed Dec 31 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@class CSSingleWindowInterfacePlugin, AIMessageViewController, CSCurrentChatsListViewController;

@interface CSSingleWindowInterfaceWindowController : AIWindowController {
	IBOutlet	AIAutoScrollView		*scrollView_contactList;
	IBOutlet	AIAutoScrollView		*scrollView_currentChatsList;
	IBOutlet	NSBox					*box_messageView;
	IBOutlet	NSView					*view_noActiveChat;
	
	id <AIContactListViewController>	contactListViewController;
    NSView								*contactListView;
	CSSingleWindowInterfacePlugin		*interface;
	CSCurrentChatsListViewController	*currentChatsController;
}

+ (CSSingleWindowInterfaceWindowController*) singleWindowInterfaceWindowControllerWithInterface:(CSSingleWindowInterfacePlugin*)inInterface;
- (void)addChat:(AIChat *)inChat;
- (void)setChat:(AIChat *)inChat;
- (void)closeChat:(AIChat *)inChat;
- (void)collapseContactList:(id)sender;

@end
