/*
NEHTicTacToeBoard - A generic Objective-C TicTacToe board class.
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

#import "NEHTicTacToeBoard.h"

@implementation NEHTicTacToeBoard

- (id)init
{
	currentPlayer = PLAYER_NONE;
	return self;
}

- (void)newGame
{
	currentPlayer = PLAYER_X;
	int i,j;
	for(i=0;i<3;i++)
		for(j=0;j<3;j++)
			board[i][j] = PLAYER_NONE;
	moves = 0;
}

- (void)endGame
{
	currentPlayer = PLAYER_NONE;
}

- (BOOL)gameOver
{
	return (currentPlayer == PLAYER_NONE) || (moves == 9) || ([self winner] != PLAYER_NONE);
}

- (Player)nextPlayer
{
	return currentPlayer;
}

- (Player)winner
{
	int i;
	for(i=0;i<3;i++)
	{
		if(board[i][0] == PLAYER_X && board[i][1] == PLAYER_X && board[i][2] == PLAYER_X)
			return PLAYER_X;
		else if(board[0][i] == PLAYER_X && board[1][i] == PLAYER_X && board[2][i] == PLAYER_X)
			return PLAYER_X;
	}
	if(board[0][0] == PLAYER_X && board[1][1] == PLAYER_X && board[2][2] == PLAYER_X)
		return PLAYER_X;
	else if(board[2][0] == PLAYER_X && board[1][1] == PLAYER_X && board[0][2] == PLAYER_X)
		return PLAYER_X;
		
	for(i=0;i<3;i++)
	{
		if(board[i][0] == PLAYER_O && board[i][1] == PLAYER_O && board[i][2] == PLAYER_O)
			return PLAYER_O;
		else if(board[0][i] == PLAYER_O && board[1][i] == PLAYER_O && board[2][i] == PLAYER_O)
			return PLAYER_O;
	}
	if(board[0][0] == PLAYER_O && board[1][1] == PLAYER_O && board[2][2] == PLAYER_O)
		return PLAYER_O;
	else if(board[2][0] == PLAYER_O && board[1][1] == PLAYER_O && board[0][2] == PLAYER_O)
		return PLAYER_O;
		
	return PLAYER_NONE;
}

- (BOOL)move: (Player)who atRow:(int)row atColumn:(int)col
{
	if(row < 0 || row > 2 || col < 0 || col > 2)
		return NO;
	if(board[row][col] != PLAYER_NONE)
		return NO;
	if(who != currentPlayer)
		return NO;
	board[row][col] = currentPlayer;
	if([self winner] != PLAYER_NONE || ++moves == 9)
		currentPlayer = PLAYER_NONE;
	else
	{
		if(currentPlayer == PLAYER_X)
			currentPlayer = PLAYER_O;
		else
			currentPlayer = PLAYER_X;
	}
	return YES;
}

@end
