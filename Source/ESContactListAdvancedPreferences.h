//
//  ESContactListAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 2/20/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Adium/AIPreferencePane.h>

@interface ESContactListAdvancedPreferences : AIPreferencePane {
	IBOutlet	NSPopUpButton   *popUp_windowPosition;
    IBOutlet	NSButton		*checkBox_hide;
	
	IBOutlet	NSButton		*checkBox_flash;
	IBOutlet	NSButton		*checkBox_showTransitions;
	IBOutlet	NSButton		*checkBox_showTooltips;
	IBOutlet	NSButton		*checkBox_showTooltipsInBackground;
	
	IBOutlet	NSTextField		*label_effects;
	IBOutlet	NSTextField		*label_tooltips;
	IBOutlet	NSTextField		*label_windowHandling;
	IBOutlet	NSTextField		*label_orderTheContactList;	
}

@end
