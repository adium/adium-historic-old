//
//  DCJoinChatWindowController.h
//  Adium
//
//  Created by David Clark on Tue Jul 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface DCGaimJabberJoinChatViewController : DCJoinChatViewController {
	IBOutlet		NSTextField		*textField_roomName;
	IBOutlet		NSTextField		*textField_server;
	IBOutlet		NSTextField		*textField_handle;
	IBOutlet		NSTextField		*textField_password;
	
	IBOutlet		NSTextField		*textField_inviteMessage;
	IBOutlet		NSTextField		*textField_inviteUsers;
}

@end
