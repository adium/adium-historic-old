//
//  ESGaimAccountView.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "GaimCommon.h"

@interface ESGaimAccountViewController : AIAccountViewController {
	IBOutlet	NSTextField					*textField_hostName;
	IBOutlet	NSTextField					*textField_portNumber;
	
	IBOutlet	NSPopUpButton				*menu_proxy;
	IBOutlet	NSTextField					*textField_proxyHostName;
	IBOutlet	NSTextField					*textField_proxyPortNumber;
	IBOutlet	NSTextField					*textField_proxyUserName;
	IBOutlet	NSSecureTextField			*textField_proxyPassword;
	
	IBOutlet	NSTextField					*textField_alias;
	
	IBOutlet	NSButton					*checkBox_checkMail;
}

- (IBAction)changedConnectionPreference:(id)sender;
- (void)controlTextDidChange:(NSNotification *)aNotification;

@end
