//
//  CSDisconnectAllPlugin.h
//  Adium
//
//  Created by Chris Serino on Tue Sep 30 2003.
//  Copyright (c) 2003 The Adium Group. All rights reserved.
//

@interface CSDisconnectAllPlugin : AIPlugin {
    NSMenuItem *connectItem;
	NSMenuItem *connectDockItem;
    NSMenuItem *disconnectItem;
    NSMenuItem *disconnectDockItem;
    NSMenuItem *cancelConnectItem;
}

@end
