//
//  AIAccountSetupEditAccountView.h
//  Adium
//
//  Created by Adam Iser on 12/31/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAccountSetupView.h"

@class AIAccount;

@interface AIAccountSetupEditAccountView : AIAccountSetupView {
	IBOutlet	NSImageView			*image_serviceIcon;
	IBOutlet	NSTextField			*textField_accountDescription;
	IBOutlet	NSTextField			*textField_serviceName;
	
//	//Account status
//	IBOutlet		NSTextField					*textField_status;
//	IBOutlet		NSProgressIndicator			*progress_status;
//	IBOutlet		NSButton					*button_toggleConnect;
	IBOutlet		NSButton					*button_register;
//	
//	//Account preferences
    IBOutlet		NSTabView					*tabView_auxiliary;
    IBOutlet		NSView						*view_accountDetails;
//    IBOutlet		NSPopUpButton				*popupMenu_serviceList;
	IBOutlet		ESDelayedTextField			*textField_accountName;
	IBOutlet		NSTextField					*textField_userNameLabel;
    IBOutlet		NSButton					*button_autoConnect;
	IBOutlet		ESImageViewWithImagePicker  *imageView_userIcon;
//	
//	//Account list
//    IBOutlet		AIAutoScrollView			*scrollView_accountList;
//    IBOutlet		NSTableView					*tableView_accountList;
//	IBOutlet		NSPopUpButton				*button_newAccount;
//    IBOutlet		NSButton					*button_deleteAccount;
	
	//Current configuration
	AIService						*configuredForService;
	AIAccount						*configuredForAccount;
    AIAccountViewController			*accountViewController;
//	NSTimer							*responderChainTimer;
//	
//    //Account List
//    NSArray							*accountArray;
//    AIAccount						*tempDragAccount;
	
	AIAccount			*account;
}

- (void)configureForAccount:(AIAccount *)inAccount;
- (IBAction)okay:(id)sender;

@end
