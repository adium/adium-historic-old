//
//  AIAccountSetupConnectionView.m
//  Adium
//
//  Created by Adam Iser on 1/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AIAccountSetupConnectionView.h"
#import "AIAccountProxySettings.h"

@implementation AIAccountSetupConnectionView

- (void)awakeFromNib
{
	proxySettings = [[AIAccountProxySettings alloc] initReplacingView:view_proxySettings];

}

//Configure the account preferences for an account
- (void)configureForAccount:(AIAccount *)inAccount
{
	[proxySettings configureForAccount:inAccount];
}

- (NSSize)desiredSize
{
	return(NSMakeSize(500,386));
}

- (IBAction)cancel:(id)sender
{
	[controller newAccountPane];
}

- (IBAction)okay:(id)sender
{

}

@end
