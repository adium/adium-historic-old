//
//  ESAwayStatusWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 4/12/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>

#define KEY_SOUND_MUTE @"Mute Sounds"

@interface ESAwayStatusWindowController : AIWindowController {
	IBOutlet	NSButton		*button_return;
	IBOutlet	NSButton		*button_muteWhileAway;

	IBOutlet	NSTabView		*tabView_configuration;
	
	//Single status tab
	IBOutlet	NSScrollView	*scrollView_singleStatus;
	IBOutlet	NSTextView		*textView_singleStatus;
	
	//Multiple statuses tab
	IBOutlet	NSScrollView	*scrollView_multiStatus;
	IBOutlet	NSTableView		*tableView_multiStatus;
	
	NSMutableArray				*_awayAccounts;
}

+ (void)updateStatusWindowWithVisibility:(BOOL)shouldBeVisibile;
+ (void)setAlwaysOnTop:(BOOL)flag;
+ (void)setHideInBackground:(BOOL)flag;

- (IBAction)returnFromAway:(id)sender;

- (IBAction)toggleMuteWhileAway:(id)sender;
@end
