//
//  AINewGroupWindowController.h
//  Adium XCode
//
//  Created by Adam Iser on Fri Feb 06 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AINewGroupWindowController : AIWindowController {
	IBOutlet	NSTextField		*textField_groupName;
}

+ (void)promptForNewGroupOnWindow:(NSWindow *)parentWindow;
- (IBAction)cancel:(id)sender;
- (IBAction)addGroup:(id)sender;
- (IBAction)closeWindow:(id)sender;

@end
