//
//  DCJoinChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface DCJoinChatViewController : AIObject {
	IBOutlet		NSView			*view;			// Custom view
	AIChat							*chat;			// The newly created chat
}

+ (DCJoinChatViewController *)joinChatView;

- (id)init;
- (NSView *)view;
- (NSString *)nibName;

- (void)configureForAccount:(AIAccount *)inAccount;
- (void)joinChatWithAccount:(AIAccount *)inAccount;

@end
