//
//  ESWKMVAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Fri Apr 30 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface ESWKMVAdvancedPreferences : AIPreferencePane {
	IBOutlet	NSButton		*checkBox_customNameFormatting;
	IBOutlet	NSPopUpButton   *popUp_nameFormat;
	IBOutlet	NSButton		*checkBox_combineConsecutive;
	IBOutlet	NSButton		*checkBox_backgroundColorFormatting;
}

@end
