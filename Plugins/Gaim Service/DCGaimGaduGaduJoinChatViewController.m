//
//  DCGaimGaduGaduJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
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
