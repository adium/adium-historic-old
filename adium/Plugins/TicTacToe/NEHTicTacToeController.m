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
#import "NEHTicTacToeController.h"

#define TTT_NIB @"TicTacToeBoard"

@implementation NEHTicTacToeController

#pragma mark Strings

#define BUTTON_OK   AILocalizedString(@"OK","")
#define BUTTON_ERR  AILocalizedString(@"OK","")

#define GAME_OVER   AILocalizedString(@"Game Over","Title for game end pane")
#define YOU_WIN		AILocalizedString(@"You win!","")
#define YOU_LOSE		AILocalizedString(@"You lost...","")
#define TIE			AILocalizedString(@"It's a Tie!","Message when the game ends in a tie")
#define TURN_X		AILocalizedString(@"X's turn","")
#define TURN_O		AILocalizedString(@"O's turn","")
#define CONTACT_NOT_FOUND			AILocalizedString(@"Contact Not Found","")
#define CONTACT_NOT_FOUND_MESSAGE   AILocalizedString(@"Unable to find contact '%@'","")
#define PLAY_FIRST  AILocalizedString(@"(You will play first)","")
#define PLAY_SECOND AILocalizedString(@"(You will play second)","")
#define STATE_NO_GAME		AILocalizedString(@"No game.","Status message when there is no game in progress")
#define STATE_YOUR_TURN		AILocalizedString(@"Your turn.","")
#define STATE_THEIR_TURN	AILocalizedString(@"Waiting for opponent","Status message when it is the other player's turn")
#define INVITE_CANCELLED			AILocalizedString(@"Invite cancelled","")
#define INVITE_CANCELLED_MESSAGE	AILocalizedString(@"The invitation was cancelled.","")
#define INVITE_REJECTED			AILocalizedString(@"Invite rejected","")
#define INVITE_REJECTED_MESSAGE	AILocalizedString(@"The invitation was turned down.","")
#define GAME_ENDED			AILocalizedString(@"Game ended","")
#define GAME_ENDED_MESSAGE	AILocalizedString(@"Your opponent cancelled the game.","")
#define TIMEOUT				AILocalizedString(@"Invitation timed out.","")
#define TIMEOUT_MESSAGE		AILocalizedString(@"The invitation timed out. The other player most likely is not using the TicTacToe plugin.","")

#pragma mark Message defitions

#define MSG_TYPE_INVITE		@"Invite"
#define MSG_TYPE_ACK		@"Acknowledge"
#define MSG_TYPE_ACCEPT		@"Accept"
#define MSG_TYPE_REJECT		@"Reject"
#define MSG_TYPE_CANCEL		@"Cancel"
#define MSG_TYPE_END_GAME   @"End Game"
#define MSG_TYPE_MOVE		@"Move"

#define MSG_BUSY			@"Busy"
#define MSG_TIMEOUT			@"Timeout"

#define TIMEOUT_SECONDS		10

#pragma mark Init/Shutdown stuff

static NEHTicTacToeController * sharedInstance = nil;

+ (id)install
{
	if(!sharedInstance)
		sharedInstance = [[self alloc] initWithWindowNibName:TTT_NIB];
	return sharedInstance;
}

+ (void)uninstall
{
	[sharedInstance cleanup];
	[sharedInstance release];
}

+ (id)showBoard
{
	[sharedInstance showWindow:nil];
	return sharedInstance;
}

- (void)awakeFromNib
{
	image_X = [self loadImage:@"X"];
	image_O = [self loadImage:@"O"];
//	board = [[NEHTicTacToeBoard alloc] init];
	[self reset];
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

- (id)initWithWindowNibName:(NSString*)nib
{
	[super initWithWindowNibName:nib];
	[[adium contentController] registerIncomingContentFilter:self];
	return self;
}

- (void)cleanup
{
	[image_X release];
	[image_O release];
//	[board release];
//	if(state == State_Playing)
//		[self sendMessage:@"Client Quit" ofType:MSG_TYPE_END_GAME];
}

#pragma mark Main window actions

- (IBAction)endGame:(id)sender
{
	if(state == State_Playing)
	{
		[self reset];
		[self sendMessage:@"" ofType:MSG_TYPE_END_GAME];
	}
	else if(state == State_GameOver)
		[self reset];
	else
		NSBeep();
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

- (IBAction)newGame:(id)sender
{
	if(state != State_None && state != State_GameOver)
	{
		NSBeep();
		return;
	}
	AIListContact   *selectedContact = [[adium contactController] selectedContact];
	[self showWindow:nil];
	[NSApp beginSheet:sheet_newGame modalForWindow:boardWindow
				modalDelegate:self didEndSelector:NULL contextInfo:nil];
				
	if(selectedContact)
		[textField_handle setStringValue:[selectedContact UID]];
	else
		[textField_handle setStringValue:@""];
	
	NSEnumerator		*enumerator;
    AIListContact		*contact;
    AIAccount			*account;
    
    //Configure the auto-complete view
    enumerator = [[[adium contactController] allContactsInGroup:nil subgroups:YES] objectEnumerator];
    while((contact = [enumerator nextObject])){
        [textField_handle addCompletionString:[contact UID]];
    }

    //Configure the handle type menu
    [popUp_account removeAllItems];
    [[popUp_account menu] setAutoenablesItems:NO];

    //Insert a menu item for each available account
    enumerator = [[[adium accountController] accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
        NSMenuItem	*menuItem;
        
        //Create the menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:[account displayName] target:self action:@selector(selectAccount:) keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];

        //Disabled the menu item if the account is offline
        if(![[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil onAccount:account]){
            [menuItem setEnabled:NO];
        }else{
            [menuItem setEnabled:YES];
        }

        //add the menu item
        [[popUp_account menu] addItem:menuItem];
    }

    //Select the last used account / Available online account
    [popUp_account selectItemAtIndex:[popUp_account indexOfItemWithRepresentedObject:[[adium accountController] accountForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil]]];
	state = State_InviteSent;
}

#pragma mark Invite Window Actions

- (IBAction) cancelInvite:(id)sender
{
	[timeout invalidate];
	[sheet_newGame orderOut:nil];
    [NSApp endSheet:sheet_newGame];
	[self reset];
}

- (IBAction) sendInvite: (id)sender
{
	[sheet_newGame orderOut:nil];
    [NSApp endSheet:sheet_newGame];
	
    NSString		*UID;
    AIServiceType	*serviceType;

    //Get the service type and UID
    account_Player = [[popUp_account selectedItem] representedObject];
    serviceType = [[account_Player service] handleServiceType];
    UID = [serviceType filterUID:[textField_handle stringValue]];
        
    //Find the contact
    contact_OtherPlayer = 
		[[adium contactController] contactInGroup:nil withService:[serviceType identifier] UID:UID serverGroup:nil create:YES];
    if(contact_OtherPlayer){
        int playAs = [radio_playAs selectedRow];
		if(playAs == 2) playAs = rand()%2;
		player = playAs?PLAYER_O:PLAYER_X;
		//Send the invitation, including info on who we wish to play as
		[self sendMessage:(player == PLAYER_X)?@"X":@"O" ofType:MSG_TYPE_INVITE];
		[newGame setEnabled:NO];
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
		[NSApp beginSheet:sheet_inviteSent modalForWindow: boardWindow modalDelegate: self 
					didEndSelector: NULL contextInfo: nil];
		timeout = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_SECONDS target:self selector:@selector(inviteTimedOut:) userInfo:nil repeats:NO];
    }
	else
	{
		NSRunAlertPanel(CONTACT_NOT_FOUND,[NSString stringWithFormat:CONTACT_NOT_FOUND_MESSAGE,[textField_handle stringValue]],
							BUTTON_ERR,nil,nil);
	}
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
	[sheet_acceptInvite orderOut:nil];
	[NSApp endSheet:sheet_acceptInvite];
	[self sendMessage:@"" ofType:MSG_TYPE_REJECT];
	[self reset];
}

- (IBAction)retractInvite:(id)sender
{
	[sheet_inviteSent orderOut:nil];
	[NSApp endSheet:sheet_inviteSent];
	[self sendMessage:@"" ofType:MSG_TYPE_CANCEL];
	[self reset];
}

- (IBAction)selectAccount: (id) sender
{
}

- (void)inviteTimedOut: (NSTimer*) timer
{
	//Send a cancel message here, in case there *is* a
	//plugin on the other end, and we're just on a really bad connection
	[self sendMessage:MSG_TIMEOUT ofType:MSG_TYPE_CANCEL];
	[timer invalidate];
	timeout = nil;
	[sheet_inviteSent orderOut:nil];
	[NSApp endSheet:sheet_inviteSent];
	NSRunAlertPanel(TIMEOUT,TIMEOUT_MESSAGE,BUTTON_OK,nil,nil);	
	[self reset];
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
	NSWindow * sheet = [boardWindow attachedSheet];
	if(sheet)
	{
		[sheet orderOut:nil];
		[NSApp endSheet:sheet];
	}
	[board endGame];
	[self clearBoard];
	[squares setEnabled:NO];
	[newGame setEnabled:YES];
	[endGame setEnabled:NO];
	state = State_None;
	[self updateStatus];
}

- (void)beginGame
{
	[board newGame];
	[self clearBoard];
	[squares setEnabled:YES];
	[newGame setEnabled:NO];
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
				NSRunAlertPanel(GAME_OVER,(winner == player)?
									YOU_WIN : YOU_LOSE, BUTTON_OK, nil, nil);
				[status setStringValue: (winner == player)?YOU_WIN:YOU_LOSE];
				[squares setEnabled:NO];
			}
			else				//Tie
			{
				NSRunAlertPanel(GAME_OVER,TIE, BUTTON_OK, nil, nil);
				[status setStringValue: TIE];
				[squares setEnabled:NO];
			}
			state = State_GameOver;
			[newGame setEnabled:YES];
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
	[[adium interfaceController] setActiveChat:chat];
		
		
	NSAttributedString * message = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"[TTT/%@]:%@",type,msg]]autorelease];
	
	AIContentMessage	*content;
                
	content = [AIContentMessage messageInChat:chat
										withSource:from
										destination:to
										date:nil
										message:message
										autoreply:NO];
//	[content setDisplayContent:NO];
	
	[[adium contentController] sendContentObject:content];
}

- (void)filterContentObject:(AIContentObject *)inobj
{
	if(![[inobj type] isEqual:CONTENT_MESSAGE_TYPE])
		return;
	NSString * str = [[((AIContentMessage*)inobj) message] string];
	NSRange start = [str rangeOfString:@"[TTT/"];
	NSRange end = [str rangeOfString:@"]:"];
	if(start.location != 0 || end.location == NSNotFound)
		return;
	NSRange r;
	r.location = start.length;
	r.length = end.location - r.location;
	NSString * type = [str substringWithRange:r];
	NSString * msg;
	if([str length] > end.location+end.length)
		msg = [str substringFromIndex:(end.location+end.length)];
	else
		msg = @"";
		
	AIListContact * contact = [inobj source];
//	[inobj setDisplayContent:NO];
	if([type isEqualToString:MSG_TYPE_INVITE])
	{
		if(state == State_None || state == State_GameOver)
		{
			[self showWindow:nil];
			account_Player = [inobj destination];
			contact_OtherPlayer = contact;
			state = State_InviteReceived;
			
			[textField_remoteContact setStringValue:[contact displayName]];
			if([msg isEqualToString:@"X"])
				player = PLAYER_O;
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
			[self sendMessage:@"" ofType:MSG_TYPE_ACK];
			[NSApp beginSheet:sheet_acceptInvite modalForWindow:boardWindow
				modalDelegate:self didEndSelector:NULL contextInfo:nil];
		}
		else
			[self sendMessage:MSG_BUSY ofType:MSG_TYPE_REJECT toContact:contact fromAccount:[inobj destination] inChat:[inobj chat]];
	}
	if([inobj source] != contact_OtherPlayer)
	{
		NSLog(@"TTT:Dropped %@ message from account %@",type,[[inobj source] displayName]);
		return;
	}
	if([inobj destination] != account_Player)
	{
		NSLog(@"TTT:Dropped %@ message to account %@",type,[[inobj destination] displayName]);
		return;
	}
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
		else NSLog(@"TTT:Move message received with state %d.",state);
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
			[sheet_inviteSent orderOut:nil];
			[NSApp endSheet:sheet_inviteSent];
			[self reset];
			NSRunAlertPanel(INVITE_REJECTED,INVITE_REJECTED_MESSAGE,BUTTON_OK,nil,nil);
		}
		else NSLog(@"TTT:Move message received with state %d.",state);
	}
	else if([type isEqualToString:MSG_TYPE_CANCEL])
	{
		if(state == State_InviteReceived)
		{
			[sheet_acceptInvite orderOut:nil];
			[NSApp endSheet:sheet_acceptInvite];
			[self reset];
			NSRunAlertPanel(INVITE_CANCELLED,INVITE_CANCELLED_MESSAGE,BUTTON_OK,nil,nil);
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
			NSRunAlertPanel(GAME_ENDED,GAME_ENDED_MESSAGE,BUTTON_OK,nil,nil);
			[self reset];
		}
		else NSLog(@"TTT:End game message received with state %d.",state);
	}
}

@end
