//
//  DCGaimMeanwhileJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimMeanwhileJoinChatViewController.h"

@implementation DCGaimMeanwhileJoinChatViewController

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	if( delegate )
		[delegate setJoinChatEnabled:NO];
}

- (NSString *)nibName
{
	return @"DCGaimMeanwhileJoinChatView";
}

@end
