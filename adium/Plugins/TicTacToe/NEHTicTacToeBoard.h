/*
NEHTicTacToeBoard - A generic Objective-C TicTacToe board class.
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

typedef enum { PLAYER_NONE, PLAYER_X, PLAYER_O, PLAYER_DRAW } Player;

enum {
	defaultBoardSize = 3
};

@interface NEHTicTacToeBoard : NSObject {
	unsigned boardSize;
	Player **board;

	Player currentPlayer;
	int moves;
}

- (id)initWithSize:(unsigned)size;

- (void)newGame;
- (void)endGame;
- (BOOL)gameOver;
- (Player)nextPlayer;
- (Player)winner;
- (BOOL)move:(Player)who atRow:(unsigned)row atColumn:(unsigned)col;

@end
