//
//  DCGaimNovellJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimNovellJoinChatViewController.h"

@implementation DCGaimNovellJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	if( delegate )
		[delegate setJoinChatEnabled:NO];
}

- (NSString *)nibName
{
	return @"DCGaimNovellJoinChatView";
}

@end
