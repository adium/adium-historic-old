//
//  CSCheckmarkPlugin.h
//  Adium XCode
//
//  Created by Chris Serino on Sun Jan 04 2004.
//

#define PREF_GROUP_CHECKMARK    @"Checkmark"
#define CHECKMARK_DEFAULT_PREFS @"CheckmarkDefaults"
#define KEY_DISPLAY_CHECKMARK	@"Display Checkmark"

@class CSCheckmarkPreferences;

@interface CSCheckmarkPlugin : AIPlugin <AIListObjectObserver, AIListObjectView> {
	NSImage						*checkmarkImage;
	CSCheckmarkPreferences		*checkmarkPreferences;
	BOOL						displayCheckmark;
}

- (void)installPlugin;

@end
