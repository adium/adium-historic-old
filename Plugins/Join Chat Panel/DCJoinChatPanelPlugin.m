//
//  DCJoinChatPanelPlugin.m
//  Adium
//
//  Created by David Clark on Sun Jul 18 2004
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "DCJoinChatPanelPlugin.h"
#import "DCJoinChatWindowController.h"

#define JOIN_CHAT_MENU_ITEM		NSLocalizedString(@"Join Chat...",nil)

@implementation DCJoinChatPanelPlugin

- (void)installPlugin
{
	joinChatMenuItem = [[NSMenuItem alloc] initWithTitle:JOIN_CHAT_MENU_ITEM
													target:self 
													action:@selector(joinChat:)
											 keyEquivalent:@""];
	[[adium menuController] addMenuItem:joinChatMenuItem toLocation:LOC_File_New];
}	

//Initiate a chat
- (IBAction)joinChat:(id)sender
{	
	[DCJoinChatWindowController joinChatWindow];
}

@end
