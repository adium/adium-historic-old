//
//  AIAccountSetupEditAccountView.h
//  Adium
//
//  Created by Adam Iser on 12/31/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAccountSetupView.h"

@class AIAccount;

@interface AIAccountSetupEditAccountView : AIAccountSetupView {
	IBOutlet	NSImageView			*image_serviceIcon;
	IBOutlet	NSTextField			*textField_accountDescription;
	IBOutlet	NSTextField			*textField_serviceName;

	//Account preferences
    IBOutlet	NSTabView					*tabView_auxiliary;
    IBOutlet	NSView						*view_accountDetails;
    IBOutlet	NSButton					*button_autoConnect;
	IBOutlet	ESImageViewWithImagePicker  *imageView_userIcon;
	
	//Current configuration
	AIService						*configuredForService;
	AIAccount						*configuredForAccount;
    AIAccountViewController			*accountViewController;
	
	AIAccount			*account;
}

- (void)configureForAccount:(AIAccount *)inAccount;
- (IBAction)okay:(id)sender;

@end
