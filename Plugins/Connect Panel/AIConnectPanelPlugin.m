//
//  AIConnectPanelPlugin.m
//  Adium
//
//  Created by Adam Iser on Fri Mar 12 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIConnectPanelPlugin.h"
#import "AIConnectPanelWindowController.h"

#define NEW_CONNETION_MENU_TITLE	AILocalizedString(@"New Connection...","Title for the new connection menu item")


@implementation AIConnectPanelPlugin

- (void)installPlugin
{
	//New connection menu item
    menuItem_newConnection = [[NSMenuItem alloc] initWithTitle:NEW_CONNETION_MENU_TITLE
														target:self 
														action:@selector(newConnection:) 
												 keyEquivalent:@""];
    [[adium menuController] addMenuItem:menuItem_newConnection toLocation:LOC_File_New];
	
}

//Open new connection panel
- (IBAction)newConnection:(id)sender
{
	[[AIConnectPanelWindowController connectPanelWindowController] showWindow:nil];
	
}




@end
