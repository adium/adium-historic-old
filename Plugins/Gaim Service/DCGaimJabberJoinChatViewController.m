//
//  DCGaimJabberJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimJabberJoinChatViewController.h"

@implementation DCGaimJabberJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString		*room = [textField_roomName stringValue];
	NSString		*server = [textField_server stringValue];
	NSString		*handle = [textField_handle stringValue];
	NSString		*password = [textField_password stringValue];
	NSDictionary	*chatCreationInfo;
	
	//NSLog(@"#### Jabber joinChatWithAccount: %@ joining",inAccount);
		
	chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:room,@"room",server,@"server",handle,@"handle",password,@"password",nil];


	[self doJoinChatWithName:room
				   onAccount:inAccount
			chatCreationInfo:chatCreationInfo
			invitingContacts:nil
	  withInvitationMessage:nil];

}

- (NSString *)nibName
{
	return @"DCGaimJabberJoinChatView";
}

@end
