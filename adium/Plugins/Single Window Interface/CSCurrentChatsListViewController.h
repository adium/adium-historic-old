//
//  CSCurrentChatsListViewController.h
//  Adium XCode
//
//  Created by Chris Serino on Thu Jan 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@class AIMessageViewController;

@interface CSCurrentChatsListViewController : AIObject {
	AIAlternatingRowTableView			*view;
	NSMutableArray						*messageViewControllerArray;
	AIChat								*activeChat;
}

- (BOOL)messageViewControllerHasBeenCreatedForChat:(AIChat*)inChat;
- (AIMessageViewController*)messageViewControllerForChat:(AIChat*)inChat;

- (void)openChat:(AIChat*)inChat;
- (void)setChat:(AIChat*)inChat;
- (void)closeChat:(AIChat*)inChat;

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView;

- (int)count;

- (AIAlternatingRowTableView*)view;

@end
