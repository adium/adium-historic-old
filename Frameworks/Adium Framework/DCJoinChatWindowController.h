//
//  DCJoinChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface DCJoinChatWindowController : AIWindowController {	
    IBOutlet		NSPopUpButton   *popUp_service;				//Account selector
    IBOutlet		NSView			*view_customView;			//View containing service-specific controls
	
	IBOutlet		AILocalizationTextField		*label_account;
	IBOutlet		AILocalizationButton		*button_joinChat;
	IBOutlet		AILocalizationButton		*button_cancel;

	DCJoinChatViewController		*controller;				//Current view controller
	NSView							*currentView;				//
}

+ (void)joinChatWindow;

- (void)configureForAccount:(AIAccount *)inAccount;
- (IBAction)joinChat:(id)sender;
- (IBAction)closeWindow:(id)sender;

- (void)setJoinChatEnabled:(BOOL)enabled;
- (AIListContact *)contactFromText:(NSString *)text;

@end
