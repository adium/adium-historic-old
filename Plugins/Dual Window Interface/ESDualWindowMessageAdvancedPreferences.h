//
//  ESDualWindowMessageWindowAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#define PREF_GROUP_WEBKIT_MESSAGE_DISPLAY	@"WebKit Message Display"
#define WEBKIT_DEFAULT_PREFS				@"WebKit Defaults"

#define KEY_WEBKIT_NAME_FORMAT				@"Name Format"
#define KEY_WEBKIT_COMBINE_CONSECUTIVE		@"Combine Consecutive Messages"
#define KEY_WEBKIT_USE_BACKGROUND			@"Use Background Color"
#define KEY_WEBKIT_USE_NAME_FORMAT			@"Use Custom Name Format"

@interface ESDualWindowMessageAdvancedPreferences : AIPreferencePane {
    IBOutlet	NSButton		*autohide_tabBar;
    IBOutlet    NSButton		*checkBox_allowInactiveClosing;
	
	IBOutlet	NSButton		*checkBox_customNameFormatting;
	IBOutlet	NSPopUpButton   *popUp_nameFormat;
	IBOutlet	NSButton		*checkBox_combineConsecutive;
	IBOutlet	NSButton		*checkBox_backgroundColorFormatting;
}

@end
