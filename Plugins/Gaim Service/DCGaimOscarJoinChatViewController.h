//
//  DCJoinChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//

@interface DCGaimOscarJoinChatViewController : DCJoinChatViewController {	
	IBOutlet		NSTextField		*textField_roomName;
	IBOutlet		NSTextField		*textField_inviteMessage;
	IBOutlet		NSTextField		*textField_inviteUsers;
	IBOutlet		NSScrollView	*scrollView_inviteUsers;
	IBOutlet		NSTableView		*tableView_inviteUsers;
}

@end
