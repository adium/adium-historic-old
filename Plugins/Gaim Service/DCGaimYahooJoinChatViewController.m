//
//  DCGaimYahooJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimYahooJoinChatViewController.h"

@interface DCGaimYahooJoinChatViewController (PRIVATE)
- (void)validateEnteredText;
@end

@implementation DCGaimYahooJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[delegate setJoinChatEnabled:([[textField_roomName stringValue] length] > 0)];
	[[view window] makeFirstResponder:textField_roomName];
	[super configureForAccount:inAccount];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString		*room = [textField_roomName stringValue];
	NSDictionary	*chatCreationInfo;
	
	chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:room,@"room",nil];
	
	[self doJoinChatWithName:room
				   onAccount:inAccount
			chatCreationInfo:chatCreationInfo
			invitingContacts:[self contactsFromNamesSeparatedByCommas:[textField_inviteUsers stringValue] onAccount:inAccount]
	   withInvitationMessage:[textField_inviteMessage stringValue]];
	
}

- (NSString *)nibName
{
	return @"DCGaimYahooJoinChatView";
}

//Entered text is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	if([notification object] == textField_roomName){
		[self validateEnteredText];
	}
}

- (void)validateEnteredText
{
	NSString *roomName = [textField_roomName stringValue];
	BOOL enabled = NO;
	
	if( roomName && [roomName length] ) {
		enabled = YES;
	}
	
	if( delegate )
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:enabled];
}

@end
