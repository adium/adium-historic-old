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

#import "NEHTicTacToeController.h"
#import "NEHTicTacToePlugin.h"

#define TTT_NIB @"TicTacToeBoard"

@implementation NEHTicTacToeController

#pragma mark Strings

#define GAME_OVER			AILocalizedString(@"Game Over","Title for game end pane")
#define YOU_WIN				AILocalizedString(@"You win!","")
#define YOU_LOSE			AILocalizedString(@"You lost...","")
#define TIE					AILocalizedString(@"It's a Tie!","Message when the game ends in a tie")
#define TURN_X				AILocalizedString(@"X's turn","")
#define TURN_O				AILocalizedString(@"O's turn","")
#define PLAY_FIRST			AILocalizedString(@"(You will play first)","")
#define PLAY_SECOND			AILocalizedString(@"(You will play second)","")
#define STATE_NO_GAME		AILocalizedString(@"No game.","Status message when there is no game in progress")
#define STATE_YOUR_TURN		AILocalizedString(@"Your turn.","")
#define STATE_THEIR_TURN	AILocalizedString(@"Waiting for opponent","Status message when it is the other player's turn")
#define INVITE_CANCELLED			AILocalizedString(@"Invite cancelled","")
#define INVITE_CANCELLED_MESSAGE	AILocalizedString(@"The invitation was cancelled.","")
#define INVITE_REJECTED				AILocalizedString(@"Invite rejected","")
#define INVITE_REJECTED_MESSAGE		AILocalizedString(@"The invitation was turned down.","")
#define GAME_ENDED			AILocalizedString(@"Game ended","")
#define GAME_ENDED_MESSAGE	AILocalizedString(@"Your opponent cancelled the game.","")
#define TIMEOUT				AILocalizedString(@"Invitation timed out.","")
#define TIMEOUT_MESSAGE		AILocalizedString(@"The invitation timed out. The other player most likely is not using the TicTacToe plugin.","")

#define TIMEOUT_SECONDS		10

#pragma mark Init/Shutdown stuff

- (void)awakeFromNib
{
	image_X = [self loadImage:@"X"];
	image_O = [self loadImage:@"O"];
	[self reset];
}

- (id)init
{
	[super initWithWindowNibName:TTT_NIB];
	return self;
}

- (void)handleInvitation:(NSString *)msg account:(AIAccount*)account contact:(AIListContact*)contact
{
	account_Player = account;
	contact_OtherPlayer = contact;
	[self showWindow:nil];
	[self updateTitle];
	
	[self sendMessage:@"" ofType:MSG_TYPE_ACK];
	
	[textField_remoteContact setStringValue:[contact displayName]];
	if([msg isEqualToString:@"X"])
		player = PLAYER_O;				//This is not a typo - the message is what *they* will play as
	else
		player = PLAYER_X;
		
	if(player == PLAYER_X)
	{
		[imageView_acceptPlayAs setImage:image_X];
		[textField_acceptMove setStringValue:PLAY_FIRST];
	}
	else
	{
		[imageView_acceptPlayAs setImage:image_O];
		[textField_acceptMove setStringValue:PLAY_SECOND];
	}
	
	[NSApp beginSheet:sheet_acceptInvite modalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	state = State_InviteReceived;
}


- (void)sendInvitation:(Player)inPlayer account:(AIAccount*)account contact:(AIListContact*)contact
{
	account_Player = account;
	contact_OtherPlayer = contact;
	[self showWindow:nil];
	[self updateTitle];
	player = inPlayer;
	
	//Send the invitation, including info on who we wish to play as
	[self sendMessage:(player == PLAYER_X)?@"X":@"O" ofType:MSG_TYPE_INVITE];
	if(player == PLAYER_X)
	{
		[imageView_sentPlayAs setImage:image_X];
		[textField_sentMove setStringValue:PLAY_FIRST];
	}
	else
	{
		[imageView_sentPlayAs setImage:image_O];
		[textField_sentMove setStringValue:PLAY_SECOND];
	}
	[NSApp beginSheet:sheet_inviteSent modalForWindow:[self window] modalDelegate:self didEndSelector: NULL contextInfo: nil];
	timeout = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_SECONDS target:self selector:@selector(inviteTimedOut:) userInfo:nil repeats:NO];
	state = State_InviteSent;
}

- (void)updateTitle
{
	[[self window] setTitle: [NSString stringWithFormat:@"TTT : %@",[contact_OtherPlayer displayName]]];
}

- (NSImage*) loadImage:(NSString*)name
{
	NSString	* path;
	NSImage		* img = nil;
	NSBundle	* bundle = [NSBundle bundleForClass:[self class]];
	if(path = [bundle pathForImageResource:name])
	{
		img = [[NSImage alloc] initWithContentsOfFile:path];
	}
	else
	{
		NSLog(@"TTT:Unable to open image %@",name);
	}
	return img;
}

- (void)cleanup
{
	[image_X release];
	[image_O release];
}

#pragma mark Main window actions

- (IBAction)endGame:(id)sender
{
	if(state == State_Playing)
	{
		[self reset];
		[self sendMessage:@"" ofType:MSG_TYPE_END_GAME];
		[self end:nil returnCode:0 contextInfo:NULL];
	}
	else NSBeep();
}

- (IBAction)move:(id)sender
{
	if(state  != State_Playing)
		return;
	int		row = [squares selectedRow], 
			col = [squares selectedColumn];
	if([self move:player atRow:row atColumn:col])
	{
		[self sendMessage:[NSString stringWithFormat:@"%d,%d",row,col] ofType:MSG_TYPE_MOVE];
	}
	else
		NSBeep();
}

#pragma mark Other actions

- (IBAction)acceptInvite:(id)sender
{
	[sheet_acceptInvite orderOut:nil];
	[NSApp endSheet:sheet_acceptInvite];
	[self sendMessage:@"" ofType:MSG_TYPE_ACCEPT];
	[self beginGame];
}

- (IBAction)rejectInvite:(id)sender
{
	[self reset];
	[self sendMessage:@"" ofType:MSG_TYPE_REJECT];
}

- (IBAction)retractInvite:(id)sender
{
	if(timeout)[timeout invalidate];
	[self sendMessage:@"" ofType:MSG_TYPE_CANCEL];
	[self end:nil returnCode:0 contextInfo:NULL];
}

- (IBAction)selectAccount: (id) sender
{
}

- (void)inviteTimedOut: (NSTimer*) timer
{
	[self reset];
	//Send a cancel message here, in case there *is* a
	//plugin on the other end, and we're just on a really bad connection
	[self sendMessage:MSG_TIMEOUT ofType:MSG_TYPE_CANCEL];
	[timer invalidate];
	timeout = nil;
	NSBeginAlertSheet(TIMEOUT,BUTTON_OK,nil,nil,[self window],self,NULL,@selector(end:returnCode:contextInfo:),NULL,TIMEOUT_MESSAGE);
}

#pragma mark Board Management Stuff

- (void)clearBoard
{
	int i,j;
	for(i=0;i<3;i++)
		for(j=0;j<3;j++)
			[[squares cellAtRow:i column:j] setImage:nil];
}

- (void)reset
{
	NSWindow * sheet = [[self window] attachedSheet];
	if(sheet)
	{
		[sheet orderOut:nil];
		[NSApp endSheet:sheet];
	}
	[board endGame];
	[self clearBoard];
	[squares setEnabled:NO];
	[endGame setEnabled:NO];
	state = State_None;
	[self updateStatus];
}

- (void)beginGame
{
	[board newGame];
	[self clearBoard];
	[squares setEnabled:YES];
	[endGame setEnabled:YES];
	state = State_Playing;
	[self updateStatus];
}

- (void)updateStatus
{
	NSString * msg;
	switch(state)
	{
		case State_Playing:
			if(player == [board nextPlayer])
				msg = STATE_YOUR_TURN;
			else
				msg = STATE_THEIR_TURN;
			break;
		default:
			msg = STATE_NO_GAME;
			break;
	}
	[status setStringValue:msg];
}

- (BOOL)move:(Player)p atRow:(int)row atColumn:(int)col
{
	Player winner;
	if([board move:p atRow:row atColumn:col])
	{
		if(p == PLAYER_O)
			[[squares cellAtRow:row column:col] setImage:image_O];
		else
			[[squares cellAtRow:row column:col] setImage:image_X];
			
		if([board nextPlayer] == PLAYER_NONE)
		{
			winner = [board winner];
			if(winner != PLAYER_NONE)
			{
				NSBeginAlertSheet(GAME_OVER,BUTTON_OK,nil,nil,[self window],self,NULL,@selector(end:returnCode:contextInfo:),NULL,(winner == player)?YOU_WIN:YOU_LOSE);
				[status setStringValue: (winner == player)?YOU_WIN:YOU_LOSE];
				[squares setEnabled:NO];
			}
			else				//Tie
			{
				NSBeginAlertSheet(GAME_OVER,BUTTON_OK,nil,nil,[self window],self,NULL,@selector(end:returnCode:contextInfo:),NULL,TIE);
				[status setStringValue: TIE];
				[squares setEnabled:NO];
			}
			state = State_GameOver;
		}
		else [self updateStatus];
		return YES;
	}
	return NO;
}

#pragma mark Message-passing stuff

- (void)sendMessage:(NSString*)msg ofType:(NSString*)type
{
	//Open a chat if needed
	AIChat * chat;
	if([[[adium contentController] allChatsWithListObject:contact_OtherPlayer] count] == 0)
		chat = [[adium contentController] openChatOnAccount:account_Player withListObject:contact_OtherPlayer];
	else
		chat = [[[adium contentController] allChatsWithListObject:contact_OtherPlayer] objectAtIndex:0];
	[self sendMessage:msg ofType:type toContact:contact_OtherPlayer fromAccount:account_Player inChat:chat];
}

- (void)sendMessage:(NSString*)msg ofType:(NSString*)type toContact:(AIListContact*)to fromAccount:(AIAccount*)from inChat:(AIChat*)chat
{
	NSAttributedString * message = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"[TTT/%@]:%@",type,msg]]autorelease];
	
	AIContentMessage	*content;
                
	content = [AIContentMessage messageInChat:chat
										withSource:from
										destination:to
										date:nil
										message:message
										autoreply:NO];
	[content setDisplayContent:NO];
	[content setTrackContent:NO];
	
	[[adium contentController] sendContentObject:content];
}

- (void)handleMessage:(NSString*)msg ofType:(NSString*)type
{
	if([type isEqualToString:MSG_TYPE_ACK])
	{
		if(timeout)
		{
			[timeout invalidate];
			timeout = nil;
		}
	}
	else if([type isEqualToString:MSG_TYPE_ACCEPT])
	{
		if(state == State_InviteSent)
		{
			if(timeout)
			{
				[timeout invalidate];
				timeout = nil;
			}
			[sheet_inviteSent orderOut:nil];
			[NSApp endSheet:sheet_inviteSent];
			[self beginGame];
		}
		else NSLog(@"TTT:Accept message received with state %d.",state);
	}
	else if([type isEqualToString:MSG_TYPE_REJECT])
	{
		if(state == State_InviteSent)
		{
			if(timeout)
			{
				[timeout invalidate];
				timeout = nil;
			}
			[self reset];
			NSBeginAlertSheet(INVITE_REJECTED,BUTTON_OK,nil,nil,[self window],self,NULL,@selector(end:returnCode:contextInfo:),NULL,INVITE_REJECTED_MESSAGE);
		}
		else NSLog(@"TTT:Reject message received with state %d.",state);
	}
	else if([type isEqualToString:MSG_TYPE_CANCEL])
	{
		if(state == State_InviteReceived)
		{
			[self reset];
			NSBeginAlertSheet(INVITE_CANCELLED,BUTTON_OK,nil,nil,[self window],self,NULL,@selector(end:returnCode:contextInfo:),NULL,INVITE_CANCELLED_MESSAGE);
		}
		else NSLog(@"TTT:Cancel message received with state %d.",state);
	}
	else if([type isEqualToString:MSG_TYPE_MOVE])
	{
		if(state == State_Playing)
		{
			int row,col;
			row = [msg characterAtIndex:0] - '0';
			col = [msg characterAtIndex:2] - '0';
			[self move:(player==PLAYER_X?PLAYER_O:PLAYER_X) atRow:row atColumn:col];
		}
		else NSLog(@"TTT:Move message received with state %d.",state);
	}
	else if([type isEqualToString:MSG_TYPE_END_GAME])
	{
		if(state == State_Playing)
		{
			[self reset];
			NSBeginAlertSheet(GAME_ENDED,BUTTON_OK,nil,nil,[self window],self,NULL,@selector(end:returnCode:contextInfo:),NULL,GAME_ENDED_MESSAGE);
		}
		else NSLog(@"TTT:End game message received with state %d.",state);
	}
}

- (void)end:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[self close];
	[self cleanup];
	[[NEHTicTacToePlugin plugin] endGameFor:self];
}

@end
