//
//  NEHGrowlPlugin.h
//  Adium
//
//  Created by Nelson Elhage on Sat May 29 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@protocol AIActionHandler;
@protocol GrowlAppBridgeDelegate;

@interface NEHGrowlPlugin : AIPlugin <AIActionHandler, GrowlAppBridgeDelegate> {
	BOOL			 showWhileAway;
}

@end
