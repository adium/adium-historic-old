//
//  DCJoinChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

@interface DCGaimMeanwhileJoinChatViewController : DCJoinChatViewController {
	IBOutlet		NSTextField					*textField_topic;
	IBOutlet		AICompletingTextField		*textField_inviteUsers;
	
	AIAccount									*account;

}

@end
