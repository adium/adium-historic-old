//
//  AINewContactWindowController.h
//  Adium XCode
//
//  Created by Adam Iser on Sat Jan 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//


@interface AINewContactWindowController : AIWindowController {
	IBOutlet	NSPopUpButton		*popUp_contactType;
	IBOutlet	NSPopUpButton		*popUp_targetGroup;
	IBOutlet	NSTextField			*textField_contactName;
	IBOutlet	NSTableView			*tableView_accounts;
	IBOutlet	NSButton			*button_add;
	
	NSArray							*accounts;
	NSMutableArray					*addToAccounts;
}

+ (void)promptForNewContactOnWindow:(NSWindow *)parentWindow;
- (IBAction)cancel:(id)sender;
- (IBAction)addContact:(id)sender;
- (IBAction)closeWindow:(id)sender;

@end
