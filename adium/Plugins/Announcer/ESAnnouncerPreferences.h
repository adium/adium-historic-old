//
//  ESAnnouncerPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@interface ESAnnouncerPreferences : AIPreferencePane {
    IBOutlet	NSButton	*checkBox_outgoing;
    IBOutlet	NSButton	*checkBox_incoming;
    IBOutlet    NSButton	*checkBox_messageText;
    IBOutlet	NSButton	*checkBox_status;
    IBOutlet	NSButton	*checkBox_time;
    IBOutlet	NSButton	*checkBox_sender;
	IBOutlet	NSWindow	*panel_options;
	IBOutlet	NSButton	*pushButton_OK;
	IBOutlet	NSButton	*pushButton_cancel;
	IBOutlet	NSButton	*pushButton_options;
	IBOutlet	NSButton	*checkBox_enableSpeech;
}

- (IBAction)changePreference:(id)sender;
- (IBAction)closeOptions:(id)sender;
- (IBAction)openOptions:(id)sender;

- (void)savePreferences;
- (void)configureControlDimming;
- (void)configureControlsFromPrefs;
@end
