//
//  DCJoinChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface DCJoinChatWindowController : AIWindowController {	
    IBOutlet		NSPopUpButton   *popUp_service;				//Account selector
    IBOutlet		NSView			*view_customView;			//View containing service-specific controls
	
	IBOutlet		NSTextField		*textField_accountLabel;
	IBOutlet		NSButton		*button_joinChat;
	IBOutlet		NSButton		*button_cancel;
	
	DCJoinChatViewController		*controller;				//Current view controller
}

+ (void)joinChatWindow;
+ (void)closeSharedInstance;

- (void)configureForAccount:(AIAccount *)inAccount;
- (IBAction)joinChat:(id)sender;
- (IBAction)closeWindow:(id)sender;

@end
