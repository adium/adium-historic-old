//
//  AINewMessagePanelPlugin.h
//  Adium
//
//  Created by Adam Iser on Tue Jul 13 2004.
//  Copyright (c) 2004 The Adium Team. All rights reserved.
//

@interface AINewMessagePanelPlugin : AIPlugin {
	NSMenuItem	*newMessageMenuItem;
}

- (IBAction)newMessage:(id)sender;

@end
