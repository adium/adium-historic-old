//
//  DCJoinChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface DCJoinChatViewController : AIObject {
	IBOutlet		NSView			*view;			//Custom view
}

+ (DCJoinChatViewController *)joinChatView;

- (id)init;
- (void)configureForAccount:(AIAccount *)inAccount;
- (NSView *)view;
- (NSString *)nibName;

@end
