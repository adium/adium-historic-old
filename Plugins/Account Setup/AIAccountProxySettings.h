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
	IBOutlet	NSPopUpButton			*menu_proxy;
	IBOutlet	NSTextField				*textField_proxyHostName;
	IBOutlet	NSTextField				*textField_proxyPortNumber;
	IBOutlet	NSTextField				*textField_proxyUserName;
	IBOutlet	NSSecureTextField		*textField_proxyPassword;
	
	AIAccount			*account;
	id					delegate;
}

- (id)initReplacingView:(NSView *)replaceView;
- (void)configureForAccount:(AIAccount *)inAccount;
- (void)setDelegate:(id)inDelegate;
- (id)delegate;
- (IBAction)toggleProxy:(id)sender;

@end
