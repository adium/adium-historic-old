//
//  DCGaimTrepiaJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

#import "DCGaimTrepiaJoinChatViewController.h"

@implementation DCGaimTrepiaJoinChatViewController

#ifndef TREPIA_NOT_AVAILABLE

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
}

- (NSString *)nibName
{
	return @"DCGaimTrepiaJoinChatView";
}

#endif

@end
