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
	
	NSLog(@"#### Yahoo! joinChatWithAccount: %@ joining",inAccount);
	
	chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:room,@"room",nil];
	
	[[adium contentController] chatWithName:room
								  onAccount:inAccount
						   chatCreationInfo:chatCreationInfo];
}

- (NSString *)nibName
{
	return @"DCGaimYahooJoinChatView";
}

@end
