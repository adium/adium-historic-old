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
#import <Adium/Adium.h>

#import "NEHTicTacToeBoard.h"

typedef enum {  State_None,
				State_InviteSent, 
				State_InviteReceived,
				State_Negotiation,
				State_Playing,
				State_GameOver,
				} GameState;

@interface NEHTicTacToeController : AIWindowController
{
	IBOutlet NSWindow		* boardWindow;
    IBOutlet NSMatrix		* squares;
	IBOutlet NSTextField	* status;
	IBOutlet NSButton		* newGame;
	IBOutlet NSButton		* endGame;
	
	IBOutlet NSPanel		* sheet_newGame;
	IBOutlet AICompletingTextField	* textField_handle;
	IBOutlet NSPopUpButton  * popUp_account;
	IBOutlet NSMatrix		* radio_playAs;
	
	IBOutlet NSPanel		* sheet_acceptInvite;
	IBOutlet NSTextField	* textField_remoteContact;
	IBOutlet NSImageView	* imageView_acceptPlayAs;
	IBOutlet NSTextField	* textField_acceptMove;
	
	IBOutlet NSPanel		* sheet_inviteSent;
	IBOutlet NSImageView	* imageView_sentPlayAs;
	IBOutlet NSTextField	* textField_sentMove;
	
	NSImage					* image_X;
	NSImage					* image_O;
	IBOutlet NEHTicTacToeBoard	* board;
	
	Player					player;
	AIListContact			* contact_OtherPlayer;
	AIAccount				* account_Player;
	
	GameState				state;
	NSTimer					* timeout;
}

+ (id)install;
+ (id)showBoard;

- (id)initWithWindowNibName:(NSString*)nib;
- (NSImage*) loadImage: (NSString*)name;

- (IBAction)move:(id)sender;
- (IBAction)newGame:(id)sender;
- (IBAction)endGame:(id)sender;

- (IBAction)sendInvite:(id)sender;
- (IBAction)cancelInvite:(id)sender;

- (IBAction)acceptInvite:(id)sender;
- (IBAction)rejectInvite:(id)sender;

- (IBAction)retractInvite:(id)sender;

- (IBAction)selectAccount: (id)sender;

- (void)inviteTimedOut: (NSTimer*) timer;

- (void)reset;
- (void)clearBoard;
- (void)beginGame;
- (void)updateStatus;
- (BOOL)move:(Player)p atRow:(int)row atColumn:(int)col;

- (void)sendMessage:(NSString*)msg ofType:(NSString*)type;
- (void)sendMessage:(NSString*)msg ofType:(NSString*)type toContact:(AIListContact*)to fromAccount:(AIAccount*)from inChat:(AIChat*)chat;

- (void)cleanup;
@end
