//
//  AIContactStatusEvents.h
//  Adium
//
//  Created by Adam Iser on Sun Apr 04 2004.
//

@interface AIContactStatusEventsPlugin : AIPlugin <AIListObjectObserver, AIEventHandler> {
	NSMutableDictionary		*onlineCache;
	NSMutableDictionary		*awayCache;
	NSMutableDictionary		*idleCache;
	NSMutableDictionary		*statusMessageCache;
}

@end
