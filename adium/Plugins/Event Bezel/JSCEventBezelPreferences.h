//
//  JSCEventBezelPreferences.h
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#define EVENT_BEZEL_PREFERENCE_LABEL	@"Event Notifications"

@interface JSCEventBezelPreferences : AIPreferencePane {
    IBOutlet NSButton       *checkBox_showBezel;
    IBOutlet NSButton       *checkBox_online;
    IBOutlet NSButton       *checkBox_offline;
    IBOutlet NSButton       *checkBox_available;
    IBOutlet NSButton       *checkBox_away;
    IBOutlet NSButton       *checkBox_noIdle;
    IBOutlet NSButton       *checkBox_idle;
    IBOutlet NSButton       *checkBox_firstMessage;
    IBOutlet NSSlider       *slider_duration;
    IBOutlet NSButton       *checkBox_showHidden;
    IBOutlet NSButton       *checkBox_showAway;
    IBOutlet NSButton       *checkBox_includeText;
	IBOutlet NSButton		*checkBox_ignoreClicks;
}

- (IBAction)changePreference:(id)sender;

@end
