//
//  ESGaimAntepoAccountViewController.m
//  Adium
//
//  Created by Evan Schoenberg on 11/24/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import "ESGaimAntepoAccountViewController.h"

@implementation ESGaimAntepoAccountViewController

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	//Force allowing of plain text passwords over unencrypted streams
	[checkBox_allowPlaintext setState:NSOnState];
	[checkBox_allowPlaintext setEnabled:NO];
}

@end
