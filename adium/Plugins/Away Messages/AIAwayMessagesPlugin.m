//
//  AIAwayMessagesPlugin.m
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AIUtilities/AIUtilities.h>
#import "AIAwayMessagesPlugin.h"
#import "AIAwayMessagePreferences.h"
#import "AIEnterAwayWindowController.h"

#define	ENTER_AWAY_MESSAGE_MENU_TITLE		@"Enter Away Message…"			//Menu item title

@implementation AIAwayMessagesPlugin

- (void)installPlugin
{
    NSMenuItem	*menuItem;

    //Our preference view
    preferences = [[AIAwayMessagePreferences awayMessagePreferencesWithOwner:owner] retain];

    //Install our 'enter away' menu item
    menuItem = [[NSMenuItem alloc] initWithTitle:ENTER_AWAY_MESSAGE_MENU_TITLE target:self action:@selector(enterAwayMessage:) keyEquivalent:@"y"];
    [[owner menuController] addMenuItem:menuItem toLocation:LOC_File_Status];

}

- (IBAction)enterAwayMessage:(id)sender
{
    [[AIEnterAwayWindowController enterAwayWindowControllerForOwner:owner] showWindow:nil];
}

@end
