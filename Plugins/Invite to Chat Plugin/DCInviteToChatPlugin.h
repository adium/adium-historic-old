//
//  DCInviteToChatPlugin.h
//  Adium
//
//  Created by David Clark on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface DCInviteToChatPlugin : AIPlugin {
	NSMenuItem		*menuItem_inviteToChat;
	NSMenuItem		*menuItem_inviteToChatContext;
		
	BOOL			shouldRebuildChatList;
}

- (IBAction)inviteToChat:(id)sender;

@end
