//
//  DCInviteToChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface DCInviteToChatWindowController : AIWindowController {	
	IBOutlet	NSPopUpButton   *menu_contacts;
	IBOutlet	NSTextField		*textField_message;
	IBOutlet	NSTextField		*textField_chatName;
	
	AIListObject				*contact;
	NSString					*service;
	AIChat						*chat;
}

+ (void)inviteToChatWindowForChat:(AIChat *)inChat contact:(AIListObject *)inContact service:(NSString *)inService;
+ (void)closeSharedInstance;

- (IBAction)invite:(id)sender;
- (IBAction)cancel:(id)sender;

@end
