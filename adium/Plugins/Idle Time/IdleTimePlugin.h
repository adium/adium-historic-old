//
//  Idle Time.h
//  Adium
//
//  Created by Greg Smith on Wed Dec 18 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>


#define IDLE_TIME_DEFAULT_PREFERENCES	@"IdleDefaultPrefs"

#define GROUP_IDLE_TIME			@"Idle"
#define KEY_IDLE_TIME_ENABLED		@"Idle Enabled"
#define KEY_IDLE_TIME_IDLE_MINUTES	@"Threshold"


@protocol AIMiniToolbarItemDelegate;

@class IdleTimeWindowController, IdleTimePreferences;

@interface AIIdleTimePlugin : AIPlugin <AIMiniToolbarItemDelegate> {
    IdleTimePreferences	*preferences;

    BOOL		isIdle;
    NSTimer		*idleTimer;

    BOOL		idleEnabled;
    double		idleThreshold;
}

- (void)installPlugin;
- (void)uninstallPlugin;
- (IBAction)showIdleTimeWindow:(id)sender;

@end