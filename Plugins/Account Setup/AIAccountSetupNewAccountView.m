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
	[textField_serviceName setStringValue:[NSString stringWithFormat:@"New %@ Account",[service longDescription]]];
	
	//Fields

}

- (NSSize)desiredSize
{
	return(NSMakeSize(484,318));
}

- (IBAction)cancel:(id)sender
{
	[controller showAccountsOverview];
}

@end
