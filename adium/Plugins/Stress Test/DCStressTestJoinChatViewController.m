//
//  DCGaimOscarJoinChatViewController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "DCStressTestJoinChatViewController.h"

#define STRESS_TEST_JOIN_CHAT_VIEW_NIB @"DCStressTestJoinChatView"

@implementation DCStressTestJoinChatViewController

- (NSString *)nibName
{
	return STRESS_TEST_JOIN_CHAT_VIEW_NIB;
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
}

- (IBAction)buttonClicked:(id)sender
{
	NSLog(@"#### StressTest Button Clicked! ####");
}


@end
