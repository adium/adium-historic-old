//
//  AIAccountSetupConnectionView.h
//  Adium
//
//  Created by Adam Iser on 1/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAccountSetupView.h"

@class AIAccountProxySettings;

@interface AIAccountSetupConnectionView : AIAccountSetupView {
	IBOutlet	NSView			*view_proxySettings;
	
	AIAccountProxySettings		*proxySettings;
}

- (void)configureForAccount:(AIAccount *)inAccount;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;

@end
