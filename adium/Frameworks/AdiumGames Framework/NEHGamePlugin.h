//
//  NEHGamePlugin.h
//  Adium
//
//  Created by Nelson Elhage on Sun Jan 18 2004.
//

#import <Foundation/Foundation.h>

@class AIPlugin;
@class NEHGameController;
@protocol AIContentFilter;

#define MSG_TYPE_INVITE		@"Invite"
#define MSG_TYPE_ACK		@"Acknowledge"
#define MSG_TYPE_ACCEPT		@"Accept"
#define MSG_TYPE_REJECT		@"Reject"
#define MSG_TYPE_CANCEL		@"Cancel"
#define MSG_TYPE_END_GAME   @"End Game"
#define MSG_TYPE_MOVE		@"Move"

#define MSG_BUSY			@"Busy"
#define MSG_TIMEOUT			@"Timeout"

#define BUTTON_OK   AILocalizedString(@"OK","")
#define BUTTON_ERR  AILocalizedString(@"OK","")
#define BUTTON_YES  AILocalizedString(@"Yes","")
#define BUTTON_NO   AILocalizedString(@"No","")

//Tag values for the play as radio button group
#define				TAG_PLAYER_1		0
#define				TAG_PLAYER_2		1
#define				TAG_CHOOSE_PLAYER   2

@interface NEHGamePlugin : AIPlugin <AIContentFilter> {
	NSMenuItem				* menuItem_game;
	
	//This dictionary maps [account uniqueObjectID] => 
	//{NSDictionary of [contact uniqueObjectID] =>  NEHGameController*}
	NSMutableDictionary		* gamesForAccounts;
	
	IBOutlet NSWindow		* window_newGame;
	IBOutlet AICompletingTextField	* textField_handle;
	IBOutlet NSPopUpButton  * popUp_account;
	IBOutlet NSMatrix		* radio_playAs;
	
	NSWindowController		* windowController;
	
	//This is of the form "[<Short Game Name>/", just to avoid recreating that
	//every time we try to parse an incoming message
	NSString * prefixString;
}

- (void)endGameWith:(AIListContact*)contact fromAccount:(AIAccount*)account;
- (IBAction)newGame:(id)sender;

- (IBAction)sendInvite:(id)sender;
- (IBAction)cancelInvite:(id)sender;

#pragma mark Selectors for subclasses to implement

//return an autoreleased NEHGameController, initialized with initWithPlugin, of the
//appropriate class
- (NEHGameController*)newController;
- (NSString*)nibName;

//The long name is used in menus, and so on
- (NSString*)gameLongName;
//The short name is used in the menu bar of game windows and as a prefix
//when sending messages. Defaults to the long name
- (NSString*)gameShortName;

//This is called before control is told to send an invitation
//It can be used to set parameters in control based on extra
//options in the New Game window, for example
- (void)willSendInvitation:(NEHGameController*)control;

//I can't personally think of a use for this one, but flexibility is good :)
- (void)willRespondToInvitation:(NEHGameController*)control;


- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
@end
