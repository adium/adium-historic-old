//
//  AIAccountSetupNewAccountView.m
//  Adium
//
//  Created by Adam Iser on 12/30/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
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
