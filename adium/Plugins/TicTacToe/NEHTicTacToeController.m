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

#import <Cocoa/Cocoa.h>

#import "NEHTicTacToeController.h"
#import "NEHTicTacToePlugin.h"

#define TTT_NIB @"TicTacToeBoard"

#define PLAY_FIRST			AILocalizedString(@"(You will play first)","")
#define PLAY_SECOND			AILocalizedString(@"(You will play second)","")
#define YOU_WIN				AILocalizedString(@"You win!","")
#define YOU_LOSE			AILocalizedString(@"You lost...","")
#define TIE					AILocalizedString(@"It's a Tie!","Message when the game ends in a tie")

#define STATE_NO_GAME		AILocalizedString(@"No game.","Status message when there is no game in progress")
#define STATE_YOUR_TURN		AILocalizedString(@"Your turn.","")
#define STATE_THEIR_TURN	AILocalizedString(@"Waiting for opponent","Status message when it is the other player's turn")

@implementation NEHTicTacToeController

- (id)initWithPlugin:(NEHGamePlugin *)inPlugin
{
	[super initWithPlugin:inPlugin];
	return self;
}

- (void)awakeFromNib
{
	image_O = [self loadImage:@"O"];
	image_X = [self loadImage:@"X"];	
}

- (void)handleMessage:(NSString *)msg ofType:(NSString *)type
{
	if([type isEqualToString:MSG_TYPE_MOVE]) {
		if(state == State_Playing) {
			unsigned row, col;
			row = [msg characterAtIndex:0] - '0';
			col = [msg characterAtIndex:2] - '0';
			[self move:(player == PLAYER_X ? PLAYER_O : PLAYER_X) atRow:row atColumn:col];
		} else {
			NSLog(@"TTT:Move message received with state %d.", state);
		}
	}
	[super handleMessage:msg ofType:type];
}

- (void)beginNewGame
{
	[board newGame];
	[self clearBoard];
	[squares setEnabled:YES];
	[self updateStatus];
}

- (void)dealloc
{
	[image_X release];
	[image_O release];
	[super dealloc];
}

- (void)didSendInvitation:(int)playAs
{
	player = (playAs == FIRST_PLAYER ? PLAYER_X : PLAYER_O);
	if(playAs == FIRST_PLAYER) {
		player = PLAYER_X;
		[imageView_sentPlayAs setImage:image_X];
		[textField_sentMove setStringValue:PLAY_FIRST];
	} else {
		player = PLAYER_O;
		[imageView_sentPlayAs setImage:image_O];
		[textField_sentMove setStringValue:PLAY_SECOND];
	}
}


- (void)didReceiveInvitation:(int)playAs
{
	player = (playAs == FIRST_PLAYER ? PLAYER_X : PLAYER_O);
	[textField_remoteContact setStringValue:[contact_OtherPlayer displayName]];
	if(player == PLAYER_X) {
		[imageView_acceptPlayAs setImage:image_X];
		[textField_acceptMove setStringValue:PLAY_FIRST];
	} else {
		[imageView_acceptPlayAs setImage:image_O];
		[textField_acceptMove setStringValue:PLAY_SECOND];
	}
}

- (NSString *)nibName
{
	return TTT_NIB;
}

- (NSString *)firstPlayerName
{
	return @"X";
}

- (NSString *)secondPlayerName
{
	return @"O";
}


- (NSImage *)loadImage:(NSString *)name
{
	NSString *path;
	NSImage  *img    =  nil;
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];

	if(path = [bundle pathForImageResource:name]) {
		img = [[NSImage alloc] initWithContentsOfFile:path];
	} else {
		NSLog(@"TTT:Unable to open image %@",name);
	}

	return img;
}

- (void)cleanup
{
	[image_X release];
	[image_O release];
}

- (IBAction)move:(id)sender
{
	if(state != State_Playing) return;

	int	row = [squares selectedRow], 
		col = [squares selectedColumn];

	if(row >= 0 && col >= 0 && [self move:player atRow:row atColumn:col]) {
		[self sendMessage:[NSString stringWithFormat:@"%d,%d",row,col] ofType:MSG_TYPE_MOVE];
	} else {
		NSBeep();
	}
}

- (void)clearBoard
{
	for(int i = 0; i < 3; i++) {
		for(int j = 0; j < 3; j++) {
			[[squares cellAtRow:i column:j] setImage:nil];
		}
	}
}

- (void)reset
{
	[super closeSheet];
	[board endGame];
	[self clearBoard];
	[squares setEnabled:NO];
	[self updateStatus];
}

- (void)updateStatus
{
	NSString *msg;
	switch(state)
	{
		case State_Playing:
			msg = (player == [board nextPlayer] ? STATE_YOUR_TURN : STATE_THEIR_TURN);
			break;
		default:
			msg = STATE_NO_GAME;
			break;
	}
	[status setStringValue:msg];
}

- (BOOL)move:(Player)p atRow:(unsigned)row atColumn:(unsigned)col
{
	if([board move:p atRow:row atColumn:col]) {
		[[squares cellAtRow:row column:col] setImage:(p == PLAYER_X ? image_X : image_O)];

		if([board nextPlayer] == PLAYER_NONE) {
			Player winner = [board winner];
			if(winner != PLAYER_DRAW) {
				[self gameDidComplete:(winner == player ? End_UserWon : End_UserLost) displaySheet:YES];
				[status setStringValue:(winner == player ? YOU_WIN : YOU_LOSE)];
			} else {
				[self gameDidComplete:End_GameTied displaySheet:YES];
				[status setStringValue: TIE];
			}
			[squares setEnabled:NO];
			state = State_GameOver;
		} else {
			[self updateStatus];
		}
		return YES;
	}
	return NO;
}

@end
