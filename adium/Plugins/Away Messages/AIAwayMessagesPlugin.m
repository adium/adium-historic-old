/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import "AIAwayMessagesPlugin.h"
#import "AIAwayMessagePreferences.h"
#import "AIEnterAwayWindowController.h"

#define AWAY_SPELLING_DEFAULT_PREFS		@"AwaySpellingDefaults"

#define AWAY_MESSAGE_MENU_TITLE			@"Set Away Message"
#define	REMOVE_AWAY_MESSAGE_MENU_TITLE		@"Remove Away Message"
#define	CUSTOM_AWAY_MESSAGE_MENU_TITLE		@"Custom Message…"
#define AWAY_MENU_HOTKEY			@"y"
#define MENU_AWAY_DISPLAY_LENGTH		30

@interface AIAwayMessagesPlugin (PRIVATE)
- (void)accountStatusChanged:(NSNotification *)notification;
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
- (void)installAwayMenu;
- (BOOL)shouldConfigureForAway;
- (void)_updateMenusToReflectAwayState:(BOOL)shouldConfigureForAway;
- (void)_updateAwaySubmenus;
- (NSMenu *)_awaySubmenuFromArray:(NSArray *)awayArray forMainMenu:(BOOL)mainMenu;
- (void)_appendAwaysFromArray:(NSArray *)awayArray toMenu:(NSMenu *)awayMenu;
- (void)swapMenuItem:(NSMenuItem *)existingItem with:(NSMenuItem *)newItem;
@end

@implementation AIAwayMessagesPlugin

- (void)installPlugin
{
    menuConfiguredForAway = NO;

    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:AWAY_SPELLING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_SPELLING];
    
    //Our preference view
    preferences = [[AIAwayMessagePreferences awayMessagePreferencesWithOwner:owner] retain];

    //Install our 'enter away message' submenu
    [self installAwayMenu];

    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_StatusChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    [self accountStatusChanged:nil];
}

//Display the enter away message window
- (IBAction)enterAwayMessage:(id)sender
{
    [[AIEnterAwayWindowController enterAwayWindowControllerForOwner:owner] showWindow:nil];
}

//Called by the away menu, sets the selected away (sender)
- (IBAction)setAwayMessage:(id)sender
{
    NSDictionary	*awayDict = [sender representedObject];
    NSAttributedString	*awayMessage = [awayDict objectForKey:@"Message"];

    [[owner accountController] setStatusObject:awayMessage forKey:@"AwayMessage" account:nil];
}

//Remove the active away message
- (IBAction)removeAwayMessage:(id)sender
{
    //Remove the away status flag	
    [[owner accountController] setStatusObject:nil forKey:@"AwayMessage" account:nil];
}

//Update our menu when the away status changes
- (void)accountStatusChanged:(NSNotification *)notification
{
    if(notification == nil || [notification object] == nil){ //We ignore account-specific status changes
        NSString	*modifiedKey = [[notification userInfo] objectForKey:@"Key"];

        if([modifiedKey compare:@"AwayMessage"] == 0){
            //Update our away menus
            [self _updateMenusToReflectAwayState:[self shouldConfigureForAway]];
            [self _updateAwaySubmenus];

            //Remove existing content sent/received observer, and install new (if away)
            [[owner notificationCenter] removeObserver:self name:Content_DidReceiveContent object:nil];
            [[owner notificationCenter] removeObserver:self name:Content_DidSendContent object:nil];
            if([[owner accountController] statusObjectForKey:@"AwayMessage" account:nil] != nil){
                [[owner notificationCenter] addObserver:self selector:@selector(didReceiveContent:) name:Content_DidReceiveContent object:nil];
                [[owner notificationCenter] addObserver:self selector:@selector(didSendContent:) name:Content_DidSendContent object:nil];
            }

            //Flush our array of 'responded' contacts
            [receivedAwayMessage release]; receivedAwayMessage = [[NSMutableArray alloc] init];
        }
    }
}

//Called when Adium receives content
- (void)didReceiveContent:(NSNotification *)notification
{
    id <AIContentObject>	contentObject = [[notification userInfo] objectForKey:@"Object"];
    NSAttributedString		*awayMessage = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"AwayMessage" account:nil]];
    
    //If the user received a message, send our away message to them
    if([[contentObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
        if(awayMessage && [awayMessage length] != 0){
            AIHandle	*handle = [contentObject source];

            //Create and send an away bounce message (If the sender hasn't received one already)
            if(![receivedAwayMessage containsObject:[handle UIDAndServiceID]]){
                AIContentMessage	*responseContent;
    
                responseContent = [AIContentMessage messageWithSource:[contentObject destination]
                                                          destination:handle
                                                                 date:nil
                                                              message:awayMessage];
    
                [[owner contentController] sendContentObject:responseContent];
            }
        }
    }
}

//Called when Adium sends content
- (void)didSendContent:(NSNotification *)notification
{
    id <AIContentObject>	contentObject = [[notification userInfo] objectForKey:@"Object"];

    if([[contentObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
        AIHandle	*handle = [contentObject destination];
        NSString 	*senderUID = [handle UIDAndServiceID];

        //Add the handle's UID to our 'already received away message' array, so they only receive the message once.
        if(![receivedAwayMessage containsObject:senderUID]){
            [receivedAwayMessage addObject:senderUID];
        }
    }
}



//Away Menu ----------------------------------------------------------------------------------
//Install the away message window
- (void)installAwayMenu
{
    /*
     It would be easier (and safer) to use a single menu item, and dynamically set it to behave as both menu items ("Set Away ->" and "Remove Away"), dynamically adding and removing the submenu and hotkey.  However, NSMenuItem appears to dislike it when a menu that has previously contained a submenu is assigned a hotkey.  setKeyEquivalent is ignored for any menu that has previuosly contained a submenu, resulting in a hotkey that will stick and persist even when the submenu is present, and that cannot be removed.  To work around this we must use two seperate menu items, and sneak them into Adium's menu.  Using the menu controller with two seperate dynamic items would result in them jumping position in the menu if other items were present in the same category, and is not a good solution.
     */

    //Setup the menubar away selector
    menuItem_away = [[NSMenuItem alloc] initWithTitle:AWAY_MESSAGE_MENU_TITLE target:self action:@selector(enterAwayMessage:) keyEquivalent:@""];
    menuItem_removeAway = [[NSMenuItem alloc] initWithTitle:REMOVE_AWAY_MESSAGE_MENU_TITLE target:self action:@selector(removeAwayMessage:) keyEquivalent:AWAY_MENU_HOTKEY];

    //Setup the dock menu away selector
    menuItem_dockAway = [[NSMenuItem alloc] initWithTitle:AWAY_MESSAGE_MENU_TITLE target:self action:@selector(enterAwayMessage:) keyEquivalent:@""];
    menuItem_dockRemoveAway = [[NSMenuItem alloc] initWithTitle:REMOVE_AWAY_MESSAGE_MENU_TITLE target:self action:@selector(removeAwayMessage:) keyEquivalent:@""];

    //Add it to the menubar
    if([self shouldConfigureForAway]){
        [[owner menuController] addMenuItem:menuItem_removeAway toLocation:LOC_File_Status];
        [[owner menuController] addMenuItem:menuItem_dockRemoveAway toLocation:LOC_Dock_Status];
    }else{
        [[owner menuController] addMenuItem:menuItem_away toLocation:LOC_File_Status];
        [[owner menuController] addMenuItem:menuItem_dockAway toLocation:LOC_Dock_Status];
    }

    //Update the menu content
    [self _updateAwaySubmenus];
}

//Called as our menu item is displayed, update it to reflect option key status
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    //It would be much better to update the menu in response to option being pressed, but I do not know of an easy way to do this :(
    [self _updateMenusToReflectAwayState:[self shouldConfigureForAway]]; //Update the away message menu

    return(YES);
}

//Is the user currently away?
- (BOOL)shouldConfigureForAway
{
    return(([[owner accountController] statusObjectForKey:@"AwayMessage" account:nil] != nil) && ![NSEvent optionKey]);
}

//Update our menu if the away list changes
- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_AWAY_MESSAGES] == 0 &&
       [(NSString *)[[notification userInfo] objectForKey:@"Key"] compare:KEY_SAVED_AWAYS] == 0){
        [self _updateAwaySubmenus]; //Rebuild the away menu
    }
}


//--- Private
//Updates the away selection menus to reflect the requested away state
- (void)_updateMenusToReflectAwayState:(BOOL)shouldConfigureForAway
{
    if(shouldConfigureForAway != menuConfiguredForAway){
        //Swap the menu items
        if(shouldConfigureForAway){
            [self swapMenuItem:menuItem_away with:menuItem_removeAway];
            [self swapMenuItem:menuItem_dockAway with:menuItem_dockRemoveAway];
            
        }else{
            [self swapMenuItem:menuItem_removeAway with:menuItem_away];
            [self swapMenuItem:menuItem_dockRemoveAway with:menuItem_dockAway];

        }

        menuConfiguredForAway = shouldConfigureForAway;
    }
}

//Swap two menu items
- (void)swapMenuItem:(NSMenuItem *)existingItem with:(NSMenuItem *)newItem
{
    NSMenu	*containingMenu = [existingItem menu];
    int		menuItemIndex = [containingMenu indexOfItem:existingItem];

    [containingMenu removeItem:existingItem];
    [containingMenu insertItem:newItem atIndex:menuItemIndex];
}

//Refresh the away messages displayed in the away submenus
- (void)_updateAwaySubmenus
{
    NSArray	*awayArray;

    //Load the saved aways
    awayArray = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];

    //Update the menus
    [menuItem_away setSubmenu:[self _awaySubmenuFromArray:awayArray forMainMenu:YES]];
    [menuItem_dockAway setSubmenu:[self _awaySubmenuFromArray:awayArray forMainMenu:NO]];

}

//Builds an away message submenu from the passed array of aways
- (NSMenu *)_awaySubmenuFromArray:(NSArray *)awayArray forMainMenu:(BOOL)mainMenu
{
    NSMenu		*awayMenu;
    NSMenuItem		*menuItem;
    
    //Create the menu
    awayMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];

    //Add the 'Custom away' menu item and divider
    menuItem = [[NSMenuItem alloc] initWithTitle:CUSTOM_AWAY_MESSAGE_MENU_TITLE target:self action:@selector(enterAwayMessage:) keyEquivalent:(mainMenu ? AWAY_MENU_HOTKEY : @"")];
    [awayMenu addItem:menuItem];
    [awayMenu addItem:[NSMenuItem separatorItem]];

    //Add a menu item for each away message
    [self _appendAwaysFromArray:awayArray toMenu:awayMenu];

    return(awayMenu);
}

- (void)_appendAwaysFromArray:(NSArray *)awayArray toMenu:(NSMenu *)awayMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*awayDict;

    //Add a menu item for each away message
    enumerator = [awayArray objectEnumerator];
    while((awayDict = [enumerator nextObject])){
        NSString *type = [awayDict objectForKey:@"Type"];

        if([type compare:@"Group"] == 0){
            //NSString		*group = [awayDict objectForKey:@"Name"];

            //Create & process submenu

        }else if([type compare:@"Away"] == 0){
            NSString		*away = [[NSAttributedString stringWithData:[awayDict objectForKey:@"Message"]] string];
            NSMenuItem		*menuItem;

            //Cap the away menu title (so they're not incredibly long)
            if([away length] > MENU_AWAY_DISPLAY_LENGTH){
                away = [[away substringToIndex:MENU_AWAY_DISPLAY_LENGTH] stringByAppendingString:@"…"];
            }

            menuItem = [[NSMenuItem alloc] initWithTitle:away target:self action:@selector(setAwayMessage:) keyEquivalent:@""];
            [menuItem setRepresentedObject:awayDict];
            [awayMenu addItem:menuItem];
        }
    }

}

@end





