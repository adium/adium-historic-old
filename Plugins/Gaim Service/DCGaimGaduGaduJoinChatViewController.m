//
//  DCGaimGaduGaduJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimGaduGaduJoinChatViewController.h"
#import "DCJoinChatWindowController.h"

@implementation DCGaimGaduGaduJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	if( delegate )
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:NO];
}

- (NSString *)nibName
{
	return @"DCGaimGaduGaduJoinChatView";
}

@end
