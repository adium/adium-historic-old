//
//  ESGaimJabberAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "AIAccountViewController.h"
#import "ESGaimJabberAccount.h"

@interface ESGaimJabberAccountViewController : AIAccountViewController {
    IBOutlet	NSTextField *textField_connectServer;
	IBOutlet	NSTextField *textField_resource;
	IBOutlet	NSButton	*checkBox_useTLS;
	IBOutlet	NSButton	*checkBox_forceOldSSL;
	IBOutlet	NSButton	*checkBox_allowPlaintext;
}

@end

