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

#define AWAY_MESSAGE_MENU_TITLE			@"Set Away Message"
#define	REMOVE_AWAY_MESSAGE_MENU_TITLE		@"Remove Away Message"
#define	CUSTOM_AWAY_MESSAGE_MENU_TITLE		@"Custom MessageÉ"

@interface AIAwayMessagesPlugin (PRIVATE)
- (void)installMenu;
@end

@implementation AIAwayMessagesPlugin

- (void)installPlugin
{
    //Our preference view
    preferences = [[AIAwayMessagePreferences awayMessagePreferencesWithOwner:owner] retain];

    //Install our 'enter away message' submenu
    [self installMenu];
}

- (void)installMenu
{
    //Set Away Message ->
    menu_awaySubmenu = [[NSMenu alloc] initWithTitle:@"Aways"]; //Title is arbitrary
    menuItem_away = [[NSMenuItem alloc] initWithTitle:AWAY_MESSAGE_MENU_TITLE action:nil keyEquivalent:@""];
    [menuItem_away setSubmenu:menu_awaySubmenu];
    
    //Custom Message...
    menuItem_customMessage = [[NSMenuItem alloc] initWithTitle:CUSTOM_AWAY_MESSAGE_MENU_TITLE target:self action:@selector(enterAwayMessage:) keyEquivalent:@"y"];
    [menu_awaySubmenu addItem:menuItem_customMessage];

    //Divider
    [menu_awaySubmenu addItem:[NSMenuItem separatorItem]];
    
    //Custom aways:



    //Add it to the menubar
    [[owner menuController] addMenuItem:menuItem_away toLocation:LOC_File_Status];
}

- (IBAction)enterAwayMessage:(id)sender
{
    [[AIEnterAwayWindowController enterAwayWindowControllerForOwner:owner] showWindow:nil];
}

-

@end
