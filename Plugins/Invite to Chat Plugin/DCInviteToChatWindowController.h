//
//  DCInviteToChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

@interface DCInviteToChatWindowController : AIWindowController {	
	IBOutlet	NSPopUpButton   *menu_contacts;
	IBOutlet	NSTextField		*textField_message;
	IBOutlet	NSTextField		*textField_chatName;
	
	AIListContact				*contact;
	AIService					*service;
	AIChat						*chat;
}

+ (void)inviteToChatWindowForChat:(AIChat *)inChat contact:(AIListContact *)inContact;
+ (void)closeSharedInstance;

- (IBAction)invite:(id)sender;
- (IBAction)cancel:(id)sender;

@end
