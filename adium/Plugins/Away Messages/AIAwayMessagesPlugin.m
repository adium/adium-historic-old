//
//  AIAwayMessagesPlugin.m
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import "AIAwayMessagesPlugin.h"
#import "AIAwayMessagePreferences.h"
#import "AIEnterAwayWindowController.h"

#define AWAY_MESSAGE_MENU_TITLE			@"Set Away Message"
#define	REMOVE_AWAY_MESSAGE_MENU_TITLE		@"Remove Away Message"
#define	CUSTOM_AWAY_MESSAGE_MENU_TITLE		@"Custom Message…"
#define AWAY_MENU_HOTKEY			@"y"

@interface AIAwayMessagesPlugin (PRIVATE)
- (void)accountStatusChanged:(NSNotification *)notification;
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
- (void)installAwayMenu;
- (void)updateAwayMenu;
@end

@implementation AIAwayMessagesPlugin

- (void)installPlugin
{
    menuConfiguredForAway = NO;
    
    //Our preference view
    preferences = [[AIAwayMessagePreferences awayMessagePreferencesWithOwner:owner] retain];

    //Install our 'enter away message' submenu
    [self installAwayMenu];
    [self updateAwayMenu];
    
    //Observe
    [[[owner accountController] accountNotificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_StatusChanged object:nil];
}

- (IBAction)enterAwayMessage:(id)sender
{
    [[AIEnterAwayWindowController enterAwayWindowControllerForOwner:owner] showWindow:nil];
}

- (IBAction)removeAwayMessage:(id)sender
{
    //Remove the away status flag
    [[owner accountController] setStatusObject:nil forKey:@"AwayMessage" account:nil];
}

//Private ------------------------------------------------------------------------------
//Update our menu when the away status changes
- (void)accountStatusChanged:(NSNotification *)notification
{
    if([notification object] == nil){ //We ignore account-specific status changes
        NSString	*modifiedKey = [[notification userInfo] objectForKey:@"Key"];

        if([modifiedKey compare:@"AwayMessage"] == 0){
            [self updateAwayMenu]; //Update our away menu
        }
    }
}

//Called as our menu item is displayed, update it to reflect option key status
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    //It would be much better to update the menu in response to option being pressed, but I do not know of an easy way to do this :(

    //    if(menuItem == menuItem_away || menuItem == menuItem_removeAway){
        [self updateAwayMenu]; //Update the away message menu
//    }

    return(YES);
}

//Install the away message window
- (void)installAwayMenu
{
    /*
     It would be easier (and safer) to use a single menu item, and dynamically set it to behave as both menu items ("Set Away ->" and "Remove Away"), dynamically adding and removing the submenu and hotkey.  However, NSMenuItem appears to dislike it when a menu that has previously contained a submenu is assigned a hotkey.  setKeyEquivalent is ignored for any menu that has previuosly contained a submenu, resulting in a hotkey that will stick and persist even when the submenu is present, and that cannot be removed.  To work around this we must use two seperate menu items, and sneak them into Adium's menu.  Using the menu controller with two seperate dynamic items would result in them jumping position in the menu if other items were present in the same category, and is not a good solution.
     */

    //Main away items
    menuItem_away = [[NSMenuItem alloc] initWithTitle:AWAY_MESSAGE_MENU_TITLE
                                               target:self
                                               action:@selector(enterAwayMessage:)
                                        keyEquivalent:@""];
    
    menuItem_removeAway = [[NSMenuItem alloc] initWithTitle:REMOVE_AWAY_MESSAGE_MENU_TITLE
                                                     target:self
                                                     action:@selector(removeAwayMessage:)
                                              keyEquivalent:AWAY_MENU_HOTKEY];

    //Build the 'Go away' Submenu --
    menuItem_customMessage = [[NSMenuItem alloc] initWithTitle:CUSTOM_AWAY_MESSAGE_MENU_TITLE target:self action:@selector(enterAwayMessage:) keyEquivalent:AWAY_MENU_HOTKEY];
    menu_awaySubmenu = [[NSMenu alloc] initWithTitle:@""]; //Title is arbitrary
    [menu_awaySubmenu addItem:menuItem_customMessage];
    [menu_awaySubmenu addItem:[NSMenuItem separatorItem]];

    [menuItem_away setSubmenu:menu_awaySubmenu];
    
    //Add it to the menubar
    [[owner menuController] addMenuItem:menuItem_away toLocation:LOC_File_Status];
}

//Update the away message menu
- (void)updateAwayMenu
{
    BOOL shouldConfigureForAway = ([[owner accountController] statusObjectForKey:@"AwayMessage" account:nil] != nil) && ![NSEvent optionKey];

    if(shouldConfigureForAway != menuConfiguredForAway){
        //Swap the menu items
        if(shouldConfigureForAway){
            NSMenu	*containingMenu = [menuItem_away menu];
            int		menuItemIndex = [containingMenu indexOfItem:menuItem_away];

            [containingMenu removeItem:menuItem_away];
            [containingMenu insertItem:menuItem_removeAway atIndex:menuItemIndex];
            
        }else{
            NSMenu	*containingMenu = [menuItem_removeAway menu];
            int		menuItemIndex = [containingMenu indexOfItem:menuItem_removeAway];

            [containingMenu removeItem:menuItem_removeAway];
            [containingMenu insertItem:menuItem_away atIndex:menuItemIndex];
            
        }

        menuConfiguredForAway = shouldConfigureForAway;
    }
}

@end
