//
//  AINewMessagePanelPlugin.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 13 2004.
//

#import "AINewMessagePanelPlugin.h"
#import "AINewMessagePrompt.h"

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
	[AINewMessagePrompt newMessagePrompt];
}

@end
