//
//  ESGlobalEventsPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 12/18/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define OTHER_ELLIPSIS				AILocalizedString(@"Other...",nil)
#define OTHER						AILocalizedString(@"Other",nil)
#define SOUND_MENU_ICON_SIZE		16

@class ESContactAlertsViewController;

@interface ESGlobalEventsPreferences : AIPreferencePane {
	IBOutlet	ESContactAlertsViewController	*contactAlertsViewController;
	
	IBOutlet	NSPopUpButton	*popUp_dockBehaviorSet;
	IBOutlet	NSPopUpButton	*popUp_soundSet;
	IBOutlet	NSPopUpButton	*popUp_speechPreset;
	IBOutlet	NSPopUpButton	*popUp_growlPreset;
}

@end
