//
//  ESDualWindowMessageWindowPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Thu Sep 18 2003.
//

@interface ESDualWindowMessageAdvancedPreferences : AIPreferencePane {
    IBOutlet	NSButton		*autohide_tabBar;
    IBOutlet    NSButton		*checkBox_allowInactiveClosing;
	
	IBOutlet	NSButton		*checkBox_arrangeTabs;
	IBOutlet	NSButton		*checkBox_arrangeByGroup;
}

@end
