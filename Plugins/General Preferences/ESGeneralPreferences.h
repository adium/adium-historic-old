//
//  ESGeneralPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 12/21/04.
//  Copyright 2004-2005 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIPreferencePane;

@interface ESGeneralPreferences : AIPreferencePane {
    IBOutlet	NSButton		*checkBox_messagesInTabs;
    IBOutlet	NSButton		*checkBox_arrangeTabs;
    IBOutlet	NSButton		*checkBox_arrangeByGroup;

	IBOutlet	NSButton		*checkBox_enableLogging;
	
	IBOutlet	NSPopUpButton	*popUp_tabKeys;
	
	IBOutlet	NSButton		*checkBox_sendOnReturn;
	IBOutlet	NSButton		*checkBox_sendOnEnter;

	IBOutlet	NSSlider		*slider_volume;
	IBOutlet	NSPopUpButton   *popUp_outputDevice; 	
	
	IBOutlet	NSPopUpButton	*popUp_statusIcons;
	IBOutlet	NSPopUpButton	*popUp_serviceIcons;
}

- (IBAction)selectVolume:(id)sender;

@end
