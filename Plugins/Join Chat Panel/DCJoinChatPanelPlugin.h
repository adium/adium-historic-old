//
//  AINewMessagePanelPlugin.h
//  Adium
//
//  Created by Adam Iser on Tue Jul 13 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface DCJoinChatPanelPlugin : AIPlugin {
	NSMenuItem	*joinChatMenuItem;
}

- (IBAction)joinChat:(id)sender;

@end
