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

#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "NEHTicTacToePlugin.h"

#define MENU_TICTACTOE_BOARD AILocalizedString(@"Tic Tac Toe Board","Menu item to show board.")
#define MENU_TICTACTOE_INVITE AILocalizedString(@"Invite to play Tic Tac Toe","Contextual menu item to invite someone to a game.")
#define MENU_TICTACTOE_RESET AILocalizedString(@"Reset Tic Tac Toe Plugin","Menu item to reset plugin.")


@implementation NEHTicTacToePlugin

- (void)installPlugin
{
	NEHTicTacToeController *control = [NEHTicTacToeController install];
	
	menuItem_TTTBoard = [[[NSMenuItem alloc] initWithTitle:MENU_TICTACTOE_BOARD target:self action:@selector(showBoard:) keyEquivalent:@"T"] autorelease];
	[[adium menuController] addMenuItem:menuItem_TTTBoard toLocation:LOC_Window_Auxilary];
	
	menuItem_invite = [[[NSMenuItem alloc] initWithTitle:MENU_TICTACTOE_INVITE target:control action:@selector(newGame:) keyEquivalent:@""] autorelease];
	[[adium menuController] addContextualMenuItem:menuItem_invite toLocation:Context_Contact_Manage];
	
	menuItem_resetTTT = [[[NSMenuItem alloc] initWithTitle:MENU_TICTACTOE_RESET target:self action:@selector(resetTTT:) keyEquivalent:@""] autorelease];
	[[adium menuController] addMenuItem:menuItem_resetTTT toLocation:LOC_File_Additions];
}

- (void)uninstallPlugin
{
}

- (void)showBoard: (id)sender
{
	[NEHTicTacToeController showBoard];
}

- (void)resetTTT: (id)sender
{
	[[NEHTicTacToeController install] reset];
}

@end
