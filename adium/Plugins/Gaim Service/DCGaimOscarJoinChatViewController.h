//
//  DCJoinChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface DCGaimOscarJoinChatViewController : DCJoinChatViewController {
	AIAccount						*account;					// Account we are configured for
	NSArray							*contacts;					// List of contacts for invite table view
	
	IBOutlet		NSTextField		*textField_roomName;
	IBOutlet		NSTextField		*textField_inviteMessage;
	IBOutlet		NSTextField		*textField_inviteUsers;
	IBOutlet		NSScrollView	*scrollView_inviteUsers;
	IBOutlet		NSTableView		*tableView_inviteUsers;
}

@end
