//
//  ESAccountEvents.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Jun 27 2004.

@interface ESAccountEvents : AIPlugin <AIListObjectObserver, AIEventHandler> {
	NSTimer *accountConnectionStatusGroupingOnlineTimer;
	NSTimer *accountConnectionStatusGroupingOfflineTimer;
}

@end
