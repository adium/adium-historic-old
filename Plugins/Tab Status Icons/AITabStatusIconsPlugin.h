//
//  AITabStatusIconsPlugin.h
//  Adium
//
//  Created by Adam Iser on Mon Jun 21 2004.
//

@interface AITabStatusIconsPlugin : AIPlugin <AIListObjectObserver, AIChatObserver> {
	NSImage		*tabUnknown;
	NSImage		*tabAway;
	NSImage		*tabIdle;
	NSImage		*tabOffline;
	NSImage		*tabAvailable;
	NSImage		*tabContent;
	NSImage		*tabTyping;
	NSImage		*tabEnteredText;
}

@end
