//
//  AIContactAccountsPlugin.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 14 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIContactAccountsPlugin.h"
#import "AIContactAccountsPane.h"

@implementation AIContactAccountsPlugin

- (void)installPlugin
{    
	[AIContactAccountsPane contactInfoPane];
}

@end
