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

#import "AIAwayMessagesPlugin.h"
#import "AIAwayMessagePreferences.h"
#import "AIEnterAwayWindowController.h"

#define AWAY_SPELLING_DEFAULT_PREFS		@"AwaySpellingDefaults"

#define AWAY_MESSAGE_MENU_TITLE			AILocalizedString(@"Set Away Message",nil)
#define AWAY_MESSAGE_MENU_TITLE_SHORT           AILocalizedString(@"Set Away",nil)
#define	REMOVE_AWAY_MESSAGE_MENU_TITLE		AILocalizedString(@"Remove Away Message",nil)
#define	CUSTOM_AWAY_MESSAGE_MENU_TITLE		AILocalizedString(@"Custom Message…",nil)
#define AWAY_MENU_HOTKEY			@"y"

@interface AIAwayMessagesPlugin (PRIVATE)
- (void)accountPropertiesChanged:(NSNotification *)notification;
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
- (void)installAwayMenu;
- (BOOL)shouldConfigureForAway;
- (void)_updateMenusToReflectAwayState:(BOOL)shouldConfigureForAway;
- (void)_updateAwaySubmenus;
- (NSMenu *)_awaySubmenuFromArray:(NSArray *)awayArray forMainMenu:(BOOL)mainMenu;
- (void)_appendAwaysFromArray:(NSArray *)awayArray toMenu:(NSMenu *)awayMenu;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIAwayMessagesPlugin

- (void)installPlugin
{
    menuConfiguredForAway = NO;
    
    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:AWAY_SPELLING_DEFAULT_PREFS 
																		forClass:[self class]]
					  forGroup:PREF_GROUP_SPELLING];
    
    //Our preference view
    preferences = [[AIAwayMessagePreferences awayMessagePreferences] retain];
    
    //Install our 'enter away message' submenu
    [self installAwayMenu];
    
    //Observe account status changes
    [[adium notificationCenter] addObserver:self
				   selector:@selector(preferencesChanged:)
				       name:Preference_GroupChanged
				     object:nil];

    [self preferencesChanged:nil];
}

//
- (void)dealloc
{
    [menuItem_away release]; menuItem_away = nil;
    
    [menuItem_removeAway release]; menuItem_removeAway = nil;
    
    if ([NSApp isOnPantherOrBetter]) {
        [menuItem_away_alternate release]; menuItem_away_alternate = nil;
        
        [menuItem_removeAway_alternate release]; menuItem_removeAway_alternate = nil;
    }
    
    [super dealloc];
}

//Display the enter away message window
- (IBAction)enterAwayMessage:(id)sender
{
    [[AIEnterAwayWindowController enterAwayWindowController] showWindow:nil];
	[NSApp activateIgnoringOtherApps:YES]; //Bring ourself forward - needed when called by the dock menu
}

//Called by the away menu, sets the selected away (sender)
- (IBAction)setAwayMessage:(id)sender
{
    NSDictionary	*awayDict = [sender representedObject];
    NSAttributedString	*awayMessage = [awayDict objectForKey:@"Message"];
    NSAttributedString	*awayAutoResponse = [awayDict objectForKey:@"Autoresponse"];
    [[adium preferenceController] setPreference:awayMessage forKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS];
    [[adium preferenceController] setPreference:awayAutoResponse forKey:@"Autoresponse" group:GROUP_ACCOUNT_STATUS];
}

//Remove the active away message
- (IBAction)removeAwayMessage:(id)sender
{
    //Remove the away status flag	
    [[adium preferenceController] setPreference:nil forKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS];
    [[adium preferenceController] setPreference:nil forKey:@"Autoresponse" group:GROUP_ACCOUNT_STATUS];
}

//Called when Adium receives content
- (void)didReceiveContent:(NSNotification *)notification
{
    AIContentObject 	*contentObject = [[notification userInfo] objectForKey:@"Object"];
    
    //If the user received a message, send our away message to source
    if([[contentObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
        
        NSAttributedString  *awayMessage = [NSAttributedString stringWithData:[[adium preferenceController] preferenceForKey:@"Autoresponse" group:GROUP_ACCOUNT_STATUS]];
        
        if(!awayMessage){
            awayMessage = [NSAttributedString stringWithData:[[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS]];
        }
        
        if(awayMessage && [awayMessage length] != 0){
            AIChat	*chat = [contentObject chat];
            //Create and send an idle bounce message (If the sender hasn't received one already)
            if([receivedAwayMessage indexOfObjectIdenticalTo:chat] == NSNotFound){
				[receivedAwayMessage addObject:chat];
				
                AIContentMessage	*responseContent;
                
                responseContent = [AIContentMessage messageInChat:chat
                                                       withSource:[contentObject destination]
                                                      destination:[contentObject source]
                                                             date:nil
                                                          message:awayMessage
                                                        autoreply:YES];
                [[adium contentController] sendContentObject:responseContent];
            }
        }
    }
}

//Called when Adium sends content
- (void)didSendContent:(NSNotification *)notification
{
    AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"Object"];
    
    if([[contentObject type] compare:CONTENT_MESSAGE_TYPE] == 0){
        AIChat	*chat = [contentObject chat];
        
        if([receivedAwayMessage indexOfObjectIdenticalTo:chat] == NSNotFound){
            [receivedAwayMessage addObject:chat];
        }
    }
}

- (void)chatWillClose:(NSNotification *)notification
{
    AIChat *chat = [notification object];
    int chatIndex = [receivedAwayMessage indexOfObjectIdenticalTo:chat];
    
    if (chatIndex != NSNotFound)
	[receivedAwayMessage removeObjectAtIndex:chatIndex];
}

//Away Menu ----------------------------------------------------------------------------------
//Install the away message window
- (void)installAwayMenu
{
    /*
     JAGUAR: It would be easier (and safer) to use a single menu item, and dynamically set it to behave as both menu
     items ("Set Away ->" and "Remove Away"), dynamically adding and removing the submenu and hotkey.  However,
     NSMenuItem appears to dislike it when a menu that has previously contained a submenu is assigned a hotkey. 
     setKeyEquivalent is ignored for any menu that has previuosly contained a submenu, resulting in a hotkey that will
     stick and persist even when the submenu is present, and that cannot be removed.  To work around this we must use
     two seperate menu items, and sneak them into Adium's menu.  Using the menu controller with two seperate dynamic
     items would result in them jumping position in the menu if other items were present in the same category, and is
     not a good solution.
     */
    
    //Set up the menubar away selector
    menuItem_away = [[NSMenuItem alloc] initWithTitle:AWAY_MESSAGE_MENU_TITLE
					       target:self
					       action:@selector(enterAwayMessage:)
					keyEquivalent:@""];
    
    menuItem_removeAway = [[NSMenuItem alloc] initWithTitle:REMOVE_AWAY_MESSAGE_MENU_TITLE
						     target:self
						     action:@selector(removeAwayMessage:)
					      keyEquivalent:AWAY_MENU_HOTKEY];
    
    //Set up 
    if ([NSApp isOnPantherOrBetter]) {
        menuItem_away_alternate = [[NSMenuItem alloc] initWithTitle:AWAY_MESSAGE_MENU_TITLE
							     target:self
							     action:@selector(enterAwayMessage:)
						      keyEquivalent:@""];
        [menuItem_away_alternate setAlternate:YES];
        [menuItem_away_alternate setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
        
        menuItem_removeAway_alternate = [[NSMenuItem alloc] initWithTitle:AWAY_MESSAGE_MENU_TITLE_SHORT
								   target:self
								   action:@selector(enterAwayMessage:)
							    keyEquivalent:AWAY_MENU_HOTKEY];
        [menuItem_removeAway_alternate setAlternate:YES];
        [menuItem_removeAway_alternate setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
       }
    
    //Setup the dock menu away selector
    menuItem_dockAway = [[NSMenuItem alloc] initWithTitle:AWAY_MESSAGE_MENU_TITLE
						   target:self
						   action:@selector(enterAwayMessage:)
					    keyEquivalent:@""];
    menuItem_dockRemoveAway = [[NSMenuItem alloc] initWithTitle:REMOVE_AWAY_MESSAGE_MENU_TITLE
							 target:self
							 action:@selector(removeAwayMessage:)
						  keyEquivalent:@""];
    
    //Add it to the menubar
	menuConfiguredForAway = [self shouldConfigureForAway];
    if(menuConfiguredForAway){
        [[adium menuController] addMenuItem:menuItem_removeAway toLocation:LOC_File_Status];
         if ([NSApp isOnPantherOrBetter]) {
             [[adium menuController] addMenuItem:menuItem_removeAway_alternate toLocation:LOC_File_Status];
         }
        [[adium menuController] addMenuItem:menuItem_dockRemoveAway toLocation:LOC_Dock_Status];
    }else{
        [[adium menuController] addMenuItem:menuItem_away toLocation:LOC_File_Status];
        if ([NSApp isOnPantherOrBetter]) {
            [[adium menuController] addMenuItem:menuItem_away_alternate toLocation:LOC_File_Status];
        }
        [[adium menuController] addMenuItem:menuItem_dockAway toLocation:LOC_Dock_Status];
    }
    
    //Update the menu content
    [self _updateAwaySubmenus];
}

//Called as our menu item is displayed, update it to reflect option key status
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    if (![NSApp isOnPantherOrBetter]) {
        //JAGUAR: It would be much better to update the menu in response to option being pressed, but I do not know
	//of an easy way to do this :(
        [self _updateMenusToReflectAwayState:[self shouldConfigureForAway]]; //Update the away message menu
    }
    return(YES);
}

//Is the user currently away?
- (BOOL)shouldConfigureForAway
{
    return(([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] != nil) && ![NSEvent optionKey]);
}

//Update our menu if the away list changes
- (void)preferencesChanged:(NSNotification *)notification
{
    NSString    *group = [[notification userInfo] objectForKey:@"Group"];
    NSString    *key = [[notification userInfo] objectForKey:@"Key"];
    
    if(notification == nil || [group compare:PREF_GROUP_AWAY_MESSAGES] == 0){
		//Rebuild the away menu
		if([key compare:KEY_SAVED_AWAYS] == 0){
			[self _updateAwaySubmenus];
		}
		
    }else if(notification == nil || ([group compare:GROUP_ACCOUNT_STATUS] == 0 && [notification object] == nil)){
		if(!key || [key compare:@"AwayMessage"] == 0){
			//Update our away menus
			[self _updateMenusToReflectAwayState:[self shouldConfigureForAway]];
			[self _updateAwaySubmenus];
			
			//Remove existing content sent/received observer, and install new (if away)
			[[adium notificationCenter] removeObserver:self name:Content_DidReceiveContent object:nil];
			[[adium notificationCenter] removeObserver:self name:Content_FirstContentRecieved object:nil];
			[[adium notificationCenter] removeObserver:self name:Content_DidSendContent object:nil];
			[[adium notificationCenter] removeObserver:self name:Chat_WillClose object:nil];
			if([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] != nil){
				[[adium notificationCenter] addObserver:self
							       selector:@selector(didReceiveContent:) 
								   name:Content_DidReceiveContent object:nil];
				[[adium notificationCenter] addObserver:self
							       selector:@selector(didReceiveContent:)
								   name:Content_FirstContentRecieved object:nil];
				[[adium notificationCenter] addObserver:self
							       selector:@selector(didSendContent:)
								   name:Content_DidSendContent object:nil];
				[[adium notificationCenter] addObserver:self
							       selector:@selector(chatWillClose:)
								   name:Chat_WillClose object:nil];
			}
			
			//Flush our array of 'responded' contacts
			[receivedAwayMessage release]; receivedAwayMessage = [[NSMutableArray alloc] init];
		}
    }
}

//--- Private
//Updates the away selection menus to reflect the requested away state
- (void)_updateMenusToReflectAwayState:(BOOL)shouldConfigureForAway
{
    if(shouldConfigureForAway != menuConfiguredForAway){
        //Swap the menu items
        if(shouldConfigureForAway){
            [NSMenu swapMenuItem:menuItem_away with:menuItem_removeAway];
            if ([NSApp isOnPantherOrBetter]) {
                [NSMenu swapMenuItem:menuItem_away_alternate with:menuItem_removeAway_alternate];
            }
            [NSMenu swapMenuItem:menuItem_dockAway with:menuItem_dockRemoveAway];
        }else{
            [NSMenu swapMenuItem:menuItem_removeAway with:menuItem_away];
            if ([NSApp isOnPantherOrBetter]) {
                [NSMenu swapMenuItem:menuItem_removeAway_alternate with:menuItem_away_alternate];
            }
            [NSMenu swapMenuItem:menuItem_dockRemoveAway with:menuItem_dockAway];
        }
        
        menuConfiguredForAway = shouldConfigureForAway;
    }
}

//Refresh the away messages displayed in the away submenus
- (void)_updateAwaySubmenus
{
    NSArray	*awayArray;
    
    //Load the saved aways
    awayArray = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_AWAY_MESSAGES] objectForKey:KEY_SAVED_AWAYS];
    
    //Update the menus
    NSMenu *mainMenuSubmenu = [self _awaySubmenuFromArray:awayArray forMainMenu:YES];
    [menuItem_away setSubmenu:mainMenuSubmenu];
    [menuItem_away_alternate setSubmenu:[mainMenuSubmenu copy]];
    [menuItem_removeAway_alternate setSubmenu:[mainMenuSubmenu copy]];
    
    
  //  [menuItem_removeAway_alternate setKeyEquivalent:@""];
  //  [menuItem_removeAway_alternate setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    
    
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
    menuItem = [[[NSMenuItem alloc] initWithTitle:CUSTOM_AWAY_MESSAGE_MENU_TITLE
					   target:self
					   action:@selector(enterAwayMessage:)
				    keyEquivalent:(mainMenu ? AWAY_MENU_HOTKEY : @"")] autorelease];
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
            NSString		*away = [awayDict objectForKey:@"Title"];
            if (!away) //no title was found
                away = [[NSAttributedString stringWithData:[awayDict objectForKey:@"Message"]] string];
            NSMenuItem		*menuItem;
            
            //Cap the away menu title (so they're not incredibly long)
            if([away length] > MENU_AWAY_DISPLAY_LENGTH){
                away = [[away substringToIndex:MENU_AWAY_DISPLAY_LENGTH] stringByAppendingString:@"…"];
            }
            
            menuItem = [[[NSMenuItem alloc] initWithTitle:away
						   target:self
						   action:@selector(setAwayMessage:)
					    keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:awayDict];
            [awayMenu addItem:menuItem];
        }
    }
}

@end





