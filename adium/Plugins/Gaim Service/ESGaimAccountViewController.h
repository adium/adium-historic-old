//
//  ESGaimAccountView.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "GaimCommon.h"

@interface ESGaimAccountViewController : AIAccountViewController {
	IBOutlet	NSTextField			*textField_hostName;
	IBOutlet	NSTextField			*textField_portNumber;
	
	IBOutlet	NSPopUpButton                   *menu_proxy;
	IBOutlet	NSTextField			*textField_proxyHostName;
	IBOutlet	NSTextField			*textField_proxyPortNumber;
	IBOutlet	NSTextField			*textField_proxyUserName;
	IBOutlet	NSSecureTextField               *textField_proxyPassword;
	
	IBOutlet	NSTextField			*textField_alias;
	
	IBOutlet	NSButton			*checkBox_checkMail;
        IBOutlet        ESImageViewWithImagePicker      *imageView_userIcon;
}

- (IBAction)changedConnectionPreference:(id)sender;

@end
