//
//  JSCEventBezelPreferences.h
//  Adium XCode
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
}

- (IBAction)toggleShowBezel:(id)sender;
- (IBAction)changePosition:(id)sender;
- (IBAction)toggleOnline:(id)sender;
- (IBAction)toggleOffline:(id)sender;
- (IBAction)toggleAvailable:(id)sender;
- (IBAction)toggleAway:(id)sender;
- (IBAction)toggleNoIdle:(id)sender;
- (IBAction)toggleIdle:(id)sender;
- (IBAction)toggleFirstMessage:(id)sender;
- (IBAction)toggleImageBadges:(id)sender;
- (IBAction)toggleColorLabels:(id)sender;
- (IBAction)toggleNameLabels:(id)sender;
- (IBAction)changeDuration:(id)sender;

@end
