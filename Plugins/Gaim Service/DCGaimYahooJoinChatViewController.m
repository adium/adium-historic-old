//
//  DCGaimYahooJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimYahooJoinChatViewController.h"

@implementation DCGaimYahooJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString		*room = [textField_roomName stringValue];
	NSDictionary	*chatCreationInfo;
	
	//NSLog(@"#### Yahoo! joinChatWithAccount: %@ joining",inAccount);
		
	NSArray *contacts = [[textField_inviteUsers stringValue] componentsSeparatedByString:@","];
	[self registerToInviteUsers:contacts message:[textField_inviteMessage stringValue]];
	
	chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:room,@"room",nil];
	
	[self doJoinChatWithName:room
				   onAccount:inAccount
			chatCreationInfo:chatCreationInfo
			invitingContacts:nil
	  withInvitationMessage:nil];
	
}

- (NSString *)nibName
{
	return @"DCGaimYahooJoinChatView";
}

@end
