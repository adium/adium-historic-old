//
//  AINewMessagePanelPlugin.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 13 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AINewMessagePanelPlugin.h"
#import "AINewMessagePromptController.h"

@implementation AINewMessagePanelPlugin

- (void)installPlugin
{
	newMessageMenuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"New Chat...",nil)
													target:self 
													action:@selector(newMessage:)
											 keyEquivalent:@"n"];
	[[adium menuController] addMenuItem:newMessageMenuItem toLocation:LOC_File_New];
	
}	

//Initiate a chat
- (IBAction)newMessage:(id)sender
{
	[AINewMessagePromptController showPrompt];
}

@end
