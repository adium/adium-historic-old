//
//  AIChatConsolidationPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Jul 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIChatConsolidationPlugin.h"

#define CONSOLIDATE_CHATS_MENU_TITLE			NSLocalizedString(@"Consolidate Chats",nil)

@implementation AIChatConsolidationPlugin

- (void)installPlugin
{
	consolidateMenuItem = [[NSMenuItem alloc] initWithTitle:CONSOLIDATE_CHATS_MENU_TITLE
													 target:self 
													 action:@selector(consolidateChats:)
											  keyEquivalent:@"O"];
	[[adium menuController] addMenuItem:consolidateMenuItem toLocation:LOC_Window_Commands];
}

- (void)consolidateChats:(id)sender
{
	//The interface controller does all the work for us :)
	[[adium interfaceController] consolidateChats];	
}

//Only enable the menu if more than one chat is open
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	return([[[adium interfaceController] openChats] count] > 1);
}

@end
