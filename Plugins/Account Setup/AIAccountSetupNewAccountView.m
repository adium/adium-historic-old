//
//  AIAccountSetupNewAccountView.m
//  Adium
//
//  Created by Adam Iser on 12/30/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import "AIAccountSetupNewAccountView.h"


@implementation AIAccountSetupNewAccountView

- (void)configureForService:(AIService *)inService
{
	[service release];
	service = [inService retain];

	//Service icon
	[image_serviceIcon setImage:[AIServiceIcons serviceIconForService:service
																 type:AIServiceIconLarge
															direction:AIIconNormal]];
	[textField_serviceName setStringValue:[NSString stringWithFormat:@"Add %@ Account",[service longDescription]]];
	[textField_serviceHelp setStringValue:[NSString stringWithFormat:@"A %@ account is required to connect with this service.  If you already have an account, enter your information below.",[service shortDescription]]];

	//Fields
	[radio_registerNew setTitle:[NSString stringWithFormat:@"Register a new %@ account",[service shortDescription]]];
	[radio_useExisting setTitle:[NSString stringWithFormat:@"Use an existing %@ account",[service shortDescription]]];

	//Custom username string
	NSString *userNameLabel = [service userNameLabel];
	[textField_userNameLabel setStringValue:[(userNameLabel ? userNameLabel : @"User Name") stringByAppendingString:@":"]];
	
	//Restrict the account name field to valid characters and length
    [textField_accountName setFormatter:
		[AIStringFormatter stringFormatterAllowingCharacters:[service allowedCharactersForAccountName]
													  length:[service allowedLengthForAccountName]
											   caseSensitive:[service caseSensitive]
												errorMessage:AILocalizedString(@"The characters you're entering are not valid for an account name on this service.",nil)]];

	//account view controller
	accountViewController = [[inService accountView] retain];

	//Swap in the account details view
	NSView	*accountView = [accountViewController view];
	float 	accountViewHeight = [accountView frame].size.height;
	
    [view_accountDetails removeAllSubviews];
	[view_accountDetails addSubview:accountView];
	[accountView setFrameOrigin:NSMakePoint(0,([view_accountDetails frame].size.height - accountViewHeight))];
}

- (NSSize)desiredSize
{
	return(NSMakeSize(500,341));
}

- (IBAction)cancel:(id)sender
{
	[controller showAccountsOverview];
}

@end
