//
//  AIAccountSetupOverviewView.h
//  Adium
//
//  Created by Adam Iser on 12/29/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAccountSetupView.h"

@class AIViewGridView;

@interface AIAccountSetupOverviewView : AIAccountSetupView {
	IBOutlet		NSBox						*box_newUserHeader;
	IBOutlet		NSBox						*box_serviceDivider;
	IBOutlet		AIViewGridView				*grid_activeServices;
	IBOutlet		AIViewGridView				*grid_inactiveServices;
	
	IBOutlet		NSButton					*button_inactiveServicesToggle;
	IBOutlet		NSTextField					*textField_inactiveServicesToggle;
}

- (IBAction)toggleInactiveServices:(id)sender;
- (void)newAccountOnService:(AIService *)service;
- (void)editExistingAccount:(AIAccount *)account;

@end
