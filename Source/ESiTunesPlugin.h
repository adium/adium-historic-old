//  ESiTunesPlugin.h
//  Adium
//
//  Started by Evan Schoenberg on 6/11/05.
//	Assigned to Kiel Gillard (Trac Ticket #316)
	
#import <Adium/AIPlugin.h>

@protocol AIContentFilter;

typedef enum {
	AUTODISABLES = 0,
	ALWAYS_ENABLED = 1,
	ENABLED_IF_ITUNES_PLAYING = 2,
	RESPONDER_IS_WEBVIEW = 3
} KGiTunesPluginMenuItemKind;

@interface ESiTunesPlugin : AIPlugin <AIContentFilter> {
	NSDictionary *iTunesCurrentInfo;
	
	NSDictionary *substitutionDict;
	NSDictionary *phraseSubstitutionDict;
	BOOL iTunesIsStopped;
}

@end
