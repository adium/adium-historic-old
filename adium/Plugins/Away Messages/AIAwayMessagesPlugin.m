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
#define	CUSTOM_AWAY_MESSAGE_MENU_TITLE		@"Custom Message�"
#define AWAY_MENU_HOTKEY			@"y"
#define MENU_AWAY_DISPLAY_LENGTH		30

@interface AIAwayMessagesPlugin (PRIVATE)
- (void)accountStatusChanged:(NSNotification *)notification;
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
- (void)installAwayMenu;
- (void)updateAwayMenu;
- (void)rebuildSavedAways;
- (BOOL)shouldConfigureForAway;
- (void)_rebuildSavedAwayArray:(NSArray *)awayArray;
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
            [self updateAwayMenu]; //Update our away menu

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

    //Add the saved away messages
    [self rebuildSavedAways];
    
    //Add it to the menubar
    if([self shouldConfigureForAway]){
        [[owner menuController] addMenuItem:menuItem_removeAway toLocation:LOC_File_Status];
    }else{
        [[owner menuController] addMenuItem:menuItem_away toLocation:LOC_File_Status];
    }
}

//Called as our menu item is displayed, update it to reflect option key status
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    //It would be much better to update the menu in response to option being pressed, but I do not know of an easy way to do this :(
    [self updateAwayMenu]; //Update the away message menu

    return(YES);
}

//Update the away message menu
- (void)updateAwayMenu
{
    BOOL shouldConfigureForAway = [self shouldConfigureForAway];

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

- (BOOL)shouldConfigureForAway
{
    return(([[owner accountController] statusObjectForKey:@"AwayMessage" account:nil] != nil) && ![NSEvent optionKey]);
}

- (void)rebuildSavedAways
{
    NSArray		*awayArray;

    //Remove the existing away menu items
    while([menu_awaySubmenu numberOfItems] > 2){
        [menu_awaySubmenu removeItemAtIndex:2];
    }
    
    //Load the aways
    awayArray = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];

    //Build the menu items
    [self _rebuildSavedAwayArray:awayArray];
}

- (void)_rebuildSavedAwayArray:(NSArray *)awayArray
{
    NSEnumerator	*enumerator;
    NSDictionary	*awayDict;

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
                away = [[away substringToIndex:MENU_AWAY_DISPLAY_LENGTH] stringByAppendingString:@"�"];
            }

            menuItem = [[NSMenuItem alloc] initWithTitle:away target:self action:@selector(setAwayMessage:) keyEquivalent:@""];
            [menuItem setRepresentedObject:awayDict];
            [menu_awaySubmenu addItem:menuItem];
        }
    }
    
}

//Update our menu if the away list changes
- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_AWAY_MESSAGES] == 0 &&
       [(NSString *)[[notification userInfo] objectForKey:@"Key"] compare:KEY_SAVED_AWAYS] == 0){

        //Rebuild the away menu
        [self rebuildSavedAways];
    }
}

@end





