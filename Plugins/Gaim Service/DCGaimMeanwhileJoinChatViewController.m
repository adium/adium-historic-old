//
//  DCGaimMeanwhileJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimMeanwhileJoinChatViewController.h"
#import "DCJoinChatWindowController.h"

@implementation DCGaimMeanwhileJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	if( delegate )
		[(DCJoinChatWindowController *)delegate setJoinChatEnabled:NO];
}

- (NSString *)nibName
{
	return @"DCGaimMeanwhileJoinChatView";
}

@end
