//
//  ESGaimMSNAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Dec 28 2003.

#include "ESGaimAccountViewController.h"

@interface ESGaimMSNAccountViewController : ESGaimAccountViewController {
    IBOutlet		NSTextField		*textField_friendlyName;
	
	IBOutlet		NSButton		*checkBox_HTTPConnectMethod;
	
	IBOutlet		NSButton		*checkBox_treatDisplayNamesAsStatus;
	IBOutlet		NSButton		*checkBox_conversationClosed;
	IBOutlet		NSButton		*checkBox_conversationTimedOut;
}

@end
