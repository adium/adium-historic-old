/*
TicTacToe plugin for Adium
Copyright (C) 2003 Nelson El-Hage

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#import <Cocoa/Cocoa.h>

#import "NEHTicTacToePlugin.h"
#import "NEHTicTacToeBoard.h"
#import "NEHTicTacToeController.h"

#define MENU_TICTACTOE_INVITE		AILocalizedString(@"Invite to play Tic Tac Toe","Contextual menu item to invite someone to a game.")
#define MENU_TICTACTOE_NEW			AILocalizedString(@"New Tic Tac Toe Game","File Menu Item.")

#define CONTACT_NOT_FOUND			AILocalizedString(@"Contact Not Found","")
#define CONTACT_NOT_FOUND_MESSAGE   AILocalizedString(@"Unable to find contact '%@'","")

#define NEW_GAME_NIB				@"NewTicTacToeGame"

#pragma mark

@implementation NEHTicTacToePlugin

static NEHTicTacToePlugin * plugin;

- (void)installPlugin
{
	plugin = self;

	menuItem_invite = [[[NSMenuItem alloc] initWithTitle:MENU_TICTACTOE_INVITE target:self action:@selector(newGame:) keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem_invite toLocation:Context_Contact_Manage];
	menuItem_newGame = [[[NSMenuItem alloc] initWithTitle:MENU_TICTACTOE_NEW target:self action:@selector(newGame:) keyEquivalent:@""] autorelease];
	[[adium menuController] addMenuItem:menuItem_newGame toLocation:LOC_File_New];
	
	[NSBundle loadNibNamed:NEW_GAME_NIB owner:self];
	
	[window_newGame setWindowController:windowController];
	
	gamesForAccounts = [[NSMutableDictionary alloc] init];
	[[adium contentController] registerIncomingContentFilter:self];
}

- (void)uninstallPlugin
{
	[gamesForAccounts release];
	[[adium contentController] unregisterIncomingContentFilter:self];
}

+ (NEHTicTacToePlugin*)plugin
{
	return plugin;
}

- (void)endGameFor:(NEHTicTacToeController*)control
{
	NSEnumerator * enumerator = [gamesForAccounts keyEnumerator], *en2;
	id key,key2;
	NSMutableDictionary * dict;
	
	while((key = [enumerator nextObject]))
	{
		dict = [gamesForAccounts objectForKey:key];
		en2 = [dict keyEnumerator];
		while((key2 = [en2 nextObject]))
		{
			if([dict objectForKey:key2] == control)
				[dict removeObjectForKey:key2];
		}
	}
}

- (void)newGame: (id)sender
{
	AIListContact   *selectedContact = [[adium contactController] selectedContact];
	if(selectedContact)
		[textField_handle setStringValue:[selectedContact UID]];
	
	[windowController showWindow:nil];
	
	NSEnumerator		*enumerator;
    AIListContact		*contact;
    AIAccount			*account;
    
    //Configure the auto-complete view
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];
    while((contact = [enumerator nextObject])){
        [textField_handle addCompletionString:[contact UID]];
    }

    //Configure the handle type menu
    [popUp_account removeAllItems];
    [[popUp_account menu] setAutoenablesItems:NO];

    //Insert a menu item for each available account
    enumerator = [[[adium accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        NSMenuItem	*menuItem;
        
        //Create the menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:[account displayName] target:self action:@selector(selectAccount:) keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];

        //Disabled the menu item if the account is offline
        if(![[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil onAccount:account]){
            [menuItem setEnabled:NO];
        }else{
            [menuItem setEnabled:YES];
        }

        //add the menu item
        [[popUp_account menu] addItem:menuItem];
    }

    //Select the last used account / Available online account
    [popUp_account selectItemAtIndex:[popUp_account indexOfItemWithRepresentedObject:[[adium accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil]]];
}


#pragma mark Invite Window Actions

- (IBAction) cancelInvite:(id)sender
{
	[windowController close];
}

- (IBAction) sendInvite: (id)sender
{
	[windowController close]; 
	
    NSString		*UID;
    AIServiceType	*serviceType;
	AIAccount		*account;
	AIListContact   *contact;

    //Get the service type and UID
    account = [[popUp_account selectedItem] representedObject];
    serviceType = [[account service] handleServiceType];
    UID = [serviceType filterUID:[textField_handle stringValue]];
        
    //Find the contact
	contact = [[adium contactController] contactWithService:[serviceType identifier] UID:UID];
	NSMutableDictionary * contacts = [gamesForAccounts objectForKey:[account UIDAndServiceID]];
	if(contacts == nil)
	{
		contacts = [[[NSMutableDictionary alloc] init] autorelease];
		[gamesForAccounts setObject:contacts forKey:[account UIDAndServiceID]];
	}
	if(contact && [contacts objectForKey:[contact UIDAndServiceID]])
	{
		NSBeep();
		return;
		//TODO: Put an error message here, perhaps
	}
	
    if(contact){
		int playAs = [radio_playAs selectedRow];
		if(playAs == 2) playAs = rand()%2;
		Player player = playAs?PLAYER_O:PLAYER_X;
		NEHTicTacToeController * control = [[[NEHTicTacToeController alloc] init] autorelease];
		[control sendInvitation:player account:account contact:contact];
        [contacts setObject:control	forKey:[contact UIDAndServiceID]];
    }
	else
	{
		NSRunAlertPanel(CONTACT_NOT_FOUND,[NSString stringWithFormat:CONTACT_NOT_FOUND_MESSAGE,[textField_handle stringValue]],BUTTON_ERR,nil,nil);
	}
}

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString forContentObject:(AIContentObject *)inobj
{
	NSString * str = [inAttributedString string];
	NSRange start = [str rangeOfString:@"[TTT/"];
	NSRange end = [str rangeOfString:@"]:"];
	if(start.location != 0 || end.location == NSNotFound)
		return inAttributedString;
	NSRange r;
	r.location = start.length;
	r.length = end.location - r.location;
	NSString * type = [str substringWithRange:r];
	NSString * msg;
	if([str length] > end.location+end.length)
		msg = [str substringFromIndex:(end.location+end.length)];
	else
		msg = @"";
		
	[inobj setDisplayContent:NO];
	[inobj setTrackContent:NO];
	
	AIListContact   * contact = [inobj source];
	AIAccount		* account = [inobj destination];
	
	NSMutableDictionary * contacts = [gamesForAccounts objectForKey:[account UIDAndServiceID]];
	if(contacts == nil)
	{
		contacts = [[[NSMutableDictionary alloc] init] autorelease];
		[gamesForAccounts setObject:contacts forKey:[account UIDAndServiceID]];
	}
	NEHTicTacToeController * control = [contacts objectForKey:[contact UIDAndServiceID]];
		
	if([type isEqualToString:MSG_TYPE_INVITE])
	{
		if(control != nil)
		{
			//If this happens, it means something has gone weird. Ignore it for now - if there really is a plugin calling us, they'll time out
			return inAttributedString;
		}
		control = [[[NEHTicTacToeController alloc] init] autorelease];
		[control handleInvitation:msg account:account contact:contact];
		[contacts setObject:control forKey:[contact UIDAndServiceID]];
	}
	else if(control != nil)		//We ignore messages from people with whom we don't have an open game
	{
		[control handleMessage:msg ofType:type];
	}
	return inAttributedString;	
}

- (IBAction)selectAccount: (id)sender
{
}

@end
