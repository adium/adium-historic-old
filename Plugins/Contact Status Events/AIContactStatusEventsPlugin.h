//
//  AIContactStatusEvents.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 04 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface AIContactStatusEventsPlugin : AIPlugin <AIListObjectObserver, AIEventHandler> {
	NSMutableDictionary		*onlineCache;
	NSMutableDictionary		*awayCache;
	NSMutableDictionary		*idleCache;
	NSMutableDictionary		*statusMessageCache;
}

@end
