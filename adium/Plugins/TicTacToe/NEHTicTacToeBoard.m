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

#define square(i) ((i) * (i))

@implementation NEHTicTacToeBoard

- (id)init
{
	return [self initWithSize:defaultBoardSize];
}

- (id)initWithSize:(unsigned)size
{
	boardSize = size;

	//malloc returns pointers to page boundaries. that means that most of a page
	// (4 K as of Panther) is wasted if we allocate a buffer for each row.
	//so, we allocate a buffer whose contents are arranged like this:
	/*size=3
	0x00 &row_0
	0x04 &row_1
	0x08 &row_2

	0x0C row_0: col_0
	0x10        col_1
	0x14        col_2

	0x18 row_1: col_0
	0x1C        col_1
	0x20        col_2

	0x24 row_2: col_0
	0x28        col_1
	0x2C        col_2
	*/
	size_t sizeOfPointers = sizeof(Player *) * size;
	size_t sizeOfRow      = sizeof(Player)   * size;
	board = malloc((sizeOfRow * size) + sizeOfPointers);

	while(size--) {
		board[size] = (Player *)board + (boardSize + (boardSize * size));
	}

	currentPlayer = PLAYER_NONE;
	return self;
}

- (void)dealloc
{
	free(board);

	[super dealloc];
}

//initialise the board and game state.
- (void)newGame
{
	currentPlayer = PLAYER_X;

	for(unsigned i = 0; i < boardSize; i++) {
		for(unsigned j = 0; j < boardSize; j++) {
			board[i][j] = PLAYER_NONE;
		}
	}

	moves = 0;
}

- (void)endGame
{
	currentPlayer = PLAYER_NONE;
}

//returns whether the game is ended.
- (BOOL)gameOver
{
	return (currentPlayer == PLAYER_NONE) || (moves == square(boardSize)) || ([self winner] != PLAYER_NONE);
}

//returns the player on whom we are waiting, i.e., the next player to move.
- (Player)nextPlayer
{
	return currentPlayer;
}

//searches for a winner. if there is one, returns that player; if not, returns PLAYER_NONE.
- (Player)winner
{
	//a line is defined as a row, column, or diagon.

	//number of X-winnable and O-winnable lines on the board.
	unsigned winnableX = 0, winnableO = 0;

	//the number of X and O squares in the line currently being examined.
	unsigned numX = 0, numO = 0;

	//the coordinates of the square being examined.
	unsigned thisRow, thisCol;

	//first, examine diagons.

	//top-left to bottom-right.
	//for this loop, thisRow is also used as the column index, for efficiency.
	for(thisRow = 0; thisRow < boardSize; ++thisRow) {
		numX += (board[thisRow][thisRow] == PLAYER_X);
		numO += (board[thisRow][thisRow] == PLAYER_O);
	}
	if(numX == boardSize) return PLAYER_X;
	else if(numO == boardSize) return PLAYER_O;
	else {
		winnableX += !numO;
		winnableO += !numX;
	}

	//top-right to bottom-left.
	numX = numO = 0;
	for(thisRow = 0; thisRow < boardSize; ++thisRow) {
		thisCol = (boardSize - 1) - thisRow;

		numX += (board[thisRow][thisCol] == PLAYER_X);
		numO += (board[thisRow][thisCol] == PLAYER_O);
	}
	if(numX == boardSize) return PLAYER_X;
	else if(numO == boardSize) return PLAYER_O;
	else {
		winnableX += !numO;
		winnableO += !numX;
	}
	
	//next, examine rows.
	for(thisRow = 0; thisRow < boardSize; ++thisRow) {
		numX = numO = 0;
		for(thisCol = 0; thisCol < boardSize; ++thisCol) {
			numX += (board[thisRow][thisCol] == PLAYER_X);
			numO += (board[thisRow][thisCol] == PLAYER_O);
		}

		if(numX == boardSize) return PLAYER_X;
		else if(numO == boardSize) return PLAYER_O;
		else {
			winnableX += !numO;
			winnableO += !numX;
		}
	} //for(thisRow = 0; thisRow < boardSize; ++thisRow)

	//finally, examine columns.
	//note that numX and numO are reused; you should imagine that, for this
	//  section, they are named colX and colO instead.
	for(thisCol = 0; thisCol < boardSize; ++thisCol) {
		numX = numO = 0;
		for(thisRow = 0; thisRow < boardSize; ++thisRow) {
			numX += (board[thisRow][thisCol] == PLAYER_X);
			numO += (board[thisRow][thisCol] == PLAYER_O);
		}

		if(numX == boardSize) return PLAYER_X;
		else if(numO == boardSize) return PLAYER_O;
		else {
			winnableX += !numO;
			winnableO += !numX;
		}
	} //for(thisCol = 0; thisCol < boardSize; ++thisCol)

	//no wins found.
	//if a winnable line was found, we return PLAYER_NONE.
	//otherwise, it's a draw.

	return ((currentPlayer == PLAYER_X ? winnableX : winnableO) ? PLAYER_NONE : PLAYER_DRAW);
}

- (BOOL)move:(Player)who atRow:(unsigned)row atColumn:(unsigned)col
{
	if(row < 0 || row > boardSize || col < 0 || col > boardSize) {
		return NO;
	}
	if(board[row][col] != PLAYER_NONE) {
		return NO;
	}
	if(who != currentPlayer) {
		return NO;
	}
	board[row][col] = currentPlayer;

	if([self winner] != PLAYER_NONE || ++moves == square(boardSize)) {
		currentPlayer = PLAYER_NONE;
	} else {
		currentPlayer = (currentPlayer == PLAYER_X ? PLAYER_O : PLAYER_X);
	}

	return YES;
}

@end
