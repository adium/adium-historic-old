//
//  AIConnectPanelPlugin.h
//  Adium
//
//  Created by Adam Iser on Fri Mar 12 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AIConnectPanelPlugin : AIPlugin {
	NSMenuItem		*menuItem_newConnection;
}

- (IBAction)newConnection:(id)sender;

@end
