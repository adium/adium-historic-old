//
//  AIChatConsolidationPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Jul 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIChatConsolidationPlugin.h"

#define CONSOLIDATE_CHATS_MENU_TITLE			AILocalizedString(@"Consolidate Chats",nil)

@implementation AIChatConsolidationPlugin

- (void)installPlugin
{
	consolidateMenuItem = [[NSMenuItem alloc] initWithTitle:CONSOLIDATE_CHATS_MENU_TITLE
													 target:self 
													 action:@selector(consolidateChats:)
											  keyEquivalent:@""];
	[[adium menuController] addMenuItem:consolidateMenuItem toLocation:LOC_Window_Commands];
}

- (void)consolidateChats:(id)sender
{
	//The interface controller does all the work for us :)
	[[adium interfaceController] consolidateChats];	
}

@end
