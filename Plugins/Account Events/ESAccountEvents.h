//
//  ESAccountEvents.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 27 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface ESAccountEvents : AIPlugin <AIListObjectObserver, AIEventHandler> {
	NSTimer *accountConnectionStatusGroupingOnlineTimer;
	NSTimer *accountConnectionStatusGroupingOfflineTimer;
}

@end
