//
//  DCJoinChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

@interface DCGaimYahooJoinChatViewController : DCJoinChatViewController {
	IBOutlet		NSTextField		*textField_roomName;
	
	IBOutlet		NSTextField					*textField_inviteMessage;
	IBOutlet		AICompletingTextField		*textField_inviteUsers;
	
	AIAccount								*account;
}

@end
