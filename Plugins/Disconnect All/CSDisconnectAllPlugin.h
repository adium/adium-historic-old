//
//  CSDisconnectAllPlugin.h
//  Adium
//
//  Created by Chris Serino on Tue Sep 30 2003.
//  Copyright (c) 2003-2005 The Adium Group. All rights reserved.
//

@interface CSDisconnectAllPlugin : AIPlugin {
    NSMenuItem *connectItem;
    NSMenuItem *disconnectItem;
    NSMenuItem *cancelConnectItem;
	
	NSMenuItem *connectDockItem;
    NSMenuItem *disconnectDockItem;
}

@end
