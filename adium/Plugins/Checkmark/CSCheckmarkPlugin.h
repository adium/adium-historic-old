//
//  CSCheckmarkPlugin.h
//  Adium XCode
//
//  Created by Chris Serino on Sun Jan 04 2004.
//

#define PREF_GROUP_CHECKMARK    @"Checkmark"
#define KEY_DISPLAY_CHECKMARK	@"Display Checkmark"

@class CSCheckmarkPreferences;

@interface CSCheckmarkPlugin : AIPlugin <AIListObjectObserver, AIListObjectLeftView> {
	NSImage						*checkmarkImage;
	CSCheckmarkPreferences		*checkmarkPreferences;
	BOOL						displayCheckmark;
}



@end
