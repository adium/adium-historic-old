//
//  DCJoinChatWindowController.m
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "DCJoinChatViewController.h"

@implementation DCJoinChatViewController

//Create a new join chat view
+ (DCJoinChatViewController *)joinChatView
{
	return [[[self alloc] init] autorelease];
}

//Init
- (id)init
{
    [super init];
	
	[NSBundle loadNibNamed:[self nibName] owner:self];

    return(self);
}

- (void)configureForAccount:(AIAccount *)inAccount
{
}

- (NSView *)view
{
	return view;
}

- (NSString *)nibName
{
	return @"";
}

@end
