//
//  ESWKMVAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Apr 30 2004.

#import <WebKit/WebKit.h>

@interface ESWKMVAdvancedPreferences : AIPreferencePane {
	IBOutlet	NSButton		*checkBox_customNameFormatting;
	IBOutlet	NSPopUpButton   *popUp_nameFormat;
	IBOutlet	NSButton		*checkBox_combineConsecutive;
}

@end
