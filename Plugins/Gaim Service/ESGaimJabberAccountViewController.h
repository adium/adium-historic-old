//
//  ESGaimJabberAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#import "ESGaimAccountViewController.h"
#import "ESGaimJabberAccount.h"

@interface ESGaimJabberAccountViewController : ESGaimAccountViewController {
    IBOutlet	NSTextField *textField_connectServer;
	IBOutlet	NSTextField *textField_resource;
	IBOutlet	NSButton	*checkBox_useTLS;
	IBOutlet	NSButton	*checkBox_forceOldSSL;
	IBOutlet	NSButton	*checkBox_allowPlaintext;
}

@end

