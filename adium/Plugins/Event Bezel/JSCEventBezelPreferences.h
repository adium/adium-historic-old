//
//  JSCEventBezelPreferences.h
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

@interface JSCEventBezelPreferences : AIPreferencePane {
    IBOutlet NSButton       *checkBox_showBezel;
    IBOutlet NSPopUpButton  *popUp_position;
    IBOutlet NSButton       *checkBox_online;
    IBOutlet NSButton       *checkBox_offline;
    IBOutlet NSButton       *checkBox_available;
    IBOutlet NSButton       *checkBox_away;
    IBOutlet NSButton       *checkBox_noIdle;
    IBOutlet NSButton       *checkBox_idle;
    IBOutlet NSButton       *checkBox_firstMessage;
    IBOutlet NSButton       *checkBox_imageBadges;
    IBOutlet NSButton       *checkBox_colorLabels;
    IBOutlet NSButton       *checkBox_nameLabels;
    IBOutlet NSSlider       *slider_duration;
    IBOutlet NSPopUpButton  *popUp_size;
    IBOutlet NSPopUpButton  *popUp_background;
    IBOutlet NSButton       *checkBox_fadeIn;
    IBOutlet NSButton       *checkBox_fadeOut;
    IBOutlet NSButton       *checkBox_showHidden;
    IBOutlet NSButton       *checkBox_showAway;
    IBOutlet NSButton       *checkBox_includeText;
}

- (IBAction)changePreference:(id)sender;

@end
