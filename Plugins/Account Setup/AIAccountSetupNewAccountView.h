//
//  AIAccountSetupNewAccountView.h
//  Adium
//
//  Created by Adam Iser on 12/30/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAccountSetupView.h"

@class AIService;

@interface AIAccountSetupNewAccountView : AIAccountSetupView {
	IBOutlet	NSImageView			*image_serviceIcon;
	IBOutlet	NSTextField			*textField_serviceName;
	
	AIService			*service;
}

- (void)configureForService:(AIService *)inService;
- (IBAction)cancel:(id)sender;

@end
