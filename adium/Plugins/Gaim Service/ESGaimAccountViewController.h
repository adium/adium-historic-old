//
//  ESGaimAccountView.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "GaimCommon.h"

@interface ESGaimAccountViewController : AIAccountViewController {
	IBOutlet	NSTextField		*textField_hostName;
	IBOutlet	NSTextField		*textField_portNumber;
	
	IBOutlet	NSPopUpButton   *menu_proxy;
	IBOutlet	NSTextField		*textField_proxyHostName;
	IBOutlet	NSTextField		*textField_proxyPortNumber;
	IBOutlet	NSButton		*button_proxyRequireAuthentication;
	IBOutlet	NSButton		*button_proxySetPassword;
	
}

- (IBAction)changedConnectionPreference:(id)sender;

@end
