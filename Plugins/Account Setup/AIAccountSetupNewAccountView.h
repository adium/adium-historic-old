//
//  AIAccountSetupNewAccountView.h
//  Adium
//
//  Created by Adam Iser on 12/30/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAccountSetupView.h"

@class AIService;

@interface AIAccountSetupNewAccountView : AIAccountSetupView {
	IBOutlet	NSImageView			*image_serviceIcon;
	IBOutlet	NSTextField			*textField_serviceName;
	IBOutlet	NSTextField			*textField_serviceHelp;
	IBOutlet	NSButtonCell		*radio_registerNew;
	IBOutlet	NSButtonCell		*radio_useExisting;
    IBOutlet	NSView				*view_accountDetails;

	AIAccountViewController			*accountViewController;
	AIAccount						*account;
}

- (void)configureForAccount:(AIAccount *)inAccount;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;

@end
