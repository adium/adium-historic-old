//
//  NEHGameController.m
//  Adium XCode
//
//  Created by Nelson El-Hage on Sun Jan 18 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NEHGameController.h"
#import "NEHGamePlugin.h"

#define BUTTON_OK   AILocalizedString(@"OK","")
#define BUTTON_ERR  AILocalizedString(@"OK","")

#define INVITE_CANCELLED			AILocalizedString(@"Invite cancelled","")
#define INVITE_CANCELLED_MESSAGE	AILocalizedString(@"The invitation was cancelled.","")
#define INVITE_REJECTED				AILocalizedString(@"Invite rejected","")
#define INVITE_REJECTED_MESSAGE		AILocalizedString(@"The invitation was turned down.","")
#define GAME_ENDED			AILocalizedString(@"Game ended","")
#define GAME_ENDED_MESSAGE	AILocalizedString(@"Your opponent cancelled the game.","")
#define TIMEOUT				AILocalizedString(@"Invitation timed out.","")
#define TIMEOUT_MESSAGE		AILocalizedString(@"The invitation timed out. The other player most likely is not using the appropriate plugin.","")

#define GAME_OVER			AILocalizedString(@"Game Over","Title for game end pane")
#define YOU_WIN				AILocalizedString(@"You win!","")
#define YOU_LOSE			AILocalizedString(@"You lost...","")
#define TIE					AILocalizedString(@"It's a Tie!","Message when the game ends in a tie")

#define TIMEOUT_SECONDS		10

@implementation NEHGameController

- (id) initWithPlugin:(NEHGamePlugin*)inPlugin
{
	plugin = inPlugin;
	[super initWithWindowNibName:[self nibName]];
	return self;
}

- (void)handleInvitation:(NSString *)msg account:(AIAccount*)account contact:(AIListContact*)contact
{
	account_Player = account;
	contact_OtherPlayer = contact;
	state = State_InviteReceived;
	
	[self showWindow:nil];
	[self updateTitle];
	[self sendMessage:@"" ofType:MSG_TYPE_ACK];
	int playAs;
	if([msg isEqualToString:[self firstPlayerName]])
		playAs = SECOND_PLAYER;		//The message indicates what the *other* side will play as
	else
		playAs = FIRST_PLAYER;
	[self didReceiveInvitation:playAs];
	[NSApp beginSheet:sheet_acceptInvite modalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (void)sendInvitation:(int)playAs account:(AIAccount*)account contact:(AIListContact*)contact
{
	account_Player = account;
	contact_OtherPlayer = contact;
	state = State_InviteSent;
	
	[self showWindow:nil];
	[self updateTitle];
	
	//Send the invitation, including info on who we wish to play as
	[self sendMessage:(playAs == FIRST_PLAYER)?[self firstPlayerName]:[self secondPlayerName] ofType:MSG_TYPE_INVITE];
	[self didSendInvitation:playAs];
	
	[NSApp beginSheet:sheet_inviteSent modalForWindow:[self window] modalDelegate:self didEndSelector: NULL contextInfo: nil];
	timeout = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_SECONDS target:self selector:@selector(inviteTimedOut:) userInfo:nil repeats:NO];
}

- (void)updateTitle
{
	[[self window] setTitle: [NSString stringWithFormat:@"%@ : %@",
								[plugin gameShortName],
								[contact_OtherPlayer displayName]]];
}

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

- (void)gameDidComplete:(GameEndState)end displaySheet:(BOOL)display
{
	if(display)
		NSBeginAlertSheet(GAME_OVER,BUTTON_OK,nil,nil,[self window],nil,NULL,NULL,NULL,end==End_GameTied?TIE:(end == End_UserWon?YOU_WIN:YOU_LOSE));
}

#pragma mark Things for subclasses to implement

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
			[self closeSheet];
			state = State_Playing;
			[self beginNewGame];
		}
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
			[self closeSheet];
			NSBeginAlertSheet(INVITE_REJECTED,BUTTON_OK,nil,nil,[self window],self,NULL,@selector(end:returnCode:contextInfo:),NULL,INVITE_REJECTED_MESSAGE);
		}
	}
	else if([type isEqualToString:MSG_TYPE_CANCEL])
	{
		if(state == State_InviteReceived)
		{
			[self closeSheet];
			NSBeginAlertSheet(INVITE_CANCELLED,BUTTON_OK,nil,nil,[self window],self,NULL,@selector(end:returnCode:contextInfo:),NULL,INVITE_CANCELLED_MESSAGE);
		}
	}
	else if([type isEqualToString:MSG_TYPE_END_GAME])
	{
		if(state == State_Playing)
		{
			NSBeginAlertSheet(GAME_ENDED,BUTTON_OK,nil,nil,[self window],self,NULL,@selector(end:returnCode:contextInfo:),NULL,GAME_ENDED_MESSAGE);
		}
	}
}

- (void)beginNewGame
{
}

- (void)gameDidEnd
{
}

- (void)didSendInvitation:(int)playAs
{
}

- (void)didReceiveInvitation:(int)playAs
{
}

- (NSString*)nibName
{
	return @"";
}


- (NSString*)firstPlayerName
{
	return @"first";
}

- (NSString*)secondPlayerName
{
	return @"second";
}

#pragma mark Actions

- (IBAction)endGame:(id)sender
{
	if(state == State_Playing)
	{
		[self sendMessage:@"" ofType:MSG_TYPE_END_GAME];
	}
	[self end:nil returnCode:0 contextInfo:NULL];
}

- (IBAction)acceptInvite:(id)sender
{
	[sheet_acceptInvite orderOut:nil];
	[NSApp endSheet:sheet_acceptInvite];
	[self sendMessage:@"" ofType:MSG_TYPE_ACCEPT];
	state = State_Playing;
	[self beginNewGame];
}

- (IBAction)rejectInvite:(id)sender
{
	[self sendMessage:@"" ofType:MSG_TYPE_REJECT];
	[self end:nil returnCode:0 contextInfo:NULL];
}

- (IBAction)retractInvite:(id)sender
{
	if(timeout)[timeout invalidate];
	[self sendMessage:@"" ofType:MSG_TYPE_CANCEL];
	[self end:nil returnCode:0 contextInfo:NULL];
}

- (void)inviteTimedOut: (NSTimer*) timer
{
	//Send a cancel message here, in case there *is* a
	//plugin on the other end, and we're just on a really bad connection
	[self sendMessage:MSG_TIMEOUT ofType:MSG_TYPE_CANCEL];
	[timer invalidate];
	[self closeSheet];
	timeout = nil;
	NSBeginAlertSheet(TIMEOUT,BUTTON_OK,nil,nil,[self window],self,NULL,@selector(end:returnCode:contextInfo:),NULL,TIMEOUT_MESSAGE);
}

#pragma mark More Internals

- (void)sendMessage:(NSString*)msg ofType:(NSString*)type toContact:(AIListContact*)to fromAccount:(AIAccount*)from inChat:(AIChat*)chat
{
	NSAttributedString * message = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"[%@/%@]:%@",[plugin gameShortName],type,msg]]autorelease];
	
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

- (void)end:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[self close];
	[self gameDidEnd];
	[plugin endGameWith:contact_OtherPlayer fromAccount:account_Player];
}

- (void)closeSheet
{
	NSWindow * sheet = [[self window] attachedSheet];
	if(sheet)
	{
		[sheet orderOut:nil];
		[NSApp endSheet:sheet];
	}
}
	
@end
