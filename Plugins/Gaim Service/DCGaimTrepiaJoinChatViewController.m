//
//  DCGaimTrepiaJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimTrepiaJoinChatViewController.h"
#import "DCJoinChatWindowController.h"

@implementation DCGaimTrepiaJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	if( delegate )
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:NO];
}

- (NSString *)nibName
{
	return @"DCGaimTrepiaJoinChatView";
}

@end
