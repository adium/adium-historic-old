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

#import <AdiumGames/NEHGamePlugin.h>

#pragma mark Message definitions

#define MSG_TYPE_INVITE		@"Invite"
#define MSG_TYPE_ACK		@"Acknowledge"
#define MSG_TYPE_ACCEPT		@"Accept"
#define MSG_TYPE_REJECT		@"Reject"
#define MSG_TYPE_CANCEL		@"Cancel"
#define MSG_TYPE_END_GAME   @"End Game"
#define MSG_TYPE_MOVE		@"Move"

#define MSG_BUSY			@"Busy"
#define MSG_TIMEOUT			@"Timeout"

#define BUTTON_OK   AILocalizedString(@"Okay","")
#define BUTTON_ERR  AILocalizedString(@"Okay","")

@interface NEHTicTacToePlugin : NEHGamePlugin {
}


@end
