//
//  ESGaimMeanwhileAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.

#include "ESGaimAccountViewController.h"

@interface ESGaimMeanwhileAccountViewController : ESGaimAccountViewController {
	IBOutlet	NSPopUpButton	*popUp_contactList;
	IBOutlet	NSTextField		*textField_contactListWarning;
}

@end
