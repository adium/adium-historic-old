//
//  AIStandardListWindowController.h
//  Adium
//
//  Created by Adam Iser on Mon Jul 26 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "AIListWindowController.h"

@interface AIStandardListWindowController : AIListWindowController {
	NSDictionary		*toolbarItems;

	IBOutlet		NSPopUpButton	*popUp_state;
}

@end
