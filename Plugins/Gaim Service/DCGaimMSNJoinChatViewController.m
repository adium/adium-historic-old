//
//  DCGaimMSNJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimMSNJoinChatViewController.h"
#import "DCJoinChatWindowController.h"

@implementation DCGaimMSNJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	if( delegate )
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:NO];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{	
	NSString		*room = [textField_roomName stringValue];
	NSDictionary	*chatCreationInfo;
	
	//NSLog(@"#### MSN joinChatWithAccount: %@ joining %@",inAccount,room);
	
	chatCreationInfo = [NSDictionary dictionaryWithObjectsAndKeys:room,@"room",nil];

	[[adium contentController] chatWithName:room
								  onAccount:inAccount
						   chatCreationInfo:chatCreationInfo];
}

- (NSString *)nibName
{
	return @"DCGaimMSNJoinChatView";
}

@end
