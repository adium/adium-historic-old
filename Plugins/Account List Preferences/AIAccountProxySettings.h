//
//  AIAccountProxySettingsView.h
//  Adium
//
//  Created by Adam Iser on 1/1/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIAccount;

@interface AIAccountProxySettings : AIObject {
	IBOutlet	NSView					*view_accountProxy;

	IBOutlet	NSButton				*checkBox_useProxy;
	IBOutlet	NSPopUpButton			*popUpButton_proxy;
	IBOutlet	NSTextField				*textField_proxyHostName;
	IBOutlet	NSTextField				*textField_proxyPortNumber;
	IBOutlet	NSTextField				*textField_proxyUserName;
	IBOutlet	NSSecureTextField		*textField_proxyPassword;
	
	AIAccount			*account;
}

- (NSView *)view;
- (IBAction)toggleProxy:(id)sender;
- (void)configureForAccount:(AIAccount *)inAccount;
- (void)saveConfiguration;
@end
