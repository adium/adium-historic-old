/*
TicTacToe plugin for Adium
Copyright (C) 2003 Nelson Elhage

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

#import "NEHTicTacToeBoard.h"
#import <AdiumGames/NEHGameController.h>
				
@class AIWindowController, AIListContact, AIAccount, AICompletingTextField;

@interface NEHTicTacToeController : NEHGameController
{
    IBOutlet NSMatrix           *squares;
	IBOutlet NSTextField        *status;
	
	IBOutlet NSTextField        *textField_remoteContact;
	IBOutlet NSImageView        *imageView_acceptPlayAs;
	IBOutlet NSTextField        *textField_acceptMove;
	
	IBOutlet NSImageView        *imageView_sentPlayAs;
	IBOutlet NSTextField        *textField_sentMove;
	
	NSImage                     *image_X;
	NSImage                     *image_O;
	IBOutlet NEHTicTacToeBoard  *board;
	
	Player					player;
}

- (id)initWithPlugin:(NEHGamePlugin *)inPlugin;

- (void)handleMessage:(NSString *)msg ofType:(NSString *)type;

- (void)beginNewGame;

- (void)didSendInvitation:(int)playAs;
- (void)didReceiveInvitation:(int)playAs;

- (NSString *)nibName;

- (NSString *)firstPlayerName;
- (NSString *)secondPlayerName;

- (void)reset;
- (NSImage *)loadImage:(NSString *)name;
- (void)updateStatus;
- (BOOL)move:(Player)p atRow:(unsigned)row atColumn:(unsigned)col;
- (void)clearBoard;
@end
