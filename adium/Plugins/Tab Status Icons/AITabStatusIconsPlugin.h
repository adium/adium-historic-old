//
//  AITabStatusIconsPlugin.h
//  Adium
//
//  Created by Adam Iser on Mon Jun 21 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

@interface AITabStatusIconsPlugin : AIPlugin <AIListObjectObserver> {
	NSImage		*tabStranger;
	NSImage		*tabAway;
	NSImage		*tabIdle;
	NSImage		*tabOffline;
	NSImage		*tabAvailable;
	NSImage		*tabContent;
	NSImage		*tabTyping;
}

@end
