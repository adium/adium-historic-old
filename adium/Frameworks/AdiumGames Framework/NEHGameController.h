//
//  NEHGameController.h
//  Adium XCode
//
//  Created by Nelson El-Hage on Sun Jan 18 2004.
//

#import <Foundation/Foundation.h>

#define FIRST_PLAYER		0
#define SECOND_PLAYER		1

#define MSG_TYPE_INVITE		@"Invite"
#define MSG_TYPE_ACK		@"Acknowledge"
#define MSG_TYPE_ACCEPT		@"Accept"
#define MSG_TYPE_REJECT		@"Reject"
#define MSG_TYPE_CANCEL		@"Cancel"
#define MSG_TYPE_END_GAME   @"End Game"
#define MSG_TYPE_MOVE		@"Move"

#define MSG_BUSY			@"Busy"
#define MSG_TIMEOUT			@"Timeout"

@class NEHGamePlugin;

@class AIWindowController,AIListContact,AIAccount;	

typedef enum {  State_InviteSent, 
				State_InviteReceived,
				State_Playing,
				State_GameOver
				} GameState;
typedef enum {
				End_UserWon,
				End_UserLost,
				End_GameTied
				} GameEndState;
				
@interface NEHGameController : AIWindowController
{
	IBOutlet NSPanel		* sheet_acceptInvite;
	IBOutlet NSPanel		* sheet_inviteSent;
	
	AIListContact			* contact_OtherPlayer;
	AIAccount				* account_Player;
	
	GameState				state;
	NSTimer					* timeout;
	NEHGamePlugin			* plugin;
}

- (void)handleInvitation:(NSString *)msg account:(AIAccount*)account contact:(AIListContact*)contact;
- (void)sendInvitation:(int)playAs account:(AIAccount*)account contact:(AIListContact*)contact;
- (void)updateTitle;

#pragma mark Subclasses use these

- (void)sendMessage:(NSString*)msg ofType:(NSString*)type;

- (void)gameDidComplete:(GameEndState)end displaySheet:(BOOL)display;

#pragma mark Subclasses override

- (id)initWithPlugin:(NEHGamePlugin*)inPlugin;

- (void)handleMessage:(NSString*)msg ofType:(NSString*)type;

- (void)beginNewGame;

- (void)didSendInvitation:(int)playAs;
- (void)didReceiveInvitation:(int)playAs;

- (NSString*)nibName;

//You don't actually need to override these, the default values work, and are never displayed
//but they're here for backwards compatibility with the old Tic Tac Toe plugin
- (NSString*)firstPlayerName;
- (NSString*)secondPlayerName;

#pragma mark Actions
- (IBAction)endGame:(id)sender;

- (IBAction)acceptInvite:(id)sender;
- (IBAction)rejectInvite:(id)sender;

- (IBAction)retractInvite:(id)sender;
- (void)inviteTimedOut: (NSTimer*) timer;

#pragma mark Internal selectors

- (void)sendMessage:(NSString*)msg ofType:(NSString*)type toContact:(AIListContact*)to fromAccount:(AIAccount*)from inChat:(AIChat*)chat;
- (void)end:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)closeSheet;

@end
