//
//  AIEditAccountWindowController.h
//  Adium
//
//  Created by Adam Iser on 1/16/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAccountProxySettings, AIAccountViewController;

@interface AIEditAccountWindowController : AIWindowController {
	//Account preferences
	IBOutlet	NSImageView					*image_serviceIcon;
	IBOutlet	NSTextField					*textField_accountDescription;
	IBOutlet	NSTextField					*textField_serviceName;
	IBOutlet	ESImageViewWithImagePicker  *imageView_userIcon;
    IBOutlet	NSTabView					*tabView_auxiliary;

	//Replacable views
	IBOutlet	NSView						*view_accountSetup;
	IBOutlet	NSView						*view_accountProxy;
	IBOutlet	NSView						*view_accountProfile;
	IBOutlet	NSView						*view_accountOptions;

	//Current configuration
    AIAccountViewController		*accountViewController;
	AIAccountProxySettings 		*accountProxyController;
	AIAccount					*account;
	
	//Delete if the sheet is canceled (should be YES when called on a new account, NO otherwise)
	BOOL	deleteIfCanceled;
}

+ (void)editAccount:(AIAccount *)account onWindow:(id)parentWindow deleteIfCanceled:(BOOL)inDeleteIfCanceled;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;

@end
