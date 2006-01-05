//
//  ESContactListAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 2/20/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIPreferencePane.h>

@interface ESContactListAdvancedPreferences : AIPreferencePane {
	IBOutlet	NSPopUpButton   *popUp_windowPosition;
    IBOutlet	NSButton		*checkBox_hide; //when in background
	IBOutlet	NSButton		*checkBox_edgeSlide; //hide on edges whether in background or not
	
	IBOutlet	NSButton		*checkBox_flash;
	IBOutlet	NSButton		*checkBox_showTransitions;
	IBOutlet	NSButton		*checkBox_showTooltips;
	IBOutlet	NSButton		*checkBox_showTooltipsInBackground;
	IBOutlet	NSButton		*checkBox_windowHasShadow;

	IBOutlet	NSTextField		*label_appearance;
	IBOutlet	NSTextField		*label_tooltips;
	IBOutlet	NSTextField		*label_windowHandling;
	IBOutlet	NSTextField		*label_hide;
	IBOutlet	NSTextField		*label_orderTheContactList;	
}

@end
