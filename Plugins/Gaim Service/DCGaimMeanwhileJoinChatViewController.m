//
//  DCGaimMeanwhileJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimMeanwhileJoinChatViewController.h"

@implementation DCGaimMeanwhileJoinChatViewController

#ifndef MEANWHILE_NOT_AVAILABLE

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
}

- (NSString *)nibName
{
	return @"DCGaimMeanwhileJoinChatView";
}

#endif

@end
