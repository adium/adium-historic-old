//
//  CSDisconnectAllPlugin.h
//  Adium
//
//  Created by Chris Serino on Tue Sep 30 2003.
//  Copyright (c) 2003 The Adium Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@interface CSDisconnectAllPlugin : AIPlugin {
    NSMenuItem *connectItem;
    NSMenuItem *disconnectItem;
}

@end
