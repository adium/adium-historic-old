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

	chat = nil;
	
	NSString	*nibName = [self nibName];
	if (nibName){
		[NSBundle loadNibNamed:nibName owner:self];
	}else{
		NSLog(@"No nib available... we shouldn't ever get here.");
	}

    return(self);
}

- (NSView *)view
{
	return view;
}

- (NSString *)nibName
{
	return nil;
}

- (void)configureForAccount:(AIAccount *)inAccount
{
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{
	NSLog(@"#### DCJoinChatViewController: joinChatWithAccount %@",inAccount);
}

@end
