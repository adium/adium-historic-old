//
//  ESGaimMeanwhileAccountViewController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jun 28 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#include "ESGaimAccountViewController.h"

@interface ESGaimMeanwhileAccountViewController : ESGaimAccountViewController {
	IBOutlet	NSPopUpButton	*popUp_contactList;
	IBOutlet	NSTextField		*textField_contactListWarning;
}

@end
