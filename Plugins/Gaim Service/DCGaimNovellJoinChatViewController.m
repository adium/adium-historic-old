//
//  DCGaimNovellJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimNovellJoinChatViewController.h"
#import "DCJoinChatWindowController.h"

@implementation DCGaimNovellJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	if( delegate )
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:NO];
}

- (NSString *)nibName
{
	return @"DCGaimNovellJoinChatView";
}

@end
