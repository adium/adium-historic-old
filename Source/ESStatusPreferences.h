//
//  ESStatusPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 2/26/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "AIPreferencePane.h"

@class AIAutoScrollView, AIStatus;

@interface ESStatusPreferences : AIPreferencePane {
	//Status state tableview
	IBOutlet	NSButton			*button_editState;
	IBOutlet	NSButton			*button_deleteState;
	IBOutlet	NSTableView			*tableView_stateList;
	IBOutlet	AIAutoScrollView	*scrollView_stateList;
	
	NSArray				*stateArray;
	AIStatus			*tempDragState;
	
	//Other controls
	IBOutlet	NSButton		*checkBox_idle;
	IBOutlet	NSTextField		*textField_idleMinutes;
	IBOutlet    NSStepper       *stepper_idleMinutes;

	IBOutlet	NSButton		*checkBox_autoAway;
	IBOutlet	NSPopUpButton	*popUp_autoAwayStatusState;
	IBOutlet	NSTextField		*textField_autoAwayMinutes;
	IBOutlet    NSStepper       *stepper_autoAwayMinutes;

	IBOutlet	NSButton		*checkBox_fastUserSwitching;
	IBOutlet	NSPopUpButton	*popUp_fastUserSwitchingStatusState;
	
	IBOutlet	NSButton		*checkBox_showStatusWindow;
}

- (void)configureStateList;

- (IBAction)editState:(id)sender;
- (IBAction)deleteState:(id)sender;
- (IBAction)newState:(id)sender;

- (void)stateArrayChanged:(NSNotification *)notification;

@end
