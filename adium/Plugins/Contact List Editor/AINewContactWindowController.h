//
//  AINewContactWindowController.h
//  Adium XCode
//
//  Created by Adam Iser on Sat Jan 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//


@interface AINewContactWindowController : AIWindowController {
	IBOutlet	NSPopUpButton		*popUp_contactType;
	IBOutlet	NSTextField			*textField_contactName;
}

+ (void)promptForNewContactOnWindow:(NSWindow *)parentWindow;
- (IBAction)cancel:(id)sender;
- (IBAction)addContact:(id)sender;

@end
