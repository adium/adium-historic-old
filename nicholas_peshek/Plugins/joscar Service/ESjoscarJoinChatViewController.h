//
//  ESjoscarJoinChatViewController.h
//  Adium
//
//  Created by Evan Schoenberg on 2/7/06.
//

#import <Adium/DCJoinChatViewController.h>

@class AIAccount, AICompletingTextField;

@interface ESjoscarJoinChatViewController : DCJoinChatViewController {
	IBOutlet		NSTextField				*textField_roomName;
	IBOutlet		NSTextField				*textField_inviteMessage;
	IBOutlet		AICompletingTextField	*textField_inviteUsers;
}

- (void)validateEnteredText;

@end
