//
//  AIContactAccountsPlugin.m
//  Adium
//
//  Created by Adam Iser on Mon Jun 14 2004.
//

#import "AIContactAccountsPlugin.h"
#import "AIContactAccountsPane.h"

@implementation AIContactAccountsPlugin

- (void)installPlugin
{    
	[AIContactAccountsPane contactInfoPane];
}

@end
